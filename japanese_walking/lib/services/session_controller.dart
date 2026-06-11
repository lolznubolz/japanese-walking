import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import 'metronome.dart';

enum SessionState { idle, running, paused, finished }

enum Phase { fast, slow }

/// State machine for one IWT session:
/// fast → slow → fast → … (cycles × 2 phases), with metronome, phase-change
/// sounds and distinct vibration patterns.
class SessionController extends ChangeNotifier {
  SessionController(this.settings);

  final AppSettings settings;
  final Metronome metronome = Metronome();
  final AudioPlayer _fx = AudioPlayer();

  SessionState state = SessionState.idle;
  Phase phase = Phase.fast;
  int cycleIndex = 0; // 0-based

  final Stopwatch _phaseClock = Stopwatch();
  Timer? _ui;
  bool? _hasVibrator;

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

  // --- Lifecycle ---
  Future<void> start() async {
    await metronome.init();
    _hasVibrator ??= await Vibration.hasVibrator();
    cycleIndex = 0;
    phase = Phase.fast;
    state = SessionState.running;
    _phaseClock
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
    metronome.stop();
    _ui?.cancel();
    notifyListeners();
  }

  void resume() {
    if (state != SessionState.paused) return;
    state = SessionState.running;
    _phaseClock.start();
    if (settings.metronomeEnabled) metronome.start(currentBpm);
    _startUiTimer();
    notifyListeners();
  }

  void stopSession() => _finish(playFanfare: false);

  /// Live cadence tweak from the session screen (persists to settings).
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
    if (_phaseClock.elapsed >= phaseLength) {
      _nextPhase();
    }
    notifyListeners();
  }

  void _nextPhase() {
    if (phase == Phase.fast) {
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

  /// Phase-change feedback: a distinct sound per direction + vibration.
  void _announcePhase() {
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
    metronome.stop();
    _ui?.cancel();
    WakelockPlus.disable();
    if (playFanfare) {
      if (settings.phaseSoundsEnabled) {
        _fx.play(AssetSource('audio/finish.wav'));
      }
      if (settings.vibrationEnabled && (_hasVibrator ?? false)) {
        Vibration.vibrate(pattern: [0, 300, 150, 300, 150, 600]);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ui?.cancel();
    metronome.dispose();
    _fx.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}
