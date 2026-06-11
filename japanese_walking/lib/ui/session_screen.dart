import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../services/heart_rate_service.dart';
import '../services/session_controller.dart';
import '../theme.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.settings, required this.hr});

  final AppSettings settings;
  final HeartRateService hr;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionController c;

  @override
  void initState() {
    super.initState();
    c = SessionController(widget.settings);
    c.start();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(widget.settings.localeCode);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            if (c.state == SessionState.finished) {
              return _FinishedView(s: s);
            }
            final isFast = c.phase == Phase.fast;
            final color = isFast ? AppTheme.fastColor : AppTheme.slowColor;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Total progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: c.totalProgress,
                      minHeight: 6,
                      color: color,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s['cycle']} ${c.cycleIndex + 1} ${s['of']} ${widget.settings.cycles}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const Spacer(),

                  // Phase ring
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CustomPaint(
                              painter: _RingPainter(
                                progress: c.phaseProgress,
                                color: color,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  isFast ? s['fastPhase'] : s['slowPhase'],
                                  key: ValueKey(c.phase),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              Text(
                                _fmt(c.phaseRemaining),
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              ListenableBuilder(
                                listenable: widget.hr,
                                builder: (context, _) => widget.hr.connected
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.favorite,
                                              size: 16,
                                              color: AppTheme.fastColor),
                                          const SizedBox(width: 4),
                                          Text(
                                              '${widget.hr.bpm ?? '—'} ${s['bpm']}'),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Live cadence control
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove),
                            onPressed: () => c.adjustBpm(-2),
                          ),
                          Column(
                            children: [
                              Text(
                                '${c.currentBpm}',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                s['stepsPerMin'],
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add),
                            onPressed: () => c.adjustBpm(2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['adjustHint'],
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  const SizedBox(height: 16),

                  // Controls
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: Icon(c.state == SessionState.paused
                              ? Icons.play_arrow
                              : Icons.pause),
                          label: Text(c.state == SessionState.paused
                              ? s['resume']
                              : s['pause']),
                          onPressed: () => c.state == SessionState.paused
                              ? c.resume()
                              : c.pause(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.fastColor),
                          icon: const Icon(Icons.stop),
                          label: Text(s['stop']),
                          onPressed: () {
                            c.stopSession();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.s});
  final S s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events,
                size: 96, color: AppTheme.slowColor),
            const SizedBox(height: 24),
            Text(s['finished'],
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(s['sessionSummary'],
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s['done']),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular phase-progress ring with a rounded cap.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawArc(r, 0, math.pi * 2, false, bg);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
