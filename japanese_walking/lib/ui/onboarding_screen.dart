import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';

/// First-launch setup: language, age, weight, weekly goal.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = S.of(settings.localeCode);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text('🚶 ${s['appTitle']}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(s['onbText'],
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ru', label: Text('Русский')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.localeCode},
                onSelectionChanged: (sel) => settings.localeCode = sel.first,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _slider(context, s['age'], '${settings.age}',
                          settings.age.toDouble(), 14, 90,
                          (v) => settings.age = v.round()),
                      _slider(
                          context,
                          s['weight'],
                          '${settings.weightKg} ${s['kg']}',
                          settings.weightKg.toDouble(),
                          40,
                          150,
                          (v) => settings.weightKg = v.round()),
                      _slider(
                          context,
                          s['goalSetting'],
                          '${settings.goalMinutes} ${s['minU']}',
                          settings.goalMinutes.toDouble(),
                          30,
                          180,
                          (v) => settings.goalMinutes = v.round()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => settings.onboarded = true,
                child: Text(s['onbStart']),
              ),
              const SizedBox(height: 24),
              Text(s['aboutText'],
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(BuildContext context, String title, String label,
      double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
        Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged),
      ],
    );
  }
}
