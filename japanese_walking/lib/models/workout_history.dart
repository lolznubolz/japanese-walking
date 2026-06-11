import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One finished workout.
class WorkoutRecord {
  WorkoutRecord(
      {required this.day,
      required this.minutes,
      required this.steps,
      required this.kcal});

  final String day; // yyyy-MM-dd
  final int minutes;
  final int steps;
  final int kcal;

  Map<String, dynamic> toJson() =>
      {'d': day, 'min': minutes, 'st': steps, 'kc': kcal};

  factory WorkoutRecord.fromJson(Map<String, dynamic> j) => WorkoutRecord(
      day: j['d'] as String,
      minutes: (j['min'] as num).toInt(),
      steps: (j['st'] as num).toInt(),
      kcal: (j['kc'] as num).toInt());
}

/// Journal stored in SharedPreferences (newest first, capped at 300).
class WorkoutHistory {
  static const _key = 'jwHist';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<WorkoutRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString(_key) ?? '[]') as List;
      return raw
          .map((e) => WorkoutRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(WorkoutRecord r) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load()
      ..insert(0, r);
    await prefs.setString(
        _key, jsonEncode(list.take(300).map((e) => e.toJson()).toList()));
  }

  /// Consecutive training days; today not yet trained doesn't break it.
  static int streak(List<WorkoutRecord> history) {
    final days = history.map((r) => r.day).toSet();
    var cur = DateTime.now();
    cur = DateTime(cur.year, cur.month, cur.day);
    var n = 0;
    if (!days.contains(dayKey(cur))) {
      cur = cur.subtract(const Duration(days: 1));
    }
    while (days.contains(dayKey(cur))) {
      n++;
      cur = cur.subtract(const Duration(days: 1));
    }
    return n;
  }
}
