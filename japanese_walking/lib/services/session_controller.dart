import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../models/workout_history.dart';
import 'heart_rate_service.dart';
import 'metronome.dart';

enum SessionState { idle, running, paused, finished }

enum Phase { fast, slow }

/// State machine for one IWT session:
/// fast → slow → fast → … (cycles × 2 phases), with metronome, voice cues,
/// 3-2-1 countdown, phase-change sounds/vibration, live steps/kcal metrics
/// and an optional smart mode that keeps heart rate in the target zone.
class SessionController extends ChangeNotifier {
  SessionController(this.settings, {this.hr});

  final AppSettings settings;
  final HeartRateService? hr;
  final Metronome metronome = Metronome();
  final AudioPlayer _fx = AudioPlayer();
  final AudioPlayer _count = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  SessionState state = SessionState.idle;
  Phase phase = Phase.fast;
  int cycleIndex = 0; // 0-based

  // Live metrics (estimated from cadence + body weight, MET 5.0 / 3.0)
  double steps = 0;
  double kcal = 0;
  double fastMs = 0;

  final Stopwatch _phaseClock = Stopwatch();
  final Stopwatch _sessionClock = Stopwatch();
  int _lastMetricMs = 0;
  int _lastCountSec = 0;
  int _lastAdjustMs = 0;
  Timer? _ui;
  bool? _hasVibrator;

  // HR analytics: session average, 1-min recovery after fast phases,
  // out-of-zone voice coaching.
  int _hrSum = 0;
  int _hrN = 0;
  final List<int> _recoveries = [];
  int _hrFastEnd = 0;
  bool _recDone = true;
  double _outZoneMs = 0;
  bool _coachSaid = false;

  // --- Derived values for the UI ---
  Duration get phaseElapsed => _phaseClock.elapsed;
  Duration get phaseLength => Duration(seconds: settings.phaseSeconds);
  Duration get phaseRemaining {
    final r = phaseLength - phaseElapsed;
    return r.isNegative ? Duration.zero : r;
  }

  double get phaseProgress =>
      (phaseElapsed.inMilliseconds / phaseLength.inMilliseconds)
          .clamp(0.0, 1.0);

  int get phasesDone => cycleIndex * 2 + (phase == Phase.slow ? 1 : 0);
  double get totalProgress =>
      (phasesDone + phaseProgress) / (settings.cycles * 2);

  int get currentBpm =>
      phase == Phase.fast ? settings.fastBpm : settings.slowBpm;

  (int, int) get currentZone => settings.hrZone(fast: phase == Phase.fast);

  // --- Lifecycle ---
  Future<void> start() async {
    await metronome.init();
    _hasVibrator ??= await Vibration.hasVibrator();
    await _tts.setLanguage(settings.localeCode == 'ru' ? 'ru-RU' : 'en-US');
    await _tts.setSpeechRate(0.5);
    cycleIndex = 0;
    phase = Phase.fast;
    steps = 0;
    kcal = 0;
    fastMs = 0;
    _lastMetricMs = 0;
    _lastCountSec = 0;
    _lastAdjustMs = 0;
    _hrSum = 0;
    _hrN = 0;
    _recoveries.clear();
    _hrFastEnd = 0;
    _recDone = true;
    _outZoneMs = 0;
    _coachSaid = false;
    state = SessionState.running;
    _phaseClock
      ..reset()
      ..start();
    _sessionClock
      ..reset()
      ..start();
    if (settings.metronomeEnabled) {
      metronome
        ..setVolume(settings.tickVolume)
        ..start(currentBpm);
    }
    WakelockPlus.enable();
    _startUiTimer();
    _announcePhase();
    notifyListeners();
  }

  void pause() {
    if (state != SessionState.running) return;
    state = SessionState.paused;
    _phaseClock.stop();
    _sessionClock.stop();
    metronome.stop();
    _ui?.cancel();
    notifyListeners();
  }

  void resume() {
    if (state != SessionState.paused) return;
    state = SessionState.running;
    _phaseClock.start();
    _sessionClock.start();
    if (settings.metronomeEnabled) metronome.start(currentBpm);
    _startUiTimer();
    notifyListeners();
  }

  void stopSession() => _finish(playFanfare: false);

  /// Cadence tweak — manual (±) or from smart mode. Persists to settings.
  void adjustBpm(int delta) {
    if (phase == Phase.fast) {
      settings.fastBpm = settings.fastBpm + delta;
    } else {
      settings.slowBpm = settings.slowBpm + delta;
    }
    metronome.setBpm(currentBpm);
    notifyListeners();
  }

