import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../services/heart_rate_service.dart';
import '../services/metronome.dart';
import '../theme.dart';

/// 3-minute zone calibration: walk as fast as possible with the metronome;
/// the average HR of the final minute becomes the personal fast zone.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen(
      {super.key, required this.settings, required this.hr});

  final AppSettings settings;
  final HeartRateService hr;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  static const total = Duration(minutes: 3);
  final Metronome _metronome = Metronome();
  final Stopwatch _clock = Stopwatch();
  final List<int> _samples = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (widget.settings.metronomeEnabled) {
      await _metronome.init();
      _metronome
        ..setVolume(widget.settings.tickVolume)
        ..start(widget.settings.fastBpm);
    }
    _clock.start();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final bpm = widget.hr.bpm;
      // Average the final minute only — HR needs time to plateau.
      if (bpm != null && _clock.elapsed.inSeconds >= 120) _samples.add(bpm);
      if (_clock.elapsed >= total) {
        _finish(save: true);
        return;
      }
      setState(() {});
    });
  }

  void _finish({required bool save}) {
    _timer?.cancel();
    _metronome.stop();
    if (save && _samples.isNotEmpty) {
      widget.settings.calibHr =
          (_samples.reduce((a, b) => a + b) / _samples.length).round();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _metronome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(widget.settings.localeCode);
    final remain = total - _clock.elapsed;
    final mm = remain.inMinutes.toString().padLeft(2, '0');
    final ss = (remain.inSeconds % 60).toString().padLeft(2, '0');
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎯 ${s['calib']}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(s['calibRun'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 32),
                Text('$mm:$ss',
                    style: const TextStyle(
                        fontSize: 64, fontWeight: FontWeight.w700)),
                ListenableBuilder(
                  listenable: widget.hr,
                  builder: (context, _) => Text(
                    widget.hr.bpm != null ? '♥ ${widget.hr.bpm}' : '—',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.fastColor),
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.fastColor),
                  onPressed: () => _finish(save: false),
                  child: Text(s['stop']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
