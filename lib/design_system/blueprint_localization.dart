import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';

enum AppLanguage {
  english,
  spanish,
}

extension AppLanguageX on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.spanish:
        return const Locale('es');
    }
  }

  String get localeTag {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.spanish:
        return 'es';
    }
  }
}

class BlueprintStrings {
  const BlueprintStrings(this.language);

  final AppLanguage language;

  bool get isSpanish => language == AppLanguage.spanish;

  String get appTitle => isSpanish ? 'Blueprint One' : 'Blueprint One';
  String get disclaimer => isSpanish
      ? 'Esta app ofrece orientacion de bienestar basada en literatura publicada y no es un dispositivo medico.'
      : 'This app provides wellness guidance based on published literature and is not a medical device.';

  String get languageTitle => isSpanish ? 'Idioma' : 'Language';
  String get languageSubtitle => isSpanish
      ? 'Elige si quieres ver la interfaz en castellano o en ingles.'
      : 'Choose whether you want the interface in Spanish or English.';
  String get englishLabel => isSpanish ? 'Ingles' : 'English';
  String get spanishLabel => isSpanish ? 'Castellano' : 'Spanish';

  String get navOverview => isSpanish ? 'Resumen' : 'Overview';
  String get navTreatments => isSpanish ? 'Tratamientos' : 'Treatments';
  String get navCalendar => isSpanish ? 'Calendario' : 'Calendar';
  String get navHistory => isSpanish ? 'Historial' : 'History';
  String get navSettings => isSpanish ? 'Ajustes' : 'Settings';

  String get heroTitle => isSpanish
      ? 'Una forma mas clara de seguir tus planes de fototerapia'
      : 'A clearer way to follow light therapy plans';
  String get heroBody => isSpanish
      ? 'Consulta tratamientos basados en evidencia, planificalos durante la semana y conserva un registro limpio de sesiones completadas u omitidas.'
      : 'Review evidence-based treatments, schedule them through the week and keep a clean record of completed or skipped sessions.';

  String get todayPlanned => isSpanish ? 'Planificado hoy' : 'Today planned';
  String get todayTracked => isSpanish ? 'Registrado hoy' : 'Today tracked';
  String get thisWeekPlanned =>
      isSpanish ? 'Planificado esta semana' : 'This week planned';
  String get remindersActive =>
      isSpanish ? 'Recordatorios activos' : 'Reminders active';
  String get sessionsWaitingInCalendar => isSpanish
      ? 'Sesiones pendientes en tu calendario'
      : 'Sessions waiting in your calendar';
  String get completedOrSkippedEntries => isSpanish
      ? 'Entradas completadas u omitidas'
      : 'Completed or skipped entries';
  String get upcomingSessionsAcrossWeek => isSpanish
      ? 'Proximas sesiones de la semana actual'
      : 'Upcoming sessions across the current week';
  String get notificationScheduleReady =>
      isSpanish ? 'Agenda de avisos preparada' : 'Notification schedule ready';
  String get turnRemindersOnInSettings => isSpanish
      ? 'Activa los recordatorios en ajustes'
      : 'Turn reminders on in settings';
  String get nextPlannedTreatment => isSpanish
      ? 'Siguiente tratamiento planificado'
      : 'Next planned treatment';
  String get nothingPlannedYet => isSpanish
      ? 'Aun no hay nada planificado. Abre el catalogo y anade un tratamiento al calendario.'
      : 'Nothing planned yet. Open the catalogue and add a treatment to your calendar.';
  String get whatYouCanDoHere =>
      isSpanish ? 'Que puedes hacer aqui' : 'What you can do here';
  String get browseTreatments =>
      isSpanish ? 'Explorar tratamientos' : 'Browse treatments';
  String get browseTreatmentsBody => isSpanish
      ? 'Abre el catalogo, compara objetivos, duracion, distancia y la distribucion de intensidad sugerida.'
      : 'Open the catalogue, compare goals, duration, distance and suggested intensity distribution.';
  String get planYourWeek =>
      isSpanish ? 'Planificar tu semana' : 'Plan your week';
  String get planYourWeekBody => isSpanish
      ? 'Asigna tratamientos a dias concretos, revisa la semana de un vistazo y manten los avisos alineados con tu agenda.'
      : 'Assign treatments to specific days, review the week at a glance and keep reminder timing aligned with your schedule.';
  String get trackConsistency =>
      isSpanish ? 'Seguir la constancia' : 'Track consistency';
  String get trackConsistencyBody => isSpanish
      ? 'Marca sesiones como completadas u omitidas y exporta el historial para tus propios registros.'
      : 'Mark sessions as completed or skipped and export the history for your own records.';

