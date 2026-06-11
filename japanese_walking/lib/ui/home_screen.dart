import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../services/heart_rate_service.dart';
import '../theme.dart';
import 'session_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.settings, required this.hr});

  final AppSettings settings;
  final HeartRateService hr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(settings.localeCode);
    final total = settings.totalDuration.inMinutes;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s['appTitle'],
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(settings: settings, hr: hr),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(s['subtitle'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      )),
              const SizedBox(height: 32),

              // Protocol summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ProtocolRow(
                        color: AppTheme.fastColor,
                        label: s['fastPhase'],
                        value:
                            '${settings.phaseSeconds ~/ 60} ${s['minutes']} · ${settings.fastBpm} ${s['stepsPerMin']}',
                      ),
                      const SizedBox(height: 12),
                      _ProtocolRow(
                        color: AppTheme.slowColor,
                        label: s['slowPhase'],
                        value:
                            '${settings.phaseSeconds ~/ 60} ${s['minutes']} · ${settings.slowBpm} ${s['stepsPerMin']}',
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${s['cyclesCount']}: ${settings.cycles}'),
                          Text('${s['totalTime']}: $total ${s['minutes']}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Heart-rate chip
              ListenableBuilder(
                listenable: hr,
                builder: (context, _) => hr.connected
                    ? Card(
                        child: ListTile(
                          leading: const Icon(Icons.favorite,
                              color: AppTheme.fastColor),
                          title: Text(
                              '${hr.bpm ?? '—'} ${s['bpm']} · ${hr.deviceName}'),
                          subtitle: Text(s['connected']),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const Spacer(),

              // About
              Text(s['aboutMethod'],
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                s['aboutText'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.directions_walk),
                  label: Text(s['start']),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionScreen(settings: settings, hr: hr),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow(
      {required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value),
      ],
    );
  }
}