  void _startUiTimer() {
    _ui?.cancel();
    _ui = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    if (state != SessionState.running) return;

    // Metrics: integrate cadence over elapsed time.
    final ms = _sessionClock.elapsedMilliseconds;
    final dtMin = (ms - _lastMetricMs) / 60000.0;
    _lastMetricMs = ms;
    final met = phase == Phase.fast ? 5.0 : 3.0;
    steps += dtMin * currentBpm;
    kcal += dtMin * met * 3.5 * settings.weightKg / 200.0;
    if (phase == Phase.fast) fastMs += dtMin * 60000;

    final liveHr = hr?.bpm;
    if (liveHr != null) {
      _hrSum += liveHr;
      _hrN++;
      // 1-minute HR recovery after a fast phase.
      if (phase == Phase.slow &&
          _hrFastEnd > 0 &&
          !_recDone &&
          phaseElapsed.inMilliseconds >= 60000) {
        _recoveries.add(_hrFastEnd - liveHr);
        _recDone = true;
      }
      // Voice coach: out of zone for >2 minutes straight.
      if (settings.smartMode && settings.voiceEnabled) {
        final (lo, hi) = currentZone;
        if (liveHr < lo - 2 || liveHr > hi + 2) {
          _outZoneMs += dtMin * 60000;
          if (_outZoneMs > 120000 && !_coachSaid) {
            _say(liveHr < lo ? 'coachUp' : 'coachDown');
            _coachSaid = true;
          }
        } else {
          _outZoneMs = 0;
          _coachSaid = false;
        }
      }
    }

    // 3-2-1 countdown before each phase change.
    final remainSec = (phaseLength - phaseElapsed).inMilliseconds ~/ 1000 + 1;
    if (settings.phaseSoundsEnabled &&
        remainSec <= 3 &&
        remainSec >= 1 &&
        remainSec != _lastCountSec) {
      _lastCountSec = remainSec;
      _count.play(AssetSource('audio/count.wav'));
    }

    // Smart mode: after 45 s of the phase, every 15 s nudge cadence ±2
    // to keep HR inside the target zone.
    final bpmNow = hr?.bpm;
    if (settings.smartMode &&
        bpmNow != null &&
        phaseElapsed.inMilliseconds > 45000 &&
        ms - _lastAdjustMs > 15000) {
      final (lo, hi) = currentZone;
      if (bpmNow < lo - 2) {
        adjustBpm(2);
      } else if (bpmNow > hi + 2) {
        adjustBpm(-2);
      }
      _lastAdjustMs = ms;
    }

    if (_phaseClock.elapsed >= phaseLength) {
      _nextPhase();
    }
    notifyListeners();
  }

  void _nextPhase() {
    _lastCountSec = 0;
    _outZoneMs = 0;
    _coachSaid = false;
    if (phase == Phase.fast) {
      _hrFastEnd = hr?.bpm ?? 0;
      _recDone = _hrFastEnd == 0;
      phase = Phase.slow;
    } else {
      phase = Phase.fast;
      cycleIndex++;
      if (cycleIndex >= settings.cycles) {
        _finish(playFanfare: true);
        return;
      }
    }
    _phaseClock
      ..reset()
      ..start();
    metronome.setBpm(currentBpm);
    _announcePhase();
  }

  void _say(String key) {
    if (!settings.voiceEnabled) return;
    _tts.stop();
    _tts.speak(S.of(settings.localeCode)[key]);
  }

  /// Phase-change feedback: voice + a distinct sound per direction + vibration.
  void _announcePhase() {
    _say(phase == Phase.fast ? 'sayFast' : 'saySlow');
    if (settings.phaseSoundsEnabled) {
      _fx.play(AssetSource(
        phase == Phase.fast ? 'audio/phase_fast.wav' : 'audio/phase_slow.wav',
      ));
    }
    if (settings.vibrationEnabled && (_hasVibrator ?? false)) {
      if (phase == Phase.fast) {
        // Three short bursts — "speed up!"
        Vibration.vibrate(pattern: [0, 250, 120, 250, 120, 250]);
      } else {
        // One long pulse — "slow down".
        Vibration.vibrate(pattern: [0, 700]);
      }
    }
  }

  void _finish({required bool playFanfare}) {
    state = SessionState.finished;
    _phaseClock.stop();
    _sessionClock.stop();
    metronome.stop();
    _ui?.cancel();
    WakelockPlus.disable();
    // Save workouts longer than a minute to the journal.
    if (_sessionClock.elapsedMilliseconds > 60000) {
      WorkoutHistory.add(WorkoutRecord(
        day: WorkoutHistory.dayKey(DateTime.now()),
        minutes: (_sessionClock.elapsedMilliseconds / 60000).round(),
        steps: steps.round(),
        kcal: kcal.round(),
        fastMin: (fastMs / 60000 * 10).round() / 10,
        avgHr: _hrN > 0 ? (_hrSum / _hrN).round() : 0,
        recovery: _recoveries.isNotEmpty
            ? (_recoveries.reduce((a, b) => a + b) / _recoveries.length)
                .round()
            : 0,
      ));
    }
    if (playFanfare) {
      _say('sayDone');
      if (settings.phaseSoundsEnabled) {
        _fx.play(AssetSource('audio/finish.wav'));
      }
      if (settings.vibrationEnabled && (_hasVibrator ?? false)) {
        Vibration.vibrate(pattern: [0, 300, 150, 300, 150, 600]);
      }
    }
    notifyListeners();
  }

  int get activeMinutes => (_sessionClock.elapsedMilliseconds / 60000).round();

  @override
  void dispose() {
    _ui?.cancel();
    metronome.dispose();
    _fx.dispose();
    _count.dispose();
    _tts.stop();
    WakelockPlus.disable();
    super.dispose();
  }
}
