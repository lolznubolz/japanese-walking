import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_settings.dart';
import '../services/heart_rate_service.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings, required this.hr});

  final AppSettings settings;
  final HeartRateService hr;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = S.of(settings.localeCode);
        return Scaffold(
          appBar: AppBar(title: Text(s['settings'])),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Pace ---
              _SliderTile(
                title: s['fastPace'],
                color: AppTheme.fastColor,
                value: settings.fastBpm.toDouble(),
                min: 90,
                max: 190,
                label: '${settings.fastBpm} ${s['stepsPerMin']}',
                onChanged: (v) => settings.fastBpm = v.round(),
              ),
              _SliderTile(
                title: s['slowPace'],
                color: AppTheme.slowColor,
                value: settings.slowBpm.toDouble(),
                min: 50,
                max: 140,
                label: '${settings.slowBpm} ${s['stepsPerMin']}',
                onChanged: (v) => settings.slowBpm = v.round(),
              ),

              // --- Protocol ---
              _SliderTile(
                title: s['phaseLength'],
                value: settings.phaseSeconds.toDouble(),
                min: 60,
                max: 300,
                divisions: 8,
                label:
                    '${(settings.phaseSeconds / 60).toStringAsFixed(settings.phaseSeconds % 60 == 0 ? 0 : 1)} ${s['minutes']}',
                onChanged: (v) => settings.phaseSeconds = v.round(),
              ),
              _SliderTile(
                title: s['cyclesCount'],
                value: settings.cycles.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label:
                    '${settings.cycles} (${s['totalTime']}: ${settings.totalDuration.inMinutes} ${s['minutes']})',
                onChanged: (v) => settings.cycles = v.round(),
              ),

              const SizedBox(height: 8),

              // --- Feedback ---
              SwitchListTile(
                title: Text(s['metronome']),
                value: settings.metronomeEnabled,
                onChanged: (v) => settings.metronomeEnabled = v,
              ),
              if (settings.metronomeEnabled)
                _SliderTile(
                  title: s['tickVolume'],
                  value: settings.tickVolume,
                  min: 0,
                  max: 1,
                  label: '${(settings.tickVolume * 100).round()}%',
                  onChanged: (v) => settings.tickVolume = v,
                ),
              SwitchListTile(
                title: Text(s['vibration']),
                value: settings.vibrationEnabled,
                onChanged: (v) => settings.vibrationEnabled = v,
              ),
              SwitchListTile(
                title: Text(s['phaseSounds']),
                value: settings.phaseSoundsEnabled,
                onChanged: (v) => settings.phaseSoundsEnabled = v,
              ),
              SwitchListTile(
                title: Text(s['voice']),
                value: settings.voiceEnabled,
                onChanged: (v) => settings.voiceEnabled = v,
              ),
              _SliderTile(
                title: s['weight'],
                value: settings.weightKg.toDouble(),
                min: 40,
                max: 150,
                label: '${settings.weightKg} ${s['kg']}',
                onChanged: (v) => settings.weightKg = v.round(),
              ),

              const Divider(height: 32),

              // --- Smart mode ---
              SwitchListTile(
                title: Text(s['smartMode']),
                subtitle: Text(s['smartHint'],
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5))),
                value: settings.smartMode,
                onChanged: (v) => settings.smartMode = v,
              ),
              if (settings.smartMode) ...[
                _SliderTile(
                  title: s['age'],
                  value: settings.age.toDouble(),
                  min: 14,
                  max: 90,
                  label: '${settings.age}',
                  onChanged: (v) => settings.age = v.round(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${s['targetZone']}: 🔥 ${settings.hrZone(fast: true).$1}–${settings.hrZone(fast: true).$2} · '
                    '🌿 ${settings.hrZone(fast: false).$1}–${settings.hrZone(fast: false).$2}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ],

              const Divider(height: 32),

              // --- Heart rate / smartwatch ---
              Text(s['heartRate'],
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _HeartRateSection(hr: hr, s: s),

              const Divider(height: 32),

              // --- Language ---
              Text(s['language'],
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ru', label: Text('Русский')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.localeCode},
                onSelectionChanged: (sel) => settings.localeCode = sel.first,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    this.divisions,
    this.color,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final Color? color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(label,
                    style: TextStyle(
                        color: color ?? Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _HeartRateSection extends StatelessWidget {
  const _HeartRateSection({required this.hr, required this.s});

  final HeartRateService hr;
  final S s;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hr,
      builder: (context, _) {
        if (hr.connected) {
          return Card(
            child: ListTile(
              leading:
                  const Icon(Icons.favorite, color: AppTheme.fastColor),
              title: Text(hr.deviceName),
              subtitle: Text('${s['connected']} · ${hr.bpm ?? '—'} ${s['bpm']}'),
              trailing: TextButton(
                onPressed: hr.disconnect,
                child: Text(s['disconnect']),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonalIcon(
              icon: hr.scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bluetooth_searching),
              label: Text(hr.scanning ? s['scanning'] : s['connectWatch']),
              onPressed: hr.scanning ? null : () => _scan(context),
            ),
            const SizedBox(height: 8),
            for (final r in hr.results)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.watch),
                  title: Text(r.device.platformName.isEmpty
                      ? r.device.remoteId.str
                      : r.device.platformName),
                  subtitle: Text('${r.rssi} dBm'),
                  onTap: () => hr.connect(r.device),
                ),
              ),
            if (!hr.scanning && hr.results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s['noDevices'],
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _scan(BuildContext context) async {
    if (!await hr.isSupported) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s['btUnavailable'])),
        );
      }
      return;
    }
    await hr.startScan();
  }
}
