import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlueprintController extends ChangeNotifier {
  BlueprintController({
    required List<WellnessTreatment> treatments,
    required Map<int, WeeklyRoutine> initialRoutines,
  })  : _treatments = List<WellnessTreatment>.unmodifiable(treatments),
        _weeklyRoutines = Map<int, WeeklyRoutine>.from(initialRoutines);

  static const String disclaimer =
      'This app provides wellness guidance based on published literature and is not a medical device.';

  static const _prefsPlans = 'bp1_plans';
  static const _prefsHistory = 'bp1_history';
  static const _prefsRoutines = 'bp1_routines';

  final List<WellnessTreatment> _treatments;
  Map<String, List<PlannedSession>> _plans = <String, List<PlannedSession>>{};
  List<SessionHistoryEntry> _history = <SessionHistoryEntry>[];
  Map<int, WeeklyRoutine> _weeklyRoutines;
  bool _ready = false;

  bool get ready => _ready;
  List<WellnessTreatment> get treatments => _treatments;
  List<SessionHistoryEntry> get history =>
      List<SessionHistoryEntry>.unmodifiable(_history);
  Map<int, WeeklyRoutine> get weeklyRoutines =>
      Map<int, WeeklyRoutine>.unmodifiable(_weeklyRoutines);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final plansRaw = prefs.getString(_prefsPlans);
    if (plansRaw != null && plansRaw.isNotEmpty) {
      final decoded = json.decode(plansRaw) as Map<String, dynamic>;
      _plans = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((entry) => PlannedSession.fromJson(
                  Map<String, dynamic>.from(entry as Map)))
              .toList(),
        ),
      );
    }

    final historyRaw = prefs.getString(_prefsHistory);
    if (historyRaw != null && historyRaw.isNotEmpty) {
      _history = (json.decode(historyRaw) as List)
          .map((entry) =>
              SessionHistoryEntry.fromJson(Map<String, dynamic>.from(entry)))
          .toList();
    }

    final routinesRaw = prefs.getString(_prefsRoutines);
    if (routinesRaw != null && routinesRaw.isNotEmpty) {
      final decoded = json.decode(routinesRaw) as Map<String, dynamic>;
      _weeklyRoutines = decoded.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 1,
          WeeklyRoutine.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    }

    _ready = true;
    notifyListeners();
  }

  WellnessTreatment? treatmentById(String id) {
    for (final treatment in _treatments) {
      if (treatment.id == id) return treatment;
    }
    return null;
  }

  String dateKeyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  List<PlannedSession> plansFor(DateTime date) {
    final key = dateKeyFor(date);
    return List<PlannedSession>.from(_plans[key] ?? const []);
  }

  List<SessionHistoryEntry> historyFor(DateTime date) {
    final key = dateKeyFor(date);
    return _history.where((entry) => entry.dateKey == key).toList()
      ..sort((a, b) => b.loggedAtIso.compareTo(a.loggedAtIso));
  }

  int plannedCountFor(DateTime date) => plansFor(date).length;

  bool isPlannedOn(DateTime date, String treatmentId) {
    return plansFor(date).any((entry) => entry.treatmentId == treatmentId);
  }

  Future<void> scheduleTreatment({
    required WellnessTreatment treatment,
    required DateTime date,
    String momentLabel = 'Planned',
  }) async {
    final key = dateKeyFor(date);
    final existing = List<PlannedSession>.from(_plans[key] ?? const []);
    if (!existing.any((entry) => entry.treatmentId == treatment.id)) {
      existing.add(
        PlannedSession(
          treatmentId: treatment.id,
          dateKey: key,
          momentLabel: momentLabel,
        ),
      );
      _plans[key] = existing;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> unscheduleTreatment({
    required DateTime date,
    required String treatmentId,
  }) async {
    final key = dateKeyFor(date);
    final existing = List<PlannedSession>.from(_plans[key] ?? const []);
    existing.removeWhere((entry) => entry.treatmentId == treatmentId);
    if (existing.isEmpty) {
      _plans.remove(key);
    } else {
      _plans[key] = existing;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> markStatus({
    required DateTime date,
    required WellnessTreatment treatment,
    required SessionStatus status,
    String momentLabel = 'Tracked',
  }) async {
    await unscheduleTreatment(date: date, treatmentId: treatment.id);
    _history.add(
      SessionHistoryEntry(
        id: '${treatment.id}_${DateTime.now().microsecondsSinceEpoch}',
        treatmentId: treatment.id,
        loggedAtIso: DateTime.now().toIso8601String(),
        dateKey: dateKeyFor(date),
        status: status,
        momentLabel: momentLabel,
      ),
    );
    _history.sort((a, b) => b.loggedAtIso.compareTo(a.loggedAtIso));
    await _persist();
    notifyListeners();
  }

  Future<void> updateRoutine({
    required int weekday,
    required String focusLabel,
    required String cardioLabel,
  }) async {
    _weeklyRoutines[weekday] = WeeklyRoutine(
      weekday: weekday,
      focusLabel: focusLabel,
      cardioLabel: cardioLabel,
    );
    await _persist();
    notifyListeners();
  }

  String exportHistoryAsCsv() {
    final buffer = StringBuffer(
      'date,status,treatment_id,treatment_title,moment,logged_at\n',
    );
    for (final entry in _history) {
      final treatment = treatmentById(entry.treatmentId);
      buffer.writeln(
        [
          entry.dateKey,
          entry.status.name,
          entry.treatmentId,
          treatment?.title ?? 'Unknown',
          entry.momentLabel,
          entry.loggedAtIso,
        ].map(_csvEscape).join(','),
      );
    }
    return buffer.toString();
  }

  String exportHistoryAsJson() {
    final payload = _history.map((entry) {
      final treatment = treatmentById(entry.treatmentId);
      return {
        ...entry.toJson(),
        'treatmentTitle': treatment?.title ?? 'Unknown',
      };
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsPlans,
      json.encode(
        _plans.map(
          (key, value) =>
              MapEntry(key, value.map((entry) => entry.toJson()).toList()),
        ),
      ),
    );
    await prefs.setString(
      _prefsHistory,
      json.encode(_history.map((entry) => entry.toJson()).toList()),
    );
    await prefs.setString(
      _prefsRoutines,
      json.encode(
        _weeklyRoutines.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
      ),
    );
  }

  String _csvEscape(Object? value) {
    final raw = (value ?? '').toString().replaceAll('"', '""');
    return '"$raw"';
  }
}