  String get treatmentCatalogue =>
      isSpanish ? 'Catalogo de tratamientos' : 'Treatment catalogue';
  String get treatmentCatalogueBody => isSpanish
      ? 'Elige un objetivo, revisa la configuracion recomendada y planificalo en tu semana.'
      : 'Choose a goal, review recommended settings and plan it into your week.';
  String get searchHint => isSpanish
      ? 'Buscar por objetivo, zona o sintoma'
      : 'Search by goal, area or symptom';
  String get allCategory => isSpanish ? 'Todos' : 'All';
  String minutesLabel(int minutes) => '$minutes min';
  String get distancePrefix => isSpanish ? 'Distancia' : 'Distance';
  String get intensityPrefix => isSpanish ? 'Intensidad' : 'Intensity';
  String get noIntensityGuidance =>
      isSpanish ? 'Sin guia de intensidad' : 'No intensity guidance';

  String get configuration => isSpanish ? 'Configuracion' : 'Configuration';
  String get duration => isSpanish ? 'Duracion' : 'Duration';
  String get distance => isSpanish ? 'Distancia' : 'Distance';
  String get pulseMode => isSpanish ? 'Pulso / modo' : 'Pulse / mode';
  String get suggestedIntensity =>
      isSpanish ? 'Intensidad sugerida' : 'Suggested intensity';
  String get evidenceLevel =>
      isSpanish ? 'Nivel de evidencia' : 'Evidence level';
  String get safetyNotes => isSpanish ? 'Notas de seguridad' : 'Safety notes';
  String get beforeSession =>
      isSpanish ? 'Antes de la sesion' : 'Before session';
  String get afterSession =>
      isSpanish ? 'Despues de la sesion' : 'After session';
  String get sourceReferences =>
      isSpanish ? 'Referencias cientificas' : 'Source references';
  String get planForToday =>
      isSpanish ? 'Planificar para hoy' : 'Plan for today';
  String get chooseDate => isSpanish ? 'Elegir fecha' : 'Choose a date';
  String get todayMomentLabel => isSpanish ? 'Hoy' : 'Today';
  String get scheduledMomentLabel => isSpanish ? 'Planificado' : 'Scheduled';
  String plannedFor(DateTime date) => isSpanish
      ? 'Planificado para ${shortDate(date)}'
      : 'Planned for ${shortDate(date)}';
  String scheduledFor(DateTime date) => isSpanish
      ? 'Programado para ${shortDate(date)}'
      : 'Scheduled for ${shortDate(date)}';

  String get weeklySchedule => isSpanish ? 'Plan semanal' : 'Weekly schedule';
  String get weeklyScheduleBody => isSpanish
      ? 'Planifica tratamientos durante la semana, revisa los proximos avisos y registra cada sesion al completarla u omitirla.'
      : 'Plan treatments through the week, review upcoming reminders and track each session once it is completed or skipped.';
  String monthYear(DateTime date) => '${monthName(date.month)} ${date.year}';
  String remindersCount(int count) =>
      isSpanish ? '$count recordatorios' : '$count reminders';
  String get remindersOff =>
      isSpanish ? 'Recordatorios apagados' : 'Reminders off';
  String get reminderSnapshot =>
      isSpanish ? 'Resumen de recordatorios' : 'Reminder snapshot';
  String get noFutureTreatment => isSpanish
      ? 'Todavia no hay un tratamiento futuro planificado, asi que no hay nada que avisar.'
      : 'No future treatment is planned yet, so there is nothing to notify.';
  String nextTreatmentLine(String title) =>
      isSpanish ? 'Siguiente tratamiento: $title' : 'Next treatment: $title';
  String formattedMomentDate(DateTime date, String label) =>
      '${shortDate(date)} - ${translateMomentLabel(label)}';
  String get scheduledSessions =>
      isSpanish ? 'Sesiones planificadas' : 'Scheduled sessions';
  String get noTreatmentsScheduledForDay => isSpanish
      ? 'No hay tratamientos programados para este dia.'
      : 'No treatments scheduled for this day.';
  String get completed => isSpanish ? 'Completada' : 'Completed';
  String get skipped => isSpanish ? 'Omitida' : 'Skipped';
  String get dayResults => isSpanish ? 'Resultados del dia' : 'Day results';
  String get nothingMarkedYet => isSpanish
      ? 'Todavia no hay nada marcado para este dia.'
      : 'Nothing marked yet for this day.';
  String historyEntryLine(SessionHistoryEntry entry) => isSpanish
      ? '${sessionStatusLabel(entry.status)} - ${translateMomentLabel(entry.momentLabel)} - ${timeLabel(DateTime.parse(entry.loggedAtIso).toLocal())}'
      : '${sessionStatusLabel(entry.status)} - ${translateMomentLabel(entry.momentLabel)} - ${timeLabel(DateTime.parse(entry.loggedAtIso).toLocal())}';

