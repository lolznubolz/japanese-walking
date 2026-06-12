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

  // --- Voice cues, smart mode, body metrics ---
  bool get voiceEnabled => _prefs.getBool('voiceEnabled') ?? false;
  set voiceEnabled(bool v) => _set('voiceEnabled', v);

  /// Auto-adjust cadence to keep HR in zone (needs a connected HR monitor).
  bool get smartMode => _prefs.getBool('smartMode') ?? false;
  set smartMode(bool v) => _set('smartMode', v);

  int get age => _prefs.getInt('age') ?? 40;
  set age(int v) => _set('age', v.clamp(14, 90));

  int get weightKg => _prefs.getInt('weightKg') ?? 75;
  set weightKg(int v) => _set('weightKg', v.clamp(40, 150));

  /// First-launch onboarding shown?
  bool get onboarded => _prefs.getBool('onboarded') ?? false;
  set onboarded(bool v) => _set('onboarded', v);

  /// Weekly goal: fast-phase minutes (Shinshu studies: ≥60 min/week).
  int get goalMinutes => _prefs.getInt('goalMinutes') ?? 60;
  set goalMinutes(int v) => _set('goalMinutes', v.clamp(30, 180));

  /// Personal fast-zone HR from the 3-min calibration test (0 = not done).
  int get calibHr => _prefs.getInt('calibHr') ?? 0;
  set calibHr(int v) => _set('calibHr', v.clamp(0, 220));

  /// Tanaka formula.
  int get hrMax => (208 - 0.7 * age).round();

  /// (lo, hi) target HR for a phase: fast 70–80% of max (or the personal
  /// calibrated zone), slow 50–65% of max.
  (int, int) hrZone({required bool fast}) => fast
      ? (calibHr > 0
          ? (calibHr - 8, calibHr + 4)
          : ((hrMax * 0.70).round(), (hrMax * 0.80).round()))
      : ((hrMax * 0.50).round(), (hrMax * 0.65).round());

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
