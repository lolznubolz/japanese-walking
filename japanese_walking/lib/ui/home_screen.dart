import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../models/workout_history.dart';
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
          child: SingleChildScrollView(
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
                const SizedBox(height: 24),

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
                            Text('${s['cyclesCount']}: ${settings.cycles}'),
                            Text('${s['totalTime']}: $total ${s['minutes']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

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

                // Weekly goal, progression, history
                FutureBuilder<List<WorkoutRecord>>(
                  future: WorkoutHistory.load(),
                  builder: (context, snap) {
                    final h = snap.data ?? [];
                    return _DashboardSection(
                        settings: settings, s: s, history: h);
                  },
                ),
                const SizedBox(height: 12),

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
      ),
    );
  }
}

/// Weekly-goal bar, progression suggestion, badges, weekly chart, journal.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection(
      {required this.settings, required this.s, required this.history});

  final AppSettings settings;
  final S s;
  final List<WorkoutRecord> history;

  @override
  Widget build(BuildContext context) {
    final fm = WorkoutHistory.thisWeekFast(history);
    final goal = settings.goalMinutes;
    final weekN = WorkoutHistory.programWeek(history);
    final recCycles = (1 + weekN).clamp(1, 5);
    final showProg =
        history.isNotEmpty && weekN <= 5 && settings.cycles < recCycles;
    final weeks = WorkoutHistory.lastWeeks(history, 8);
    final maxV = [goal.toDouble(), ...weeks]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);
    final km = history.fold<int>(0, (a, r) => a + r.steps) * 0.7 / 1000;
    final streak = WorkoutHistory.streak(history);
    final badges = <String>[
      if (history.isNotEmpty) '🥇 1',
      if (history.length >= 10) '🏅 10',
      if (history.length >= 50) '💪 50',
      if (streak >= 7) '🔥 7',
      if (streak >= 30) '🌟 30',
      if (km >= 100) '🚶 100 km',
    ];

    return Column(
      children: [
        // Weekly goal
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['weeklyGoal']),
                    Text(
                      '${fm.round()} / $goal ${s['minU']}${fm >= goal ? ' ✅' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (fm / goal).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: AppTheme.fastColor,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Progression suggestion (first 5 weeks)
        if (showProg)
          Card(
            child: ListTile(
              title: Text(
                '📈 ${s['progrW']} $weekN ${s['progrR']} $recCycles ${s['progrC']}',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: TextButton(
                onPressed: () => settings.cycles = recCycles,
                child: Text(s['apply']),
              ),
            ),
          ),

        // History
        if (history.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🔥 ${s['streak']}'),
                      Text('$streak',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['totalWorkouts']),
                      Text('${history.length}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final b in badges)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(b,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(s['chartT'],
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 70,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final v in weeks)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                height: (v / maxV * 66).clamp(2.0, 66.0),
                                decoration: BoxDecoration(
                                  color: v >= goal
                                      ? AppTheme.fastColor
                                      : Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  for (final r in history.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.day,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.55))),
                          Text(
                            '${r.minutes} ${s['minU']} · ${r.steps} 👟 · ${r.kcal} ${s['kcalU']}'
                            '${r.avgHr > 0 ? ' · ♥${r.avgHr}' : ''}'
                            '${r.recovery > 0 ? ' ↓${r.recovery}' : ''}',
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.white.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
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