  String get sessionHistory =>
      isSpanish ? 'Historial de sesiones' : 'Session history';
  String get export => isSpanish ? 'Exportar' : 'Export';
  String get copyCsvExport =>
      isSpanish ? 'Copiar exportacion CSV' : 'Copy CSV export';
  String get copyJsonExport =>
      isSpanish ? 'Copiar exportacion JSON' : 'Copy JSON export';
  String historyCopiedAs(String type) => isSpanish
      ? 'Historial copiado como ${type.toUpperCase()}'
      : 'History copied as ${type.toUpperCase()}';
  String get sessionHistoryBody => isSpanish
      ? 'Las sesiones completadas y omitidas se guardan aqui para revisarlas y exportarlas.'
      : 'Completed and skipped sessions stay here for review and export.';
  String get noTrackedSessionsYet => isSpanish
      ? 'Todavia no hay sesiones registradas. Planifica un tratamiento y marcalo como completado u omitido desde el calendario.'
      : 'No tracked sessions yet. Plan a treatment and mark it as completed or skipped from the calendar.';
  String scheduledDay(String value) =>
      isSpanish ? 'Dia programado: $value' : 'Scheduled day: $value';
  String moment(String value) => isSpanish
      ? 'Momento: ${translateMomentLabel(value)}'
      : 'Moment: ${translateMomentLabel(value)}';
  String loggedAt(DateTime date) => isSpanish
      ? 'Registrado: ${isoDate(date)} ${timeLabel(date)}'
      : 'Logged at: ${isoDate(date)} ${timeLabel(date)}';

  String get reminderSettings =>
      isSpanish ? 'Ajustes de recordatorios' : 'Reminder settings';
  String get reminderSettingsBody => isSpanish
      ? 'Elige si los avisos llegan el mismo dia o el dia anterior, selecciona la hora y anade tantos recordatorios como necesites.'
      : 'Choose whether reminders arrive the same day or one day before, select the hour and add as many reminders as you need.';
  String get enableTreatmentReminders => isSpanish
      ? 'Activar recordatorios de tratamientos'
      : 'Enable treatment reminders';
  String get reminderCalendarSource => isSpanish
      ? 'Los recordatorios se programan a partir de tu calendario de tratamientos.'
      : 'Reminders are scheduled from your treatment calendar.';
  String get notificationsNotSupported => isSpanish
      ? 'Las notificaciones no estan disponibles en esta vista previa de plataforma.'
      : 'Notifications are not supported on this platform preview.';
  String get notificationsAllowed =>
      isSpanish ? 'Notificaciones permitidas' : 'Notifications allowed';
  String get permissionNeeded =>
      isSpanish ? 'Permiso necesario' : 'Permission needed';
  String get allowNotifications =>
      isSpanish ? 'Permitir notificaciones' : 'Allow notifications';
  String get activeReminders =>
      isSpanish ? 'Recordatorios activos' : 'Active reminders';
  String get addReminder => isSpanish ? 'Anadir recordatorio' : 'Add reminder';
  String get noActiveRemindersYet => isSpanish
      ? 'Todavia no hay recordatorios activos. Anade uno o varios para mantenerte al dia con los tratamientos planificados.'
      : 'No active reminders yet. Add one or more reminders to stay on track with planned treatments.';
  String reminderDescription(ReminderPreference reminder) =>
      reminder.leadTime == ReminderLeadTime.dayBefore
          ? (isSpanish
              ? 'Se envia el dia anterior a las ${reminder.timeLabel}'
              : 'Sent one day before at ${reminder.timeLabel}')
          : (isSpanish
              ? 'Se envia el mismo dia a las ${reminder.timeLabel}'
              : 'Sent the same day at ${reminder.timeLabel}');
  String get editReminder =>
      isSpanish ? 'Editar recordatorio' : 'Edit reminder';
  String get removeReminder =>
      isSpanish ? 'Eliminar recordatorio' : 'Remove reminder';
  String get reminderBehavior =>
      isSpanish ? 'Comportamiento de los recordatorios' : 'Reminder behavior';
  String get reminderBehaviorBody => isSpanish
      ? 'Los recordatorios se crean a partir de los tratamientos planificados. Las sesiones completadas u omitidas dejan de generar notificaciones futuras para ese dia.'
      : 'Reminders are created from your planned treatments. Completed or skipped sessions stop generating future notifications for that day.';
  String get addReminderDialogTitle =>
      isSpanish ? 'Anadir recordatorio' : 'Add reminder';
  String get editReminderDialogTitle =>
      isSpanish ? 'Editar recordatorio' : 'Edit reminder';
  String get when => isSpanish ? 'Cuando' : 'When';
  String timeButtonLabel(String timeText) =>
      isSpanish ? 'Hora - $timeText' : 'Time - $timeText';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get save => isSpanish ? 'Guardar' : 'Save';

