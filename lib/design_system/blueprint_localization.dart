import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';

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
  String get howToUseTitle =>
      isSpanish ? 'Como usar Blueprint One' : 'How to use Blueprint One';
  String get howToUseSettingsBody => isSpanish
      ? 'Consulta una guia practica sobre el objetivo de la app, como interpretar los tratamientos, como planificarlos y como leer las referencias y notas de seguridad.'
      : 'Open a practical guide covering the purpose of the app, how to interpret treatments, how to plan them and how to read references and safety notes.';
  String get openHowToUse =>
      isSpanish ? 'Abrir guia de uso' : 'Open user guide';
  String get howToUseIntro => isSpanish
      ? 'Esta seccion resume para que sirve la app, que significa la informacion de cada tratamiento y como convertir una dosis puntual en un plan completo dentro del calendario.'
      : 'This section explains what the app is for, what the information inside each treatment means and how to turn a one-off dose into a complete calendar plan.';
  String get expandForMore =>
      isSpanish ? 'Toca para ampliar' : 'Tap to expand';
  String get quickBasicsTitle =>
      isSpanish ? 'Lo esencial' : 'The essentials';
  String get quickBasicsBody => isSpanish
      ? 'Usa esta guia como apoyo rapido: primero entiende el objetivo del tratamiento, luego decide si quieres una dosis puntual o un plan completo y por ultimo sigue todo desde calendario e historial.'
      : 'Use this guide as a quick reference: first understand the treatment goal, then decide whether you want a single dose or a full plan, and finally follow everything through calendar and history.';
  String get appPurposeTitle =>
      isSpanish ? 'Objeto de la app' : 'What the app is for';
  String get appPurposeBody => isSpanish
      ? 'Blueprint One es una app de acompanamiento para bienestar y fototerapia. Reune protocolos publicados, ayuda a compararlos, planificarlos y registrar su seguimiento.'
      : 'Blueprint One is a wellness and light-therapy companion app. It brings together published protocols, helps you compare them, plan them and track follow-through.';
  String get nonMedicalBoundary => isSpanish
      ? 'No diagnostica, no prescribe y no sustituye la valoracion de un profesional sanitario.'
      : 'It does not diagnose, prescribe or replace assessment from a qualified healthcare professional.';
  String get sourcesDisclosure => isSpanish
      ? 'Las recomendaciones se presentan como orientacion basada en literatura publicada y deben interpretarse con prudencia.'
      : 'Recommendations are presented as guidance based on published literature and should be interpreted cautiously.';
  String get navigationGuideTitle =>
      isSpanish ? 'Que hace cada menu' : 'What each menu does';
  String get menuOverviewHelp => isSpanish
      ? 'Resumen: muestra la actividad de hoy, la siguiente sesion planificada y una vista rapida de tu semana.'
      : 'Overview: shows today’s activity, the next planned session and a quick snapshot of the current week.';
  String get menuContextHelp => isSpanish
      ? 'Contexto: registra si has hecho HIIT, cardio, fuerza o yoga/pilates para que la app evalue la compatibilidad con cada tratamiento.'
      : 'Context: log whether you have done HIIT, cardio, strength work or yoga/pilates so the app can assess treatment compatibility.';
  String get menuTreatmentsHelp => isSpanish
      ? 'Tratamientos: reune el catalogo completo y permite abrir el detalle, revisar evidencia y planificar.'
      : 'Treatments: contains the full catalogue and lets you open the detail view, review evidence and plan sessions.';
  String get menuCalendarHelp => isSpanish
      ? 'Calendario: organiza sesiones futuras, permite verlas por dia y marcarlas como completadas u omitidas.'
      : 'Calendar: organizes future sessions, lets you review them by day and mark them as completed or skipped.';
  String get menuHistoryHelp => isSpanish
      ? 'Historial: conserva lo que ya has realizado u omitido y te deja exportarlo.'
      : 'History: keeps a record of what you completed or skipped and lets you export it.';
  String get menuSettingsHelp => isSpanish
      ? 'Ajustes: cambia idioma, configura recordatorios y consulta esta guia de uso.'
      : 'Settings: change language, configure reminders and open this user guide.';
  String get navigationGuideSummary => isSpanish
      ? 'Resumen rapido de para que sirve cada menu.'
      : 'Quick summary of what each menu is for.';
  String get individualTreatmentTitle => isSpanish
      ? 'Como hacer un tratamiento individual'
      : 'How to do a single treatment';
  String get individualTreatmentBody => isSpanish
      ? 'Si solo quieres una sesion puntual, la app te deja usar el tratamiento como dosis unica y guardarla para hoy o para otro dia.'
      : 'If you only want a one-off session, the app lets you use the treatment as a single dose and save it for today or another day.';
  String get individualTreatmentStep1 => isSpanish
      ? 'Abre Tratamientos y elige el objetivo que quieres revisar.'
      : 'Open Treatments and choose the goal you want to review.';
  String get individualTreatmentStep2 => isSpanish
      ? 'Lee la ficha: objetivo, duracion, distancia, pulso o frecuencia, intensidad sugerida, notas de seguridad y referencias.'
      : 'Read the treatment card: goal, duration, distance, pulse or frequency, suggested intensity, safety notes and references.';
  String get individualTreatmentStep3 => isSpanish
      ? 'Pulsa Planificar tratamiento y deja seleccionada Dosis puntual si solo quieres una sesion.'
      : 'Tap Plan treatment and keep Single dose selected if you only want one session.';
  String get individualTreatmentStep4 => isSpanish
      ? 'Elige el dia de inicio y guarda. Si el contexto deportivo no encaja para hoy, puedes dejarla planificada para una fecha futura.'
      : 'Choose the start date and save. If your training context does not fit today, you can still schedule it for a future date.';
  String get individualTreatmentSummary => isSpanish
      ? 'Pasos para usar un tratamiento como sesion puntual.'
      : 'Steps to use a treatment as a one-off session.';
  String get treatmentReadingTitle => isSpanish
      ? 'Como leer la informacion del tratamiento'
      : 'How to read treatment information';
  String get durationMeaningHelp => isSpanish
      ? 'Duracion: es el tiempo estimado de cada sesion, no del tratamiento completo.'
      : 'Duration: this is the estimated length of each session, not of the full treatment course.';
  String get distanceMeaningHelp => isSpanish
      ? 'Distancia: indica a que separacion aproximada del panel o fuente de luz se ha descrito el protocolo.'
      : 'Distance: this indicates the approximate separation from the light source used in the described protocol.';
  String get pulseMeaningHelp => isSpanish
      ? 'Pulso / frecuencia: resume si el protocolo usa una modalidad concreta, continua o dependiente del estudio.'
      : 'Pulse / frequency: summarizes whether the protocol uses a specific pulsed mode, continuous output or a study-dependent approach.';
  String get intensityMeaningHelp => isSpanish
      ? 'Intensidad sugerida: reparte de forma orientativa el peso entre ondas o canales de luz cuando esa informacion esta disponible.'
      : 'Suggested intensity: gives an indicative distribution across wavelengths or channels when that information is available.';
  String get evidenceMeaningHelp => isSpanish
      ? 'Nivel de evidencia: resume la solidez relativa del respaldo publicado para ese objetivo.'
      : 'Evidence level: summarizes the relative strength of the published support behind that goal.';
  String get sourcesMeaningHelp => isSpanish
      ? 'Referencias cientificas: muestran las fuentes que justifican el protocolo o la familia de protocolos.'
      : 'Source references: show the sources that justify the protocol or protocol family.';
  String get treatmentReadingSummary => isSpanish
      ? 'Que significa duracion, distancia, intensidad, evidencia y fuentes.'
      : 'What duration, distance, intensity, evidence and sources mean.';
  String get planningGuideTitle =>
      isSpanish ? 'Como planificar en la app' : 'How to plan in the app';
  String get planningGuideBody => isSpanish
      ? 'Puedes programar un tratamiento como dosis puntual o como una serie de varias sesiones cuando quieras seguirlo completo.'
      : 'You can schedule a treatment as a one-off dose or as a multi-session series when you want to follow it as a full plan.';
  String get planningSingleDoseHelp => isSpanish
      ? 'Dosis puntual: util para una sesion aislada. Por defecto es la opcion recomendada cuando el tratamiento no trae una pauta clinica estructurada.'
      : 'Single dose: useful for a one-off session. It is the default recommendation when the treatment does not carry a structured clinical course.';
  String get planningCourseHelp => isSpanish
      ? 'Varias sesiones: permite definir un tratamiento completo indicando numero de sesiones y periodicidad.'
      : 'Multiple sessions: lets you define a full treatment course by choosing the number of sessions and the cadence.';
  String get planningStartDateHelp => isSpanish
      ? 'Fecha de inicio: siempre debes seleccionar al menos un dia de comienzo.'
      : 'Start date: you always need to select at least one starting day.';
  String get planningCadenceHelp => isSpanish
      ? 'Periodicidad: puedes elegir diario, dias alternos, semanal o quincenal para que la app genere la serie automaticamente.'
      : 'Cadence: you can choose daily, alternate days, weekly or fortnightly so the app builds the series automatically.';
  String get planningCustomDaysHelp => isSpanish
      ? 'Otros dias: te deja seleccionar varios dias concretos del calendario cuando necesitas una distribucion manual.'
      : 'Custom days: lets you pick multiple explicit calendar days when you need a manual distribution.';
  String get planningCalendarHistoryHelp => isSpanish
      ? 'Una vez guardado, el plan aparece en Calendario. Desde ahi puedes completarlo, omitirlo y ver el progreso en Historial.'
      : 'Once saved, the plan appears in Calendar. From there you can complete it, skip it and review the progress in History.';
  String get planningGuideSummary => isSpanish
      ? 'Como pasar de una dosis puntual a un plan de varias sesiones.'
      : 'How to move from a one-off dose to a multi-session plan.';
  String get trainingCompatibilityGuideTitle => isSpanish
      ? 'Como usar la compatibilidad con entrenamiento'
      : 'How to use training compatibility';
  String get trainingCompatibilityGuideBody => isSpanish
      ? 'Si registras actividad reciente, la app cruza ese contexto con la evidencia disponible para orientar si conviene hacer el tratamiento hoy, antes o despues de entrenar.'
      : 'If you log recent activity, the app cross-checks that context with the available evidence to guide whether the treatment makes sense today, before training or after training.';
  String get trainingCompatibilityGuideStep1 => isSpanish
      ? 'Registra en Contexto el tipo de entrenamiento y una hora aproximada.'
      : 'Log the training type and an approximate time in Context.';
  String get trainingCompatibilityGuideStep2 => isSpanish
      ? 'Revisa en el detalle del tratamiento las notas de compatibilidad y el nivel de prudencia.'
      : 'Review the compatibility notes and caution level inside the treatment detail.';
  String get trainingCompatibilityGuideStep3 => isSpanish
      ? 'Si la app aconseja margen de recuperacion, puedes mover el inicio a otro dia sin perder la planificacion.'
      : 'If the app suggests a recovery gap, you can move the start to another day without losing the plan.';
  String get trainingCompatibilityGuideSummary => isSpanish
      ? 'Como usar el contexto deportivo para decidir el mejor momento.'
      : 'How to use your training context to choose the best timing.';
  String get remindersGuideTitle =>
      isSpanish ? 'Recordatorios y seguimiento' : 'Reminders and follow-up';
  String get remindersGuideBody => isSpanish
      ? 'Los recordatorios se apoyan en lo que tengas planificado en el calendario.'
      : 'Reminders are built from what you have planned in the calendar.';
  String get remindersGuideStep1 => isSpanish
      ? 'En Ajustes puedes elegir avisos el mismo dia o el dia anterior, definir la hora y crear varios recordatorios.'
      : 'In Settings you can choose reminders for the same day or the day before, define the hour and create multiple reminder rules.';
  String get remindersGuideStep2 => isSpanish
      ? 'Cuando marcas una sesion como completada u omitida, el seguimiento queda guardado en Historial y deja de contarse como pendiente.'
      : 'When you mark a session as completed or skipped, the follow-up is saved in History and it stops counting as pending.';
  String get remindersGuideSummary => isSpanish
      ? 'Como recibir avisos y registrar lo que ya has hecho.'
      : 'How to receive reminders and log what you have already done.';
  String get sourcesAndSafetyTitle =>
      isSpanish ? 'Fuentes, seguridad y responsabilidad'
      : 'Sources, safety and responsibility';
  String get sourcesAndSafetyBody1 => isSpanish
      ? 'Usa las notas de seguridad para comprobar si un protocolo requiere prudencia adicional por zona corporal, sensibilidad o contexto personal.'
      : 'Use the safety notes to check whether a protocol requires extra caution because of body area, sensitivity or personal context.';
  String get sourcesAndSafetyBody2 => isSpanish
      ? 'Consulta las referencias cientificas cuando quieras entender de donde sale un tratamiento o por que la evidencia es mas o menos solida.'
      : 'Review the source references whenever you want to understand where a treatment comes from or why the evidence is stronger or weaker.';
  String get sourcesAndSafetyBody3 => isSpanish
      ? 'Si tienes una lesion importante, dolor persistente o una situacion clinica compleja, usa la app como orientacion general y busca valoracion profesional.'
      : 'If you have a significant injury, persistent pain or a complex clinical situation, use the app as general guidance and seek professional assessment.';
  String get sourcesAndSafetySummary => isSpanish
      ? 'Como interpretar la evidencia y el descargo de responsabilidad.'
      : 'How to interpret the evidence and the disclaimer.';

  String get navOverview => isSpanish ? 'Resumen' : 'Overview';
  String get navContext => isSpanish ? 'Contexto' : 'Context';
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
  String get trainingContextTitle =>
      isSpanish ? 'Contexto de entrenamiento' : 'Training context';
  String get trainingContextBody => isSpanish
      ? 'Registra que tipos de entrenamiento has hecho recientemente para que la app pueda orientar si un tratamiento es razonable ahora, antes de entrenar o despues.'
      : 'Log which training types you have done recently so the app can guide whether a treatment is reasonable now, before training or after training.';
  String get recentTrainingLogged => isSpanish
      ? 'Entrenamiento reciente registrado'
      : 'Recent training logged';
  String get noTrainingLogged => isSpanish
      ? 'No hay entrenamiento reciente registrado. La app asumira que no has entrenado recientemente.'
      : 'No recent training is logged. The app will assume you have not trained recently.';
  String get clearTrainingContext =>
      isSpanish ? 'Borrar contexto' : 'Clear context';
  String get removeTrainingLog =>
      isSpanish ? 'Eliminar registro' : 'Remove log';
  String get logNow => isSpanish ? 'Registrar ahora' : 'Log now';
  String get chooseDateAndTime =>
      isSpanish ? 'Elegir fecha y hora' : 'Choose date and time';
  String get selectTrainingExample => isSpanish
      ? 'Selecciona un ejemplo de sesion'
      : 'Select a session example';
  String get chooseTime => isSpanish ? 'Elegir hora' : 'Choose time';
  String get compatibilityTitle => isSpanish
      ? 'Compatibilidad con entrenamiento'
      : 'Training compatibility';
  String get compatibilityBody => isSpanish
      ? 'La app cruza tu contexto reciente de entrenamiento con la evidencia disponible para orientar si conviene usar este tratamiento ahora, antes de entrenar o despues.'
      : 'The app cross-checks your recent training context with the available evidence to guide whether this treatment makes sense now, before training or after training.';
  String get noRecentTrainingCompatibility => isSpanish
      ? 'No hay entrenamientos recientes registrados, asi que este tratamiento se considera independiente de entrenamiento por defecto.'
      : 'No recent training is logged, so this treatment is treated as training-independent by default.';
  String get planRelationTitle => isSpanish
      ? 'Relacion con el entrenamiento'
      : 'Relation to training';
  String get choosePlanRelation => isSpanish
      ? 'Elige si lo quieres dejar como plan independiente, antes de entrenar o despues.'
      : 'Choose whether to keep it as an independent plan, before training or after training.';
  String get genericEvidenceNote => isSpanish
      ? 'La literatura deportiva en PBM es heterogenea. Estas notas deben leerse como orientacion prudente, no como garantia de efecto.'
      : 'The sports PBM literature is heterogeneous. Treat these notes as cautious guidance, not as a guarantee of effect.';
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
  String get fullCourseTitle =>
      isSpanish ? 'Tratamiento completo' : 'Full treatment plan';
  String get fullCourseBody => isSpanish
      ? 'Algunas dolencias responden mejor cuando se mantiene una serie de sesiones a lo largo de varias semanas. Si quieres, puedes planificar el ciclo completo en lugar de una sola dosis puntual.'
      : 'Some conditions respond better when sessions are sustained across several weeks. If you want, you can plan the full cycle instead of a one-off dose.';
  String get courseWindow =>
      isSpanish ? 'Ventana sugerida' : 'Suggested range';
  String get courseCadence =>
      isSpanish ? 'Cadencia sugerida' : 'Suggested cadence';
  String get planFullCourse =>
      isSpanish ? 'Planificar tratamiento completo' : 'Plan full treatment plan';
  String get planTreatment =>
      isSpanish ? 'Planificar tratamiento' : 'Plan treatment';
  String get courseStartDate =>
      isSpanish ? 'Fecha de inicio' : 'Start date';
  String get courseTotalSessions =>
      isSpanish ? 'Numero de sesiones' : 'Number of sessions';
  String get courseSpacing =>
      isSpanish ? 'Separacion entre sesiones' : 'Session spacing';
  String get planShape =>
      isSpanish ? 'Tipo de plan' : 'Plan type';
  String get singleDose =>
      isSpanish ? 'Dosis puntual' : 'Single dose';
  String get repeatedPlan =>
      isSpanish ? 'Varias sesiones' : 'Multiple sessions';
  String get planningCadence =>
      isSpanish ? 'Periodicidad' : 'Cadence';
  String get dailyCadence =>
      isSpanish ? 'Diario' : 'Daily';
  String get alternateCadence =>
      isSpanish ? 'Dias alternos' : 'Alternate days';
  String get weeklyCadence =>
      isSpanish ? 'Semanal' : 'Weekly';
  String get fortnightlyCadence =>
      isSpanish ? 'Quincenal' : 'Fortnightly';
  String get customCadence =>
      isSpanish ? 'Otros dias' : 'Custom days';
  String get selectedDays =>
      isSpanish ? 'Dias seleccionados' : 'Selected days';
  String get addCalendarDay =>
      isSpanish ? 'Anadir dia' : 'Add day';
  String get startDateRequired =>
      isSpanish ? 'Debes seleccionar al menos un dia de inicio.'
      : 'You need to select at least one start day.';
  String get addAtLeastOneExtraDay =>
      isSpanish
          ? 'Si eliges varias sesiones con dias personalizados, anade al menos un dia adicional.'
          : 'If you choose multiple sessions with custom days, add at least one additional day.';
  String get planSaved =>
      isSpanish ? 'Tratamiento planificado' : 'Treatment planned';
  String get compatibilityForSelectedDay =>
      isSpanish ? 'Compatibilidad para el dia elegido'
      : 'Compatibility for the selected day';
  String get suitableForSelectedDay =>
      isSpanish ? 'Compatible para ese dia'
      : 'Suitable for that day';
  String get cautionForSelectedDay =>
      isSpanish ? 'Conviene dejar un margen antes de usarlo ese dia'
      : 'A short gap is advisable before using it on that day';
  String get youCanStillPlanFuture =>
      isSpanish ? 'Aun asi puedes planificar el inicio en otra fecha.'
      : 'You can still plan the start on a different date.';
  String get coursePlanTitle =>
      isSpanish ? 'Configurar tratamiento completo' : 'Configure full treatment plan';
  String courseRangeLabel(int min, int max) => isSpanish
      ? '$min-$max sesiones'
      : '$min-$max sessions';
  String everyXDays(int days) => isSpanish
      ? (days == 1 ? 'Cada dia' : 'Cada $days dias')
      : (days == 1 ? 'Every day' : 'Every $days days');
  String coursePlannedResult(int planned, int requested) => isSpanish
      ? 'Se han planificado $planned de $requested sesiones.'
      : '$planned of $requested sessions have been planned.';
  String courseProgressLine(int completed, int skipped, int target) => isSpanish
      ? '$completed completadas, $skipped omitidas, objetivo $target'
      : '$completed completed, $skipped skipped, target $target';
  String courseSessionLabel(int index, int total) => isSpanish
      ? 'Sesion $index de $total'
      : 'Session $index of $total';
  String get activeCourse =>
      isSpanish ? 'Curso activo' : 'Active course';
  String get nextCourseSession =>
      isSpanish ? 'Proxima sesion del curso' : 'Next course session';
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
  String get trainingRelationPrefix =>
      isSpanish ? 'Relacion' : 'Relation';
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

  String trainingTypeLabel(TrainingType type) {
    switch (type) {
      case TrainingType.hiit:
        return 'HIIT';
      case TrainingType.yogaPilates:
        return isSpanish ? 'Yoga / Pilates' : 'Yoga / Pilates';
      case TrainingType.upperBodyStrength:
        return isSpanish ? 'Fuerza tren superior' : 'Upper-body strength';
      case TrainingType.lowerBodyStrength:
        return isSpanish ? 'Fuerza tren inferior' : 'Lower-body strength';
      case TrainingType.cardio:
        return isSpanish ? 'Cardio' : 'Cardio';
    }
  }

  String trainingTypeBody(TrainingType type) {
    switch (type) {
      case TrainingType.hiit:
        return isSpanish
            ? 'Entrenamientos cortos y muy exigentes, con acumulacion rapida de fatiga, lactato y carga sistemica.'
            : 'Short, very demanding sessions with rapid fatigue, lactate build-up and systemic load.';
      case TrainingType.yogaPilates:
        return isSpanish
            ? 'Trabajo de movilidad, control motor, respiracion y carga mecanica habitualmente mas baja.'
            : 'Mobility, motor-control and breathing work, usually with lower mechanical load.';
      case TrainingType.upperBodyStrength:
        return isSpanish
            ? 'Sesiones con presses, remos, dominadas o trabajo accesorio de hombro, espalda y brazos.'
            : 'Sessions with presses, rows, pull-ups or accessory work for shoulders, back and arms.';
      case TrainingType.lowerBodyStrength:
        return isSpanish
            ? 'Sesiones con sentadillas, peso muerto, zancadas o trabajo dominante de cadera y rodilla.'
            : 'Sessions with squats, deadlifts, lunges or hip- and knee-dominant strength work.';
      case TrainingType.cardio:
        return isSpanish
            ? 'Trabajo continuo o por intervalos centrado en carrera, bici, remo o esfuerzos aerobicos prolongados.'
            : 'Continuous or interval-based running, cycling, rowing or longer aerobic efforts.';
    }
  }

  List<(String, String)> trainingExamples(TrainingType type) {
    switch (type) {
      case TrainingType.hiit:
        return [
          (
            'assault_bike',
            isSpanish ? 'Assault bike por intervalos' : 'Assault bike intervals'
          ),
          (
            'rower_sprints',
            isSpanish ? 'Sprints en remo' : 'Rowing sprints'
          ),
          (
            'track_intervals',
            isSpanish ? 'Series en pista' : 'Track intervals'
          ),
        ];
      case TrainingType.yogaPilates:
        return [
          ('vinyasa', isSpanish ? 'Vinyasa fluido' : 'Vinyasa flow'),
          ('mat_pilates', isSpanish ? 'Pilates de suelo' : 'Mat Pilates'),
          ('mobility_core', isSpanish ? 'Movilidad y core' : 'Mobility and core'),
        ];
      case TrainingType.upperBodyStrength:
        return [
          ('bench_pull', isSpanish ? 'Press banca y remo' : 'Bench press and rows'),
          ('push_pull', isSpanish ? 'Empuje y tiron' : 'Push and pull session'),
          ('shoulder_arms', isSpanish ? 'Hombro y brazos' : 'Shoulders and arms'),
        ];
      case TrainingType.lowerBodyStrength:
        return [
          ('squat_day', isSpanish ? 'Dia de sentadilla' : 'Squat day'),
          ('deadlift_day', isSpanish ? 'Dia de peso muerto' : 'Deadlift day'),
          ('lunge_glute', isSpanish ? 'Zancadas y gluteo' : 'Lunges and glutes'),
        ];
      case TrainingType.cardio:
        return [
          ('easy_run', isSpanish ? 'Rodaje suave' : 'Easy run'),
          ('tempo_run', isSpanish ? 'Carrera tempo' : 'Tempo run'),
          ('bike_endurance', isSpanish ? 'Bici de resistencia' : 'Endurance ride'),
        ];
    }
  }

  String trainingExampleLabel(TrainingType type, String? exampleKey) {
    if (exampleKey == null) {
      return isSpanish ? 'Sin ejemplo concreto' : 'No specific example';
    }
    for (final example in trainingExamples(type)) {
      if (example.$1 == exampleKey) return example.$2;
    }
    return exampleKey;
  }

  String trainingLoggedAt(DateTime date, String exampleLabel) => isSpanish
      ? '$exampleLabel · ${isoDate(date)} ${timeLabel(date)}'
      : '$exampleLabel · ${isoDate(date)} ${timeLabel(date)}';

  String trainingLoggedChip(DateTime date) => isSpanish
      ? 'Registrado ${timeAgo(date)}'
      : 'Logged ${timeAgo(date)}';

  String compatibilityStatusLabel(TrainingCompatibilityStatus status) {
    switch (status) {
      case TrainingCompatibilityStatus.generallyCompatible:
        return isSpanish ? 'Generalmente compatible' : 'Generally compatible';
      case TrainingCompatibilityStatus.compatibleWithCaution:
        return isSpanish
            ? 'Compatible con cautela'
            : 'Compatible with caution';
      case TrainingCompatibilityStatus.limitedEvidence:
        return isSpanish ? 'Evidencia limitada' : 'Limited evidence';
      case TrainingCompatibilityStatus.waitUntilRecovered:
        return isSpanish ? 'Es mejor esperar' : 'Better to wait';
    }
  }

  String compatibilityAssessmentSummary(
    TrainingCompatibilityStatus status, {
    required bool afterTraining,
  }) {
    switch (status) {
      case TrainingCompatibilityStatus.generallyCompatible:
        return afterTraining
            ? (isSpanish
                ? 'Generalmente compatible despues de entrenar'
                : 'Generally compatible after training')
            : (isSpanish
                ? 'Generalmente compatible antes de entrenar'
                : 'Generally compatible before training');
      case TrainingCompatibilityStatus.compatibleWithCaution:
        return afterTraining
            ? (isSpanish
                ? 'Compatible despues de entrenar con cautela practica'
                : 'Compatible after training with practical caution')
            : (isSpanish
                ? 'Compatible antes de entrenar con cautela practica'
                : 'Compatible before training with practical caution');
      case TrainingCompatibilityStatus.limitedEvidence:
        return afterTraining
            ? (isSpanish
                ? 'Posible despues de entrenar, pero con evidencia limitada'
                : 'Possible after training, but evidence is limited')
            : (isSpanish
                ? 'Posible antes de entrenar, pero con evidencia limitada'
                : 'Possible before training, but evidence is limited');
      case TrainingCompatibilityStatus.waitUntilRecovered:
        return isSpanish
            ? 'Es mejor esperar a que pase la fase inmediata post-entreno'
            : 'Wait until the immediate post-training period has settled';
    }
  }

  String trainingRelationLabel(TrainingRelation relation) {
    switch (relation) {
      case TrainingRelation.independent:
        return isSpanish ? 'Independiente' : 'Independent';
      case TrainingRelation.beforeTraining:
        return isSpanish ? 'Antes de entrenar' : 'Before training';
      case TrainingRelation.afterTraining:
        return isSpanish ? 'Despues de entrenar' : 'After training';
    }
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return isSpanish
          ? 'hace ${diff.inMinutes} min'
          : '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return isSpanish ? 'hace ${diff.inHours} h' : '${diff.inHours} h ago';
    }
    return isSpanish ? 'hace ${diff.inDays} dias' : '${diff.inDays} days ago';
  }

  String localizedCompatibilityText(String raw) {
    if (!isSpanish) return raw;
    const waitPrefix =
        'A short recovery gap is advisable first. Approximate wait remaining: ';
    if (raw.startsWith(waitPrefix)) {
      final remainder = raw.substring(waitPrefix.length);
      final splitIndex = remainder.indexOf(' min. ');
      if (splitIndex != -1) {
        final minutes = remainder.substring(0, splitIndex);
        final tail = remainder.substring(splitIndex + 6);
        return 'Conviene dejar primero una pequena ventana de recuperacion. Espera aproximada restante: $minutes min. ${localizedCompatibilityText(tail)}';
      }
    }
    return _compatibilityTranslations[raw] ?? raw;
  }

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

  static const Map<String, String> _compatibilityTranslations = {
    'High-intensity pre-exercise PBM has mixed evidence. Some localized studies suggest less fatigue, but others show no clear ergogenic effect. Use only as an optional adjunct, not as a performance requirement.':
        'La PBM antes de un esfuerzo de alta intensidad tiene evidencia mixta. Algunos estudios localizados sugieren menos fatiga, pero otros no muestran un efecto ergogenico claro. Debe verse como un apoyo opcional, no como un requisito de rendimiento.',
    'After HIIT, localized PBM is generally compatible for recovery-oriented use once the initial cool-down has finished. Evidence supports possible fatigue/oxidative-stress modulation, but benefits are inconsistent across trials.':
        'Despues de HIIT, la PBM localizada suele ser compatible para un uso orientado a la recuperacion una vez completado el enfriamiento inicial. La evidencia sugiere una posible modulacion de fatiga y estres oxidativo, pero los beneficios no son consistentes entre ensayos.',
    'No exercise-specific incompatibility was identified before HIIT for this treatment family.':
        'No se identifico una incompatibilidad especifica con HIIT antes de este tipo de tratamiento.',
    'Generally compatible after HIIT, but practical comfort is better once skin temperature, sweat and breathing have normalized. Exercise-specific evidence for this treatment family is limited.':
        'Generalmente compatible despues de HIIT, aunque la comodidad practica mejora cuando la temperatura cutanea, el sudor y la respiracion ya se han normalizado. La evidencia especifica para este tipo de tratamiento es limitada.',
    'Whole-body or systemic PBM has not shown consistent performance benefits before intense conditioning work.':
        'La PBM sistemica o de cuerpo completo no ha mostrado beneficios consistentes de rendimiento antes de trabajo de acondicionamiento intenso.',
    'Compatible after HIIT for general wellness goals. Existing exercise studies do not show a clear incompatibility, but systemic benefits are less established than localized recovery use.':
        'Compatible despues de HIIT para objetivos generales de bienestar. Los estudios de ejercicio no muestran una incompatibilidad clara, pero los beneficios sistemicos estan menos establecidos que el uso localizado para recuperacion.',
    'Localized PBM before cardio has mixed evidence. Some endurance trials are neutral, so this should be considered optional rather than necessary.':
        'La PBM localizada antes de cardio tiene evidencia mixta. Algunos ensayos de resistencia son neutros, asi que debe considerarse opcional y no necesaria.',
    'Compatible after cardio for recovery-oriented treatments, especially when soreness or accumulated load is the target. Evidence is mixed and should not be framed as guaranteed performance enhancement.':
        'Compatible despues de cardio para tratamientos orientados a recuperacion, sobre todo si el objetivo es la molestia o la carga acumulada. La evidencia es mixta y no debe presentarse como una mejora garantizada del rendimiento.',
    'No direct incompatibility with cardio was identified for this treatment family.':
        'No se identifico una incompatibilidad directa con cardio para este tipo de tratamiento.',
    'Generally compatible after cardio once the user has cooled down and the skin is comfortable. Evidence is limited because most sports PBM studies focus on muscle outcomes.':
        'Generalmente compatible despues de cardio una vez que la persona se ha enfriado y la piel esta confortable. La evidencia es limitada porque la mayoria de estudios deportivos de PBM se centran en resultados musculares.',
    'Systemic PBM before cardio is not clearly supported for performance. Some endurance trials show no benefit.':
        'La PBM sistemica antes de cardio no esta claramente respaldada para rendimiento. Algunos ensayos de resistencia no muestran beneficio.',
    'Compatible after cardio for general wellness purposes, but evidence for systemic performance or recovery gains remains limited.':
        'Compatible despues de cardio con objetivos generales de bienestar, pero la evidencia para mejoras sistemicas de rendimiento o recuperacion sigue siendo limitada.',
    'This is the most studied combination. Some upper-body resistance trials report less fatigue when PBM is used before exercise, but results are not uniform across studies.':
        'Esta es la combinacion mas estudiada. Algunos ensayos de fuerza de tren superior describen menos fatiga cuando la PBM se usa antes del ejercicio, pero los resultados no son uniformes entre estudios.',
    'Compatible after upper-body strength work for recovery-oriented use on the trained area. Evidence suggests possible help with fatigue and oxidative-stress recovery, but not a guaranteed effect on strength or adaptation.':
        'Compatible despues de trabajo de fuerza de tren superior para un uso orientado a recuperacion sobre la zona entrenada. La evidencia sugiere una posible ayuda sobre fatiga y recuperacion del estres oxidativo, pero no un efecto garantizado sobre fuerza o adaptacion.',
    'No direct incompatibility was identified when the treatment target does not match the primary trained area.':
        'No se identifico una incompatibilidad directa cuando la zona tratada no coincide con el area principal entrenada.',
    'Generally compatible after upper-body strength work. Relevance is lower when the treated area was not the main driver of the session.':
        'Generalmente compatible despues de fuerza de tren superior. La relevancia es menor cuando la zona tratada no fue el principal foco de la sesion.',
    'No exercise-specific incompatibility was found before upper-body strength work for this treatment family.':
        'No se encontro una incompatibilidad especifica con trabajo de fuerza de tren superior antes de este tipo de tratamiento.',
    'Generally compatible after training, with a practical preference for waiting until sweat and skin heat settle.':
        'Generalmente compatible despues del entrenamiento, con una preferencia practica por esperar a que el sudor y el calor cutaneo se normalicen.',
    'Systemic use before strength sessions has less direct support than localized use on the working muscles.':
        'El uso sistemico antes de sesiones de fuerza tiene menos apoyo directo que el uso localizado sobre la musculatura que va a trabajar.',
    'Compatible after strength training for general wellness goals, but additional benefits over training alone are not consistently demonstrated in trained populations.':
        'Compatible despues de entrenamiento de fuerza para objetivos generales de bienestar, pero los beneficios adicionales sobre entrenar solo no se demuestran de forma consistente en poblaciones ya entrenadas.',
    'Lower-limb PBM before strength work is sometimes studied as a fatigue-management strategy, but results are mixed and should be treated as optional.':
        'La PBM en miembros inferiores antes de fuerza se estudia a veces como estrategia de manejo de la fatiga, pero los resultados son mixtos y debe tratarse como algo opcional.',
    'Compatible after lower-body strength work for soreness and load-management purposes. Evidence is mixed but generally supportive of recovery-focused use rather than performance claims.':
        'Compatible despues de trabajo de fuerza de tren inferior para fines de control de molestia y carga. La evidencia es mixta, aunque en general apoya mas un uso centrado en recuperacion que en rendimiento.',
    'No direct incompatibility was identified when the treated area is not the primary lower-body training target.':
        'No se identifico una incompatibilidad directa cuando la zona tratada no es el principal objetivo del entrenamiento de tren inferior.',
    'Generally compatible after lower-body strength work. Consider local soreness and fatigue only when the treatment overlaps the worked tissues.':
        'Generalmente compatible despues de fuerza de tren inferior. Ten en cuenta la molestia y la fatiga local solo cuando el tratamiento coincide con los tejidos trabajados.',
    'No exercise-specific incompatibility was found before lower-body strength work for this treatment family.':
        'No se encontro una incompatibilidad especifica con trabajo de fuerza de tren inferior antes de este tipo de tratamiento.',
    'Generally compatible after training, with a practical preference for waiting until local heat, sweat and friction have settled.':
        'Generalmente compatible despues del entrenamiento, con una preferencia practica por esperar a que el calor local, el sudor y la friccion se normalicen.',
    'Systemic PBM before lower-body lifting has limited direct support compared with localized muscle-focused use.':
        'La PBM sistemica antes de levantar con tren inferior tiene un apoyo directo limitado frente al uso localizado sobre la musculatura objetivo.',
    'Compatible after strength work for general wellness goals, but evidence for extra training adaptation benefits is inconsistent.':
        'Compatible despues del trabajo de fuerza para objetivos generales de bienestar, pero la evidencia sobre beneficios extra en adaptacion al entrenamiento es inconsistente.',
    'Generally compatible before lower-load mobility work when comfort and symptom goals align with the session.':
        'Generalmente compatible antes de trabajo de movilidad de menor carga cuando los objetivos de confort y sintomas encajan con la sesion.',
    'Direct evidence specific to yoga or Pilates timing is scarce. In rehabilitation-style Pilates studies, PBM did not add measurable benefit over Pilates alone, so use this more for symptom management than expected synergy.':
        'La evidencia directa especifica sobre tiempos de yoga o Pilates es escasa. En estudios de Pilates con enfoque rehabilitador, la PBM no mostro un beneficio medible adicional frente a Pilates solo, por lo que conviene usarla mas para manejo de sintomas que esperando una sinergia clara.',
    'No exercise-specific incompatibility was identified for low-load mobility sessions.':
        'No se identifico una incompatibilidad especifica con sesiones de movilidad de baja carga.',
    'Generally compatible after yoga or Pilates. Direct timing evidence is limited, but no meaningful conflict has been demonstrated.':
        'Generalmente compatible despues de yoga o Pilates. La evidencia directa de tiempos es limitada, pero no se ha demostrado un conflicto relevante.',
  };
}
