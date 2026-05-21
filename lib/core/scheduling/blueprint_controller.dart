import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mega_panel_ai/core/ai/ai_treatment_search_service.dart';
import 'package:mega_panel_ai/core/evidence/training_compatibility.dart';
import 'package:intl/intl.dart';
import 'package:mega_panel_ai/core/scheduling/notification_service.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlueprintController extends ChangeNotifier {
  BlueprintController({
    required List<WellnessTreatment> treatments,
    AiTreatmentSearchService? aiTreatmentSearchService,
    NotificationService? notificationService,
    bool demoMode = false,
  })  : _catalogTreatments = List<WellnessTreatment>.unmodifiable(treatments),
        _aiTreatmentSearchService = aiTreatmentSearchService,
        _notificationService = notificationService ?? NotificationService(),
        _demoMode = demoMode;

  static const _prefsPlans = 'bp1_plans';
  static const _prefsHistory = 'bp1_history';
  static const _prefsReminderSettings = 'bp1_reminder_settings';
  static const _prefsLanguage = 'bp1_language';
  static const _prefsRecentTraining = 'bp1_recent_training';
  static const _prefsAiDraftTreatments = 'bp2_ai_draft_treatments';
  static const _prefsUserTreatments = 'bp2_user_treatments';

  final List<WellnessTreatment> _catalogTreatments;
  final AiTreatmentSearchService? _aiTreatmentSearchService;
  final NotificationService _notificationService;
  final bool _demoMode;

  Map<String, List<PlannedSession>> _plans = <String, List<PlannedSession>>{};
  List<SessionHistoryEntry> _history = <SessionHistoryEntry>[];
  List<WellnessTreatment> _aiDraftTreatments = <WellnessTreatment>[];
  List<WellnessTreatment> _userTreatments = <WellnessTreatment>[];
  Map<TrainingType, RecentTrainingSession> _recentTraining =
      <TrainingType, RecentTrainingSession>{};
  ReminderSettings _reminderSettings = const ReminderSettings(
    enabled: false,
    reminders: <ReminderPreference>[
      ReminderPreference(
        id: 'default_same_day',
        leadTime: ReminderLeadTime.sameDay,
        hour: 9,
        minute: 0,
      ),
    ],
  );
  bool _ready = false;
  bool _notificationsSupported = false;
  bool _notificationsPermissionGranted = false;
  AppLanguage _language = AppLanguage.english;

  bool get ready => _ready;
  bool get notificationsSupported => _notificationsSupported;
  bool get notificationsPermissionGranted => _notificationsPermissionGranted;
  bool get aiSearchAvailable =>
      _aiTreatmentSearchService != null &&
      _aiTreatmentSearchService.isConfigured;
  List<WellnessTreatment> get curatedTreatments => _catalogTreatments;
  List<WellnessTreatment> get aiDraftTreatments =>
      List<WellnessTreatment>.unmodifiable(_aiDraftTreatments);
  List<WellnessTreatment> get myTreatments =>
      List<WellnessTreatment>.unmodifiable(_userTreatments);
  List<WellnessTreatment> get treatments => List<WellnessTreatment>.unmodifiable(
        [
          ..._catalogTreatments,
          ..._userTreatments,
          ..._aiDraftTreatments,
        ],
      );
  List<SessionHistoryEntry> get history =>
      List<SessionHistoryEntry>.unmodifiable(_history);
  ReminderSettings get reminderSettings => _reminderSettings;
  AppLanguage get language => _language;
  List<RecentTrainingSession> get recentTrainingSessions =>
      _recentTraining.values.toList(growable: false)
        ..sort((a, b) => b.performedAtIso.compareTo(a.performedAtIso));
  bool get hasRecentTraining => _recentTraining.isNotEmpty;

  Future<void> load() async {
    SharedPreferences? prefs;
    if (!_demoMode) {
      prefs = await SharedPreferences.getInstance();
    }
    _language = _resolveInitialLanguage(prefs?.getString(_prefsLanguage));

    if (_demoMode) {
      _notificationsSupported = _notificationService.isSupported;
      if (_notificationsSupported) {
        await _notificationService.initialize();
        _notificationsPermissionGranted =
            await _notificationService.areNotificationsEnabled();
      }
      _seedDemoData();
      _ready = true;
      await _syncNotifications();
      notifyListeners();
      return;
    }

    final storedPrefs = prefs!;

    _notificationsSupported = _notificationService.isSupported;
    if (_notificationsSupported) {
      await _notificationService.initialize();
      _notificationsPermissionGranted =
          await _notificationService.areNotificationsEnabled();
    }

    final plansRaw = storedPrefs.getString(_prefsPlans);
    if (plansRaw != null && plansRaw.isNotEmpty) {
      final decoded = json.decode(plansRaw) as Map<String, dynamic>;
      _plans = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map(
                (entry) => PlannedSession.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
        ),
      );
    }

    final historyRaw = storedPrefs.getString(_prefsHistory);
    if (historyRaw != null && historyRaw.isNotEmpty) {
      _history = (json.decode(historyRaw) as List)
          .map(
            (entry) => SessionHistoryEntry.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    }

    final reminderRaw = storedPrefs.getString(_prefsReminderSettings);
    if (reminderRaw != null && reminderRaw.isNotEmpty) {
      _reminderSettings = ReminderSettings.fromJson(
        Map<String, dynamic>.from(json.decode(reminderRaw) as Map),
      );
    }

    final trainingRaw = storedPrefs.getString(_prefsRecentTraining);
    if (trainingRaw != null && trainingRaw.isNotEmpty) {
      final decoded = json.decode(trainingRaw) as List;
      final decodedSessions = decoded
          .map(
            (entry) => RecentTrainingSession.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);
      _recentTraining = {
        for (final session in decodedSessions) session.type: session,
      };
    }

    final aiDraftRaw = storedPrefs.getString(_prefsAiDraftTreatments);
    if (aiDraftRaw != null && aiDraftRaw.isNotEmpty) {
      _aiDraftTreatments = (json.decode(aiDraftRaw) as List)
          .map(
            (entry) => WellnessTreatment.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);
    }

    final userTreatmentsRaw = storedPrefs.getString(_prefsUserTreatments);
    if (userTreatmentsRaw != null && userTreatmentsRaw.isNotEmpty) {
      _userTreatments = (json.decode(userTreatmentsRaw) as List)
          .map(
            (entry) => WellnessTreatment.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);
    }

    _ready = true;
    await _syncNotifications();
    notifyListeners();
  }

  AppLanguage _resolveInitialLanguage(String? rawLanguage) {
    if (rawLanguage == AppLanguage.spanish.name) {
      return AppLanguage.spanish;
    }
    if (rawLanguage == AppLanguage.english.name) {
      return AppLanguage.english;
    }

    final languageCode =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (languageCode.startsWith('es')) {
      return AppLanguage.spanish;
    }
    return AppLanguage.english;
  }

  List<WellnessTreatment> catalogForOrigin(TreatmentOrigin origin) {
    switch (origin) {
      case TreatmentOrigin.curated:
        return curatedTreatments;
      case TreatmentOrigin.aiDraft:
        return aiDraftTreatments;
      case TreatmentOrigin.userTreatment:
        return myTreatments;
    }
  }

  WellnessTreatment? treatmentById(String id) {
    for (final treatment in treatments) {
      if (treatment.id == id) return treatment;
    }
    return null;
  }

  String dateKeyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime dateFromKey(String dateKey) {
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) {
      return DateTime.now();
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

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

  int plannedCountForWeek(DateTime anchor) {
    final week = weekFor(anchor);
    return week.fold<int>(0, (count, day) => count + plannedCountFor(day));
  }

  int trackedCountForWeek(DateTime anchor) {
    final weekKeys = weekFor(anchor).map(dateKeyFor).toSet();
    return _history.where((entry) => weekKeys.contains(entry.dateKey)).length;
  }

  bool isPlannedOn(DateTime date, String treatmentId) {
    return plansFor(date).any((entry) => entry.treatmentId == treatmentId);
  }

  List<DateTime> weekFor(DateTime date) {
    final first = date.subtract(Duration(days: date.weekday - 1));
    return List<DateTime>.generate(
      7,
      (index) => DateTime(first.year, first.month, first.day + index),
    );
  }

  ResolvedPlannedSession? get nextPlannedSession {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final sortedKeys = _plans.keys.toList()..sort();
    for (final key in sortedKeys) {
      final date = dateFromKey(key);
      if (date.isBefore(dayStart)) continue;
      final sessions = List<PlannedSession>.from(_plans[key] ?? const [])
        ..sort((a, b) => a.momentLabel.compareTo(b.momentLabel));
      for (final session in sessions) {
        final treatment = treatmentById(session.treatmentId);
        if (treatment != null) {
          return ResolvedPlannedSession(
            treatment: treatment,
            session: session,
            date: date,
          );
        }
      }
    }
    return null;
  }

  List<TreatmentCourseProgress> activeCoursesForTreatment(String treatmentId) {
    return _courseProgressEntries()
        .where((entry) => entry.treatment.id == treatmentId)
        .toList(growable: false);
  }

  List<TreatmentCourseProgress> _courseProgressEntries() {
    final groupedPlans = <String, List<ResolvedPlannedSession>>{};
    final groupedHistory = <String, List<SessionHistoryEntry>>{};

    final sortedKeys = _plans.keys.toList()..sort();
    for (final key in sortedKeys) {
      final date = dateFromKey(key);
      for (final session in _plans[key] ?? const []) {
        if (!session.isPartOfCourse) continue;
        final treatment = treatmentById(session.treatmentId);
        final courseId = session.courseId;
        if (treatment == null || courseId == null) continue;
        groupedPlans.putIfAbsent(courseId, () => <ResolvedPlannedSession>[]).add(
              ResolvedPlannedSession(
                treatment: treatment,
                session: session,
                date: date,
              ),
            );
      }
    }

    for (final entry in _history) {
      if (!entry.isPartOfCourse) continue;
      final courseId = entry.courseId;
      if (courseId == null) continue;
      groupedHistory.putIfAbsent(courseId, () => <SessionHistoryEntry>[]).add(entry);
    }

    final courseIds = {...groupedPlans.keys, ...groupedHistory.keys}.toList()..sort();
    final result = <TreatmentCourseProgress>[];
    for (final courseId in courseIds) {
      final planEntries = groupedPlans[courseId] ?? const <ResolvedPlannedSession>[];
      final historyEntries = groupedHistory[courseId] ?? const <SessionHistoryEntry>[];
      final treatment = planEntries.isNotEmpty
          ? planEntries.first.treatment
          : treatmentById(historyEntries.first.treatmentId);
      if (treatment == null) continue;
      final targetSessions = [
        ...planEntries
            .map((entry) => entry.session.courseSessionTarget)
            .whereType<int>(),
        ...historyEntries
            .map((entry) => entry.courseSessionTarget)
            .whereType<int>(),
      ].fold<int>(0, (current, value) => value > current ? value : current);
      if (targetSessions <= 0) continue;
      final completedSessions = historyEntries
          .where((entry) => entry.status == SessionStatus.completed)
          .length;
      final skippedSessions = historyEntries
          .where((entry) => entry.status == SessionStatus.skipped)
          .length;
      final nextPlannedDate = planEntries.isEmpty
          ? null
          : (planEntries.toList()..sort((a, b) => a.date.compareTo(b.date))).first.date;
      final progress = TreatmentCourseProgress(
        courseId: courseId,
        treatment: treatment,
        targetSessions: targetSessions,
        completedSessions: completedSessions,
        skippedSessions: skippedSessions,
        nextPlannedDate: nextPlannedDate,
      );
      if (progress.isComplete && nextPlannedDate == null) {
        continue;
      }
      result.add(progress);
    }
    result.sort((a, b) {
      final aDate = a.nextPlannedDate;
      final bDate = b.nextPlannedDate;
      if (aDate == null && bDate == null) {
        return a.treatment.title(_language == AppLanguage.spanish)
            .compareTo(b.treatment.title(_language == AppLanguage.spanish));
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return result;
  }

  String reminderSummaryForPlan(
    PlannedSession session,
    BlueprintStrings strings,
  ) {
    final enabledReminders =
        _reminderSettings.reminders.where((entry) => entry.enabled).toList();
    if (!_reminderSettings.enabled || enabledReminders.isEmpty) {
      return strings.remindersOff;
    }
    if (enabledReminders.length == 1) {
      return strings.reminderPreferenceSummary(enabledReminders.first);
    }
    return strings.reminderSummary(enabledReminders.length, true);
  }

  List<DateTime> reminderTimesFor(DateTime date) {
    if (!_reminderSettings.enabled) return const [];
    final times = _reminderSettings.reminders
        .where((entry) => entry.enabled)
        .map((entry) => DateTime(
              date.year,
              date.month,
              date.day - entry.leadTime.daysOffset,
              entry.hour,
              entry.minute,
            ))
        .toList()
      ..sort();
    return times;
  }

  Future<bool> requestNotificationPermissions() async {
    if (!_notificationsSupported) return false;
    final granted = await _notificationService.requestPermissions();
    _notificationsPermissionGranted = granted;
    await _syncNotifications();
    notifyListeners();
    return granted;
  }

  Future<void> setReminderNotificationsEnabled(bool value) async {
    _reminderSettings = _reminderSettings.copyWith(enabled: value);
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  Future<AiTreatmentSearchResult> searchTreatmentsWithAi(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      throw const AiTreatmentSearchException('Query cannot be empty.');
    }
    final service = _aiTreatmentSearchService;
    if (service == null || !service.isConfigured) {
      throw const AiTreatmentSearchException(
        'AI search is not available in this build.',
      );
    }

    final result = await service.searchTreatments(
      query: normalizedQuery,
      existingCatalog: [
        ...curatedTreatments,
        ...myTreatments,
      ],
    );
    if (result.proposedTreatments.isNotEmpty) {
      await _storeAiDrafts(result.proposedTreatments);
    }
    return result;
  }

  Future<void> _storeAiDrafts(List<WellnessTreatment> drafts) async {
    var changed = false;
    final existingByFingerprint = {
      for (final entry in _aiDraftTreatments)
        _draftFingerprint(entry): entry,
    };
    final merged = List<WellnessTreatment>.from(_aiDraftTreatments);
    for (final draft in drafts) {
      final fingerprint = _draftFingerprint(draft);
      if (existingByFingerprint.containsKey(fingerprint)) {
        continue;
      }
      merged.insert(0, draft);
      existingByFingerprint[fingerprint] = draft;
      changed = true;
    }
    if (!changed) return;
    _aiDraftTreatments = merged;
    await _persist();
    notifyListeners();
  }

  Future<void> removeAiDraft(String treatmentId) async {
    final next =
        _aiDraftTreatments.where((entry) => entry.id != treatmentId).toList();
    if (next.length == _aiDraftTreatments.length) return;
    _aiDraftTreatments = next;
    await _persist();
    notifyListeners();
  }

  Future<void> addDraftToMyTreatments(String treatmentId) async {
    WellnessTreatment? draft;
    for (final entry in _aiDraftTreatments) {
      if (entry.id == treatmentId) {
        draft = entry;
        break;
      }
    }
    if (draft == null) return;
    final resolvedDraft = draft;

    final exists = _userTreatments.any(
      (entry) => _draftFingerprint(entry) == _draftFingerprint(resolvedDraft),
    );
    if (exists) return;

    final converted = resolvedDraft.copyWith(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      origin: TreatmentOrigin.userTreatment,
      originNoteEs:
          'Tratamiento guardado en Mis tratamientos a partir de una busqueda con IA.',
      originNoteEn:
          'Treatment saved in My Treatments from an AI-assisted search.',
    );
    _userTreatments = [converted, ..._userTreatments];
    await _persist();
    notifyListeners();
  }

  String _draftFingerprint(WellnessTreatment treatment) {
    return '${treatment.titleEn.toLowerCase()}|${treatment.categoryEn.toLowerCase()}|${treatment.goalEn.toLowerCase()}';
  }

  Future<void> logTrainingSession({
    required TrainingType type,
    required DateTime performedAt,
    String? exampleKey,
  }) async {
    _recentTraining[type] = RecentTrainingSession(
      type: type,
      performedAtIso: performedAt.toIso8601String(),
      exampleKey: exampleKey,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> removeTrainingSession(TrainingType type) async {
    _recentTraining.remove(type);
    await _persist();
    notifyListeners();
  }

  Future<void> clearTrainingSessions() async {
    _recentTraining.clear();
    await _persist();
    notifyListeners();
  }

  List<TrainingCompatibilityAssessment> compatibilityForTreatment({
    required WellnessTreatment treatment,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final recent = recentTrainingSessions
        .where((entry) => now.difference(entry.performedAt).inHours <= 72)
        .toList(growable: false);
    return assessTrainingCompatibility(
      guidance: treatment.trainingGuidance,
      recentTraining: recent,
      referenceTime: now,
    );
  }

  Future<void> addReminderPreference({
    required ReminderLeadTime leadTime,
    required int hour,
    required int minute,
  }) async {
    final reminders = List<ReminderPreference>.from(_reminderSettings.reminders)
      ..add(
        ReminderPreference(
          id: 'reminder_${DateTime.now().microsecondsSinceEpoch}',
          leadTime: leadTime,
          hour: hour,
          minute: minute,
        ),
      );
    _reminderSettings = _reminderSettings.copyWith(reminders: reminders);
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> updateReminderPreference(ReminderPreference updated) async {
    final reminders = _reminderSettings.reminders
        .map((entry) => entry.id == updated.id ? updated : entry)
        .toList();
    _reminderSettings = _reminderSettings.copyWith(reminders: reminders);
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> removeReminderPreference(String id) async {
    final reminders =
        _reminderSettings.reminders.where((entry) => entry.id != id).toList();
    _reminderSettings = _reminderSettings.copyWith(reminders: reminders);
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> scheduleTreatment({
    required WellnessTreatment treatment,
    required DateTime date,
    String momentLabel = 'Planned',
    TrainingRelation trainingRelation = TrainingRelation.independent,
  }) async {
    final key = dateKeyFor(date);
    final existing = List<PlannedSession>.from(_plans[key] ?? const []);
    if (!existing.any((entry) => entry.treatmentId == treatment.id)) {
      existing.add(
        PlannedSession(
          id: _buildSessionId(
            treatmentId: treatment.id,
            dateKey: key,
            suffix: momentLabel,
          ),
          treatmentId: treatment.id,
          dateKey: key,
          momentLabel: momentLabel,
          trainingRelation: trainingRelation,
        ),
      );
      existing.sort((a, b) => a.momentLabel.compareTo(b.momentLabel));
      _plans[key] = existing;
      await _persist();
      await _syncNotifications();
      notifyListeners();
    }
  }

  Future<int> scheduleTreatmentSeries({
    required WellnessTreatment treatment,
    required List<DateTime> dates,
    String momentLabel = 'Scheduled',
    TrainingRelation trainingRelation = TrainingRelation.independent,
  }) async {
    final normalizedDates = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort();
    if (normalizedDates.isEmpty) return 0;

    final createCourseGroup =
        normalizedDates.length > 1 || treatment.courseGuidance != null;
    final courseId = createCourseGroup ? _buildCourseId(treatment.id) : null;
    final totalSessions = normalizedDates.length;
    var added = 0;
    for (final date in normalizedDates) {
      final key = dateKeyFor(date);
      final existing = List<PlannedSession>.from(_plans[key] ?? const []);
      final alreadyPlanned =
          existing.any((entry) => entry.treatmentId == treatment.id);
      if (!alreadyPlanned) {
        added++;
        existing.add(
          PlannedSession(
            id: _buildSessionId(
              treatmentId: treatment.id,
              dateKey: key,
              suffix: createCourseGroup
                  ? 'course_${courseId}_$added'
                  : momentLabel,
            ),
            treatmentId: treatment.id,
            dateKey: key,
            momentLabel: momentLabel,
            trainingRelation: trainingRelation,
            courseId: createCourseGroup ? courseId : null,
            courseSessionIndex: createCourseGroup ? added : null,
            courseSessionTarget: createCourseGroup ? totalSessions : null,
          ),
        );
        existing.sort((a, b) => a.momentLabel.compareTo(b.momentLabel));
        _plans[key] = existing;
      }
    }

    if (added > 0) {
      await _persist();
      await _syncNotifications();
      notifyListeners();
    }
    return added;
  }

  Future<int> scheduleTreatmentCourse({
    required WellnessTreatment treatment,
    required DateTime startDate,
    required int totalSessions,
    required int spacingDays,
    String momentLabel = 'Scheduled',
    TrainingRelation trainingRelation = TrainingRelation.independent,
  }) async {
    final normalizedSpacing = spacingDays < 1 ? 1 : spacingDays;
    final dates = List<DateTime>.generate(
      totalSessions,
      (index) => DateTime(
        startDate.year,
        startDate.month,
        startDate.day + (normalizedSpacing * index),
      ),
    );
    return scheduleTreatmentSeries(
      treatment: treatment,
      dates: dates,
      momentLabel: momentLabel,
      trainingRelation: trainingRelation,
    );
  }

  Future<void> unscheduleTreatment({
    required DateTime date,
    String? treatmentId,
    String? sessionId,
  }) async {
    final key = dateKeyFor(date);
    final existing = List<PlannedSession>.from(_plans[key] ?? const []);
    existing.removeWhere((entry) {
      if (sessionId != null && sessionId.isNotEmpty) {
        return entry.id == sessionId;
      }
      return treatmentId != null && entry.treatmentId == treatmentId;
    });
    if (existing.isEmpty) {
      _plans.remove(key);
    } else {
      _plans[key] = existing;
    }
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> markStatus({
    required DateTime date,
    required WellnessTreatment treatment,
    required SessionStatus status,
    PlannedSession? session,
    String momentLabel = 'Tracked',
    TrainingRelation trainingRelation = TrainingRelation.independent,
  }) async {
    final key = dateKeyFor(date);
    final existing = List<PlannedSession>.from(_plans[key] ?? const []);
    final matched = session != null
        ? existing
            .where((entry) => entry.id == session.id)
            .toList(growable: false)
        : existing
            .where((entry) => entry.treatmentId == treatment.id)
            .toList(growable: false);
    existing.removeWhere(
      (entry) => session != null
          ? entry.id == session.id
          : entry.treatmentId == treatment.id,
    );
    if (existing.isEmpty) {
      _plans.remove(key);
    } else {
      _plans[key] = existing;
    }
    _history.add(
      SessionHistoryEntry(
        id: '${treatment.id}_${DateTime.now().microsecondsSinceEpoch}',
        treatmentId: treatment.id,
        loggedAtIso: DateTime.now().toIso8601String(),
        dateKey: key,
        status: status,
        momentLabel: matched.isNotEmpty ? matched.first.momentLabel : momentLabel,
        plannedSessionId: matched.isNotEmpty ? matched.first.id : session?.id,
        trainingRelation: matched.isNotEmpty
            ? matched.first.trainingRelation
            : trainingRelation,
        courseId: matched.isNotEmpty ? matched.first.courseId : session?.courseId,
        courseSessionIndex: matched.isNotEmpty
            ? matched.first.courseSessionIndex
            : session?.courseSessionIndex,
        courseSessionTarget: matched.isNotEmpty
            ? matched.first.courseSessionTarget
            : session?.courseSessionTarget,
      ),
    );
    _history.sort((a, b) => b.loggedAtIso.compareTo(a.loggedAtIso));
    await _persist();
    await _syncNotifications();
    notifyListeners();
  }

  String exportHistoryAsCsv() {
    final buffer = StringBuffer(
      'date,status,treatment_id,treatment_title,moment,training_relation,course_id,course_session_index,course_session_target,logged_at\n',
    );
    for (final entry in _history) {
      final treatment = treatmentById(entry.treatmentId);
      buffer.writeln(
        [
          entry.dateKey,
          entry.status.name,
          entry.treatmentId,
          treatment?.title(_language == AppLanguage.spanish) ??
              BlueprintStrings(_language).unknownTreatmentLabel(),
          entry.momentLabel,
          entry.trainingRelation.name,
          entry.courseId ?? '',
          entry.courseSessionIndex ?? '',
          entry.courseSessionTarget ?? '',
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
        'treatmentTitle': treatment?.title(_language == AppLanguage.spanish) ??
            BlueprintStrings(_language).unknownTreatmentLabel(),
        'trainingRelationLabel': entry.trainingRelation.name,
        'courseSessionIndex': entry.courseSessionIndex,
        'courseSessionTarget': entry.courseSessionTarget,
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
      _prefsReminderSettings,
      json.encode(_reminderSettings.toJson()),
    );
    await prefs.setString(_prefsLanguage, _language.name);
    await prefs.setString(
      _prefsRecentTraining,
      json.encode(
        _recentTraining.values.map((entry) => entry.toJson()).toList(),
      ),
    );
    await prefs.setString(
      _prefsAiDraftTreatments,
      json.encode(_aiDraftTreatments.map((entry) => entry.toJson()).toList()),
    );
    await prefs.setString(
      _prefsUserTreatments,
      json.encode(_userTreatments.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> _syncNotifications() async {
    if (!_ready || !_notificationsSupported) return;
    if (!_notificationsPermissionGranted || !_reminderSettings.enabled) {
      await _notificationService.cancelAll();
      return;
    }
    final plans = <ResolvedPlannedSession>[];
    final sortedKeys = _plans.keys.toList()..sort();
    for (final key in sortedKeys) {
      final date = dateFromKey(key);
      for (final session in _plans[key] ?? const []) {
        final treatment = treatmentById(session.treatmentId);
        if (treatment != null) {
          plans.add(
            ResolvedPlannedSession(
              treatment: treatment,
              session: session,
              date: date,
            ),
          );
        }
      }
    }
    await _notificationService.syncPlannedReminders(
      plans: plans,
      settings: _reminderSettings,
      language: _language,
    );
  }

  String _csvEscape(Object? value) {
    final raw = (value ?? '').toString().replaceAll('"', '""');
    return '"$raw"';
  }

  String _buildSessionId({
    required String treatmentId,
    required String dateKey,
    required String suffix,
  }) {
    final normalizedSuffix = suffix.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    return '${treatmentId}_${dateKey}_${normalizedSuffix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _buildCourseId(String treatmentId) =>
      '${treatmentId}_course_${DateTime.now().microsecondsSinceEpoch}';

  void _seedDemoData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final source = _catalogTreatments.take(6).toList(growable: false);
    if (source.length < 4) return;

    _plans = <String, List<PlannedSession>>{
      dateKeyFor(today): [
        PlannedSession(
          id: 'demo_plan_1',
          treatmentId: source[0].id,
          dateKey: dateKeyFor(today),
          momentLabel: 'Morning',
          trainingRelation: TrainingRelation.afterTraining,
        ),
        PlannedSession(
          id: 'demo_plan_2',
          treatmentId: source[1].id,
          dateKey: dateKeyFor(today),
          momentLabel: 'Evening',
          trainingRelation: TrainingRelation.independent,
        ),
      ],
      dateKeyFor(today.add(const Duration(days: 1))): [
        PlannedSession(
          id: 'demo_plan_3',
          treatmentId: source[2].id,
          dateKey: dateKeyFor(today.add(const Duration(days: 1))),
          momentLabel: 'Lunch break',
          trainingRelation: TrainingRelation.beforeTraining,
        ),
      ],
      dateKeyFor(today.add(const Duration(days: 3))): [
        PlannedSession(
          id: 'demo_plan_4',
          treatmentId: source[3].id,
          dateKey: dateKeyFor(today.add(const Duration(days: 3))),
          momentLabel: 'Afternoon',
          trainingRelation: TrainingRelation.afterTraining,
        ),
      ],
    };

    _history = [
      SessionHistoryEntry(
        id: 'demo_1',
        treatmentId: source[4].id,
        loggedAtIso: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 19))
            .toIso8601String(),
        dateKey: dateKeyFor(today.subtract(const Duration(days: 1))),
        status: SessionStatus.completed,
        momentLabel: 'Evening',
        trainingRelation: TrainingRelation.afterTraining,
      ),
      SessionHistoryEntry(
        id: 'demo_2',
        treatmentId: source[0].id,
        loggedAtIso: today
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 8))
            .toIso8601String(),
        dateKey: dateKeyFor(today.subtract(const Duration(days: 2))),
        status: SessionStatus.completed,
        momentLabel: 'Morning',
        trainingRelation: TrainingRelation.independent,
      ),
      SessionHistoryEntry(
        id: 'demo_3',
        treatmentId: source[5 % source.length].id,
        loggedAtIso: today
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 13))
            .toIso8601String(),
        dateKey: dateKeyFor(today.subtract(const Duration(days: 3))),
        status: SessionStatus.skipped,
        momentLabel: 'Lunch break',
        trainingRelation: TrainingRelation.beforeTraining,
      ),
    ];

    _recentTraining = <TrainingType, RecentTrainingSession>{
      TrainingType.hiit: RecentTrainingSession(
        type: TrainingType.hiit,
        performedAtIso: today
            .subtract(const Duration(hours: 3))
            .add(const Duration(minutes: 15))
            .toIso8601String(),
        exampleKey: 'rower_sprints',
      ),
      TrainingType.upperBodyStrength: RecentTrainingSession(
        type: TrainingType.upperBodyStrength,
        performedAtIso:
            today.subtract(const Duration(hours: 22)).toIso8601String(),
        exampleKey: 'bench_pull',
      ),
      TrainingType.yogaPilates: RecentTrainingSession(
        type: TrainingType.yogaPilates,
        performedAtIso:
            today.subtract(const Duration(days: 2, hours: 2)).toIso8601String(),
        exampleKey: 'mat_pilates',
      ),
    };

    _reminderSettings = const ReminderSettings(
      enabled: true,
      reminders: <ReminderPreference>[
        ReminderPreference(
          id: 'demo_day_before',
          leadTime: ReminderLeadTime.dayBefore,
          hour: 20,
          minute: 30,
        ),
        ReminderPreference(
          id: 'demo_same_day_morning',
          leadTime: ReminderLeadTime.sameDay,
          hour: 8,
          minute: 15,
        ),
        ReminderPreference(
          id: 'demo_same_day_evening',
          leadTime: ReminderLeadTime.sameDay,
          hour: 18,
          minute: 45,
        ),
      ],
    );
  }
}