  String sessionStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return completed;
      case SessionStatus.skipped:
        return skipped;
    }
  }

  String reminderLeadTimeLabel(ReminderLeadTime leadTime) {
    switch (leadTime) {
      case ReminderLeadTime.sameDay:
        return isSpanish ? 'Mismo dia' : 'Same day';
      case ReminderLeadTime.dayBefore:
        return isSpanish ? '1 dia antes' : '1 day before';
    }
  }

  String reminderPreferenceSummary(ReminderPreference reminder) =>
      '${reminderLeadTimeLabel(reminder.leadTime)} ${isSpanish ? 'a las' : 'at'} ${reminder.timeLabel}';

  String evidenceLabel(EvidenceLevel level) {
    switch (level) {
      case EvidenceLevel.emerging:
        return isSpanish ? 'Emergente' : 'Emerging';
      case EvidenceLevel.moderate:
        return isSpanish ? 'Moderada' : 'Moderate';
      case EvidenceLevel.strong:
        return isSpanish ? 'Solida' : 'Strong';
    }
  }

  String reminderSummary(int count, bool enabled) {
    if (!enabled || count == 0) return remindersOff;
    if (count == 1) {
      return isSpanish ? '1 recordatorio activo' : '1 reminder active';
    }
    return isSpanish
        ? '$count recordatorios activos'
        : '$count reminders active';
  }

  String translateMomentLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'today':
      case 'hoy':
        return todayMomentLabel;
      case 'scheduled':
      case 'planificado':
        return scheduledMomentLabel;
      case 'tracked':
      case 'registrado':
        return isSpanish ? 'Registrado' : 'Tracked';
      case 'morning':
      case 'manana':
        return isSpanish ? 'Manana' : 'Morning';
      case 'evening':
      case 'tarde':
      case 'noche':
        return isSpanish ? 'Tarde' : 'Evening';
      case 'afternoon':
        return isSpanish ? 'Tarde' : 'Afternoon';
      case 'lunch break':
        return isSpanish ? 'Mediodia' : 'Lunch break';
      default:
        return raw;
    }
  }

  String intensitySummary(WellnessTreatment treatment) {
    if (treatment.intensityDistribution.isEmpty) return noIntensityGuidance;
    return treatment.intensityDistribution
        .map((entry) => '${entry.wavelengthNm}nm ${entry.percentage}%')
        .join(' | ');
  }

  String unknownTreatmentLabel() => isSpanish ? 'Desconocido' : 'Unknown';

  String shortDate(DateTime date) =>
      '${weekdayShort(date.weekday)} ${date.day} ${monthShort(date.month)}';

  String isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String timeLabel(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String weekdayShort(int weekday) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const es = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final values = isSpanish ? es : en;
    return values[(weekday - 1).clamp(0, 6)];
  }

  String monthShort(int month) {
    const en = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const es = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final values = isSpanish ? es : en;
    return values[(month - 1).clamp(0, 11)];
  }

  String monthName(int month) {
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const es = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final values = isSpanish ? es : en;
    return values[(month - 1).clamp(0, 11)];
  }
}
