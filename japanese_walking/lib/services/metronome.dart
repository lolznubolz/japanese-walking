import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Drift-corrected metronome.
///
/// Instead of a naive `Timer.periodic` (which accumulates drift), every beat
/// is scheduled against a monotonic [Stopwatch], so over a 30-minute session
/// the tick stays locked to the chosen cadence.
class Metronome {
  Metronome();

  AudioPool? _tickPool;
  AudioPool? _tockPool;

  final Stopwatch _clock = Stopwatch();
  Timer? _timer;

  int _bpm = 120;
  double _volume = 0.8;
  bool _running = false;
  bool _even = false;
  double _nextBeatMs = 0;

  bool get isRunning => _running;
  int get bpm => _bpm;

  /// Pre-load the audio pools. Call once before the first [start].
  Future<void> init() async {
    _tickPool ??= await AudioPool.create(
      source: AssetSource('audio/tick.wav'),
      maxPlayers: 3,
    );
    _tockPool ??= await AudioPool.create(
      source: AssetSource('audio/tock.wav'),
      maxPlayers: 3,
    );
  }

  void start(int bpm) {
    _bpm = bpm;
    if (_running) return;
    _running = true;
    _even = false;
    _clock
      ..reset()
      ..start();
    _nextBeatMs = 0;
    _scheduleNext();
  }

  /// Change tempo on the fly (takes effect from the next beat).
  void setBpm(int bpm) => _bpm = bpm;

  void setVolume(double v) => _volume = v.clamp(0.0, 1.0);

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
  }

  Future<void> dispose() async {
    stop();
    await _tickPool?.dispose();
    await _tockPool?.dispose();
    _tickPool = null;
    _tockPool = null;
  }

  void _scheduleNext() {
    if (!_running) return;
    final nowMs = _clock.elapsedMicroseconds / 1000.0;
    final delayMs = (_nextBeatMs - nowMs).clamp(0.0, 60000.0);
    _timer = Timer(Duration(microseconds: (delayMs * 1000).round()), () {
      if (!_running) return;
      // Alternate tick/tock — matches left/right foot strikes.
      final pool = _even ? _tockPool : _tickPool;
      _even = !_even;
      pool?.start(volume: _volume);
      _nextBeatMs += 60000.0 / _bpm;
      _scheduleNext();
    });
  }
}
