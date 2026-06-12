import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One finished workout.
class WorkoutRecord {
  WorkoutRecord({
    required this.day,
    required this.minutes,
    required this.steps,
    required this.kcal,
    this.fastMin = 0,
    this.avgHr = 0,
    this.recovery = 0,
  });

  final String day; // yyyy-MM-dd
  final int minutes;
  final int steps;
  final int kcal;

  /// Minutes spent in the fast phase (weekly-goal currency).
  final double fastMin;

  /// Average HR over the session (0 if no monitor).
  final int avgHr;

  /// Average 1-minute HR drop after fast phases (0 if no monitor).
  final int recovery;

  Map<String, dynamic> toJson() => {
        'd': day,
        'min': minutes,
        'st': steps,
        'kc': kcal,
        'fm': fastMin,
        'hr': avgHr,
        'rec': recovery,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> j) => WorkoutRecord(
        day: j['d'] as String,
        minutes: (j['min'] as num).toInt(),
        steps: (j['st'] as num).toInt(),
        kcal: (j['kc'] as num).toInt(),
        fastMin: ((j['fm'] ?? 0) as num).toDouble(),
        avgHr: ((j['hr'] ?? 0) as num).toInt(),
        recovery: ((j['rec'] ?? 0) as num).toInt(),
      );
}

/// Journal stored in SharedPreferences (newest first, capped at 300).
class WorkoutHistory {
  static const _key = 'jwHist';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Monday of the week containing [day] (yyyy-MM-dd).
  static String weekKey(String day) {
    final d = DateTime.parse(day);
    return dayKey(d.subtract(Duration(days: d.weekday - 1)));
  }

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

  /// Fast minutes accumulated in the current calendar week.
  static double thisWeekFast(List<WorkoutRecord> history) {
    final wk = weekKey(dayKey(DateTime.now()));
    return history
        .where((r) => weekKey(r.day) == wk)
        .fold(0.0, (a, r) => a + r.fastMin);
  }

  /// Fast minutes per week for the last [n] weeks (oldest first).
  static List<double> lastWeeks(List<WorkoutRecord> history, int n) {
    final sums = <String, double>{};
    for (final r in history) {
      sums.update(weekKey(r.day), (v) => v + r.fastMin,
          ifAbsent: () => r.fastMin);
    }
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return [
      for (var i = n - 1; i >= 0; i--)
        sums[dayKey(monday.subtract(Duration(days: 7 * i)))] ?? 0
    ];
  }

  /// Program week number since the very first workout (1-based).
  static int programWeek(List<WorkoutRecord> history) {
    if (history.isEmpty) return 1;
    final first = DateTime.parse(history.last.day);
    return DateTime.now().difference(first).inDays ~/ 7 + 1;
  }
}
