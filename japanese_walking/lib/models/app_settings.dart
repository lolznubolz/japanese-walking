import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-adjustable settings, persisted between launches.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs);
  }

  // --- Pace (steps per minute = metronome BPM) ---
  int get fastBpm => _prefs.getInt('fastBpm') ?? 135;
  set fastBpm(int v) => _set('fastBpm', v.clamp(90, 190));

  int get slowBpm => _prefs.getInt('slowBpm') ?? 100;
  set slowBpm(int v) => _set('slowBpm', v.clamp(50, 140));

  // --- Protocol ---
  /// Length of one phase in seconds (classic IWT: 180 s).
  int get phaseSeconds => _prefs.getInt('phaseSeconds') ?? 180;
  set phaseSeconds(int v) => _set('phaseSeconds', v.clamp(30, 600));

  /// Number of fast+slow cycles (classic IWT: 5 → 30 min).
  int get cycles => _prefs.getInt('cycles') ?? 5;
  set cycles(int v) => _set('cycles', v.clamp(1, 12));

  // --- Feedback ---
  bool get metronomeEnabled => _prefs.getBool('metronomeEnabled') ?? true;
  set metronomeEnabled(bool v) => _set('metronomeEnabled', v);

  bool get vibrationEnabled => _prefs.getBool('vibrationEnabled') ?? true;
  set vibrationEnabled(bool v) => _set('vibrationEnabled', v);

  bool get phaseSoundsEnabled => _prefs.getBool('phaseSoundsEnabled') ?? true;
  set phaseSoundsEnabled(bool v) => _set('phaseSoundsEnabled', v);

  double get tickVolume => _prefs.getDouble('tickVolume') ?? 0.8;
  set tickVolume(double v) {
    _prefs.setDouble('tickVolume', v.clamp(0.0, 1.0));
    notifyListeners();
  }

  // --- Locale: 'ru' | 'en' ---
  String get localeCode => _prefs.getString('localeCode') ?? 'ru';
  set localeCode(String v) {
    _prefs.setString('localeCode', v);
    notifyListeners();
  }

  Duration get totalDuration =>
      Duration(seconds: phaseSeconds * 2 * cycles);

  void _set(String key, Object v) {
    if (v is int) _prefs.setInt(key, v);
    if (v is bool) _prefs.setBool(key, v);
    notifyListeners();
  }
}
