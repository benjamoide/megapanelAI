// ignore_for_file: non_constant_identifier_names, constant_identifier_names, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'bluetooth/ble_manager.dart';
import 'bluetooth/ble_protocol.dart';
import 'views/bluetooth_custom_view.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ==============================================================================
// 1. CONFIGURACIÓN Y CONSTANTES
// ==============================================================================

const String apiKeyFromBuild =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

const List<String> RUTINAS_POSIBLES = [
  "FULLBODY I",
  "TORSO I",
  "FULLBODY II",
  "TORSO II / CIRCUITO",
  "PREVENTIVO I",
  "PREVENTIVO II",
  "Descanso Total"
];

const List<String> CARDIO_TYPES = [
  "Remo Ergómetro",
  "Cinta Inclinada",
  "Elíptica",
  "Andar",
  "Protocolo Noruego",
  "Descanso Cardio"
];

const Map<String, List<String>> RUTINA_SEMANAL_BASE = {
  "1": ["FULLBODY I"],
  "2": ["TORSO I"],
  "3": ["FULLBODY II"],
  "4": ["TORSO II / CIRCUITO"],
  "5": ["PREVENTIVO I"],
  "6": ["PREVENTIVO II"],
  "7": ["Descanso Total"]
};

const Map<String, String> CARDIO_DEFAULTS = {
  "1": "Remo Ergómetro",
  "3": "Cinta Inclinada",
  "6": "Cinta Inclinada"
};

const List<String> ZONAS_SIMETRICAS = [
  "Codo",
  "Antebrazo",
  "Muñeca",
  "Pierna",
  "Pie",
  "Hombro",
  "Rodilla",
  "Tobillo",
  "Brazo",
  "Mano",
  "Cadera"
];

// ==============================================================================
// 2. MODELOS DE DATOS
// ==============================================================================

class Tratamiento {
  String id;
  String nombre;
  String zona;
  String descripcion;
  String sintomas;
  String posicion;
  String hz;
  String duracion;
  List<Map<String, dynamic>> frecuencias; // Ej: [{'nm': 660, 'p': 100}, ...]
  List<String> tipsAntes;
  List<String> tipsDespues;
  List<String> prohibidos;
  bool esCustom;
  bool oculto;

  Tratamiento(
      {required this.id,
      required this.nombre,
      required this.zona,
      this.descripcion = "",
      this.sintomas = "",
      this.posicion = "",
      this.hz = "",
      this.duracion = "10",
      this.frecuencias = const [],
      this.tipsAntes = const [],
      this.tipsDespues = const [],
      this.prohibidos = const [],
      this.esCustom = false,
      this.oculto = false});

  Tratamiento copyWith({String? id, String? nombre, String? zona}) {
    return Tratamiento(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        zona: zona ?? this.zona,
        descripcion: descripcion,
        sintomas: sintomas,
        posicion: posicion,
        hz: hz,
        duracion: duracion,
        frecuencias: List.from(frecuencias),
        tipsAntes: List.from(tipsAntes),
        tipsDespues: List.from(tipsDespues),
        prohibidos: List.from(prohibidos),
        esCustom: esCustom,
        oculto: oculto);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'zona': zona,
        'descripcion': descripcion,
        'sintomas': sintomas,
        'posicion': posicion,
        'hz': hz,
        'duracion': duracion,
        'frecuencias': frecuencias,
        'tipsAntes': tipsAntes,
        'tipsDespues': tipsDespues,
        'prohibidos': prohibidos,
        'esCustom': esCustom,
        'oculto': oculto
      };

  factory Tratamiento.fromJson(Map<String, dynamic> json) {
    return Tratamiento(
      id: json['id'],
      nombre: json['nombre'],
      zona: json['zona'],
      descripcion: json['descripcion'] ?? "",
      sintomas: json['sintomas'] ?? "",
      posicion: json['posicion'] ?? "",
      hz: json['hz'] ?? "",
      duracion: json['duracion'].toString(),
      frecuencias: List<Map<String, dynamic>>.from(json['frecuencias'] ?? []),
      tipsAntes: List<String>.from(json['tipsAntes'] ?? []),
      tipsDespues: List<String>.from(json['tipsDespues'] ?? []),
      prohibidos: List<String>.from(json['prohibidos'] ?? []),
      esCustom: json['esCustom'] ?? false,
      oculto: json['oculto'] ?? false,
    );
  }
}

class CardioSession {
  String type;
  int duration;
  int steps;
  double resistance;
  double watts;
  double speed;
  double incline;
  String machine;

  CardioSession(
      {required this.type,
      this.duration = 0,
      this.steps = 0,
      this.resistance = 0,
      this.watts = 0,
      this.speed = 0,
      this.incline = 0,
      this.machine = ""});

  Map<String, dynamic> toJson() => {
        'type': type,
        'duration': duration,
        'steps': steps,
        'resistance': resistance,
        'watts': watts,
        'speed': speed,
        'incline': incline,
        'machine': machine
      };

  factory CardioSession.fromJson(Map<String, dynamic> json) {
    return CardioSession(
        type: json['type'] ?? "",
        duration: json['duration'] ?? 0,
        steps: json['steps'] ?? 0,
        resistance: (json['resistance'] ?? 0).toDouble(),
        watts: (json['watts'] ?? 0).toDouble(),
        speed: (json['speed'] ?? 0).toDouble(),
        incline: (json['incline'] ?? 0).toDouble(),
        machine: json['machine'] ?? "");
  }

  String getSummary() {
    if (type == "Descanso Cardio") return "Descanso";
    if (type == "Andar") return "Andar: $steps pasos";

    String details = "";
    if (type == "Protocolo Noruego") {
      details = "Noruego (4x4) - $machine. ";
      if (machine == "Cinta") details += "Vel: $speed, Inc: $incline";
      if (machine == "Elíptica")
        details += "Res: ${resistance.toInt()}, W: ${watts.toInt()}";
      if (machine == "Remo") details += "Res: ${resistance.toInt()}";
    } else if (type == "Elíptica") {
      details = "Elíptica ($duration min). Res: ${resistance.toInt()}";
      if (watts > 0) details += ", ${watts.toInt()}W";
    } else if (type == "Cinta Inclinada") {
      details = "Cinta ($duration min). Vel: $speed, Inc: $incline";
    } else {
      details = "$type ($duration min)";
    }
    return details;
  }
}

class RutinaDiaria {
  List<String> fuerza;
  List<CardioSession> cardioSessions;

  RutinaDiaria({this.fuerza = const [], this.cardioSessions = const []});

  Map<String, dynamic> toJson() => {
        'fuerza': fuerza,
        'cardioSessions': cardioSessions.map((c) => c.toJson()).toList()
      };

  factory RutinaDiaria.fromJson(Map<String, dynamic> json) {
    var sessionsList = json['cardioSessions'] as List?;
    List<CardioSession> sessions = [];

    if (sessionsList != null) {
      sessions = sessionsList.map((e) => CardioSession.fromJson(e)).toList();
    } else {
      if (json['cardioTipo'] != null) {
        sessions.add(CardioSession(
            type: json['cardioTipo'],
            duration: (json['cardioTiempo'] ?? 0).toInt(),
            speed: (json['cardioVel'] ?? 0).toDouble(),
            incline: (json['cardioInc'] ?? 0).toDouble(),
            steps: json['pasos'] ?? 0));
      }
    }

    return RutinaDiaria(
        fuerza: List<String>.from(json['fuerza'] ?? []),
        cardioSessions: sessions);
  }
}

// ==============================================================================
// 3. BASE DE DATOS MAESTRA
// ==============================================================================
final List<Tratamiento> DB_DEFINICIONES = [
  // CODO
  Tratamiento(
      id: "codo_epi",
      nombre: "Epicondilitis (Tenista)",
      zona: "Codo",
      descripcion: "Reduce inflamación en tendón extensor.",
      sintomas: "Dolor cara externa codo al agarrar o girar.",
      posicion: "Brazo en mesa, panel lateral externo.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "10",
      tipsAntes: ["Piel limpia y seca"],
      tipsDespues: ["No pinza con dedos", "Hielo si dolor"]),
  Tratamiento(
      id: "codo_golf",
      nombre: "Epitrocleitis (Golfista)",
      zona: "Codo",
      descripcion: "Regeneración para la cara interna.",
      sintomas: "Dolor interno al flexionar muñeca.",
      posicion: "Brazo mesa, palma arriba, cara interna.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "10",
      tipsDespues: ["Estirar flexores"]),
  Tratamiento(
      id: "codo_calc",
      nombre: "Calcificación",
      zona: "Codo",
      descripcion: "Infrarrojo profundo reabsorción.",
      sintomas: "Dolor punzante y tope óseo.",
      posicion: "Contacto directo con zona dura.",
      frecuencias: [
        {'nm': 660, 'p': 0},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Analgesia)",
      duracion: "12",
      tipsAntes: ["Calor previo"]),
  Tratamiento(
      id: "codo_bur",
      nombre: "Bursitis (Apoyo)",
      zona: "Codo",
      descripcion: "Baja inflamación bursa sin contacto.",
      sintomas: "Hinchazón (bulto) en la punta del codo.",
      posicion: "A 5cm del bulto. NO TOCAR.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "10Hz (Anti-inf)",
      duracion: "10",
      tipsDespues: ["No apoyar codo"]),
  // ESPALDA
  Tratamiento(
      id: "esp_cerv",
      nombre: "Cervicalgia (Cuello)",
      zona: "Espalda",
      descripcion: "Relaja tensión cervical y mejora riego sanguíneo.",
      sintomas: "Rigidez cuello y trapecios.",
      posicion: "Sentado, panel detrás del cuello.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "15",
      tipsAntes: ["Sin collar"],
      tipsDespues: ["Movilidad suave"]),
  Tratamiento(
      id: "esp_dors",
      nombre: "Dorsalgia (Alta)",
      zona: "Espalda",
      descripcion: "Para zona media-alta de la espalda y postura.",
      sintomas: "Dolor entre omóplatos.",
      posicion: "Sentado al revés en silla o tumbado.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "15",
      tipsAntes: ["Postura recta"],
      tipsDespues: ["Estirar pecho"]),
  Tratamiento(
      id: "esp_lumb",
      nombre: "Lumbalgia (Baja)",
      zona: "Espalda",
      descripcion: "Penetración profunda lumbar para desinflamar discos.",
      sintomas: "Dolor en zona baja, dificultad al enderezarse.",
      posicion: "Tumbado boca abajo o sentado en taburete.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "20",
      tipsAntes: ["Calor previo"],
      tipsDespues: ["No cargar peso"]),
  // ANTEBRAZO
  Tratamiento(
      id: "ant_sobre",
      nombre: "Sobrecarga",
      zona: "Antebrazo",
      descripcion: "Relajación muscular general del antebrazo.",
      sintomas: "Sensación de fatiga, antebrazos duros.",
      posicion: "Antebrazo apoyado en mesa. Panel desde arriba.",
      frecuencias: [
        {'nm': 660, 'p': 80},
        {'nm': 850, 'p': 80}
      ],
      hz: "10Hz (Relajación)",
      duracion: "12",
      tipsDespues: ["Estirar"]),
  Tratamiento(
      id: "ant_tend",
      nombre: "Tendinitis",
      zona: "Antebrazo",
      descripcion: "Tratamiento anti-inflamatorio localizado.",
      sintomas: "Dolor puntual en trayecto del tendón.",
      posicion: "Panel apuntando directamente al punto de dolor.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "10",
      tipsDespues: ["Reposo"]),
  // MUÑECA
  Tratamiento(
      id: "mun_tunel",
      nombre: "Túnel Carpiano",
      zona: "Muñeca",
      descripcion: "Enfocado en regeneración nerviosa y desinflamación.",
      sintomas: "Hormigueo en dedos, dolor nocturno.",
      posicion: "Palma arriba. Panel en base de muñeca.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "10Hz (Nervio)",
      duracion: "10",
      tipsAntes: ["Palma abierta"],
      tipsDespues: ["Movilidad"]),
  Tratamiento(
      id: "mun_art",
      nombre: "Articular (General)",
      zona: "Muñeca",
      descripcion: "Para dolor articular general y rigidez.",
      sintomas: "Dolor difuso al mover la muñeca.",
      posicion: "Rotar muñeca frente al panel.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "10",
      tipsDespues: ["Hielo"]),
  // PIERNA
  Tratamiento(
      id: "pierna_itb",
      nombre: "Cintilla Iliotibial",
      zona: "Pierna",
      descripcion: "Reduce fricción e inflamación en fascia lata.",
      sintomas: "Dolor lateral externo rodilla/muslo.",
      posicion: "Tumbado de lado, panel en cara externa muslo.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz (Dolor)",
      duracion: "12",
      tipsDespues: ["Estirar TFL"]),
  Tratamiento(
      id: "pierna_fem",
      nombre: "Sobrecarga Femoral",
      zona: "Pierna",
      descripcion: "Acelera barrido de lactato y recuperación.",
      sintomas: "Fatiga, pesadez muscular isquios.",
      posicion: "Panel cubriendo el grupo muscular afectado.",
      frecuencias: [
        {'nm': 660, 'p': 80},
        {'nm': 850, 'p': 100}
      ],
      hz: "10Hz (Recup)",
      duracion: "15",
      tipsDespues: ["Estirar"]),
  // PIE
  Tratamiento(
      id: "pie_fasc",
      nombre: "Fascitis Plantar",
      zona: "Pie",
      descripcion: "Desinflamación del arco plantar.",
      sintomas: "Dolor agudo en talón al pisar.",
      posicion: "Sentado, panel apuntando a planta del pie.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "50Hz",
      duracion: "10",
      tipsAntes: ["Sin calcetín"],
      tipsDespues: ["Rodar pelota"]),
  Tratamiento(
      id: "pie_esg",
      nombre: "Esguince (Dorsal)",
      zona: "Pie",
      descripcion: "Regeneración de ligamentos tras torcedura.",
      sintomas: "Dolor e hinchazón tobillo/empeine.",
      posicion: "Panel enfocado a zona hinchada.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "10Hz (Regen)",
      duracion: "10"),
  Tratamiento(
      id: "pie_lat",
      nombre: "Lateral (5º Metatarso)",
      zona: "Pie",
      descripcion: "Alivio dolor borde externo.",
      sintomas: "Dolor bajo dedo pequeño, juanete de sastre.",
      posicion: "De lado en suelo apuntando al lateral.",
      frecuencias: [
        {'nm': 660, 'p': 100},
        {'nm': 850, 'p': 100},
        {'nm': 810, 'p': 100},
        {'nm': 830, 'p': 100},
        {'nm': 630, 'p': 100}
      ],
      hz: "50Hz",
      duracion: "12"),
  // HOMBRO
  Tratamiento(
      id: "homb_tend",
      nombre: "Tendinitis",
      zona: "Hombro",
      descripcion: "Para manguito rotador inflamado.",
      sintomas: "Dolor al levantar el brazo lateralmente.",
      posicion: "Sentado, panel lateral apuntando al deltoides.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "40Hz",
      duracion: "10",
      tipsDespues: ["Péndulos"]),
  // RODILLA
  Tratamiento(
      id: "rod_gen",
      nombre: "General/Menisco",
      zona: "Rodilla",
      descripcion: "Mantenimiento articular y meniscos.",
      sintomas: "Molestia profunda o chasquidos.",
      posicion: "Pierna estirada, panel frontal o lateral.",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 100}
      ],
      hz: "10Hz",
      duracion: "10",
      tipsAntes: ["No hielo antes"]),
  // PIEL
  Tratamiento(
      id: "piel_cicat",
      nombre: "Cicatrices",
      zona: "Piel",
      descripcion: "Mejora textura y color de cicatrices.",
      sintomas: "Tejido cicatricial reciente o antiguo.",
      posicion: "Panel directo a la cicatriz.",
      frecuencias: [
        {'nm': 660, 'p': 100},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "10",
      tipsDespues: ["Rosa Mosqueta"]),
  Tratamiento(
      id: "piel_acne",
      nombre: "Acné",
      zona: "Piel",
      descripcion: "Reduce inflamación bacteriana y rojez.",
      sintomas: "Brotes activos, rojez facial.",
      posicion: "Frente al rostro (gafas puestas).",
      frecuencias: [
        {'nm': 660, 'p': 80},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "8"),
  Tratamiento(
      id: "piel_quem",
      nombre: "Quemaduras",
      zona: "Piel",
      descripcion: "Regeneración epidérmica sin calor.",
      sintomas: "Piel roja, sensible o dañada por el sol.",
      posicion: "Mayor distancia (20-30cm).",
      frecuencias: [
        {'nm': 660, 'p': 50},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "5",
      tipsAntes: ["Sin cremas"],
      tipsDespues: ["Aloe Vera"]),
  // ESTETICA
  Tratamiento(
      id: "fat_front",
      nombre: "Grasa Abdomen Frontal",
      zona: "Abdomen",
      descripcion: "Lipólisis térmica máxima.",
      sintomas: "Grasa resistente en zona central.",
      posicion: "Directo piel desnuda.",
      frecuencias: [
        {'nm': 660, 'p': 100},
        {'nm': 850, 'p': 100},
        {'nm': 810, 'p': 100},
        {'nm': 830, 'p': 100},
        {'nm': 630, 'p': 100}
      ],
      hz: "CW",
      duracion: "15",
      prohibidos: ["No hacer de Noche (Activa)"],
      tipsDespues: ["Realizar 30min de Cardio Inmediatamente"]),
  Tratamiento(
      id: "face_rejuv",
      nombre: "Facial Rejuvenecimiento",
      zona: "Cara",
      descripcion: "Estimulación de colágeno superficial.",
      sintomas: "Arrugas finas, piel apagada.",
      posicion: "Frente al rostro 30cm. GAFAS PUESTAS.",
      frecuencias: [
        {'nm': 630, 'p': 100},
        {'nm': 660, 'p': 50}
      ],
      hz: "CW",
      duracion: "10",
      tipsAntes: ["Cara lavada"],
      tipsDespues: ["Serum de Vitamina C"]),
  // SISTEMICO
  Tratamiento(
      id: "testo",
      nombre: "Testosterona",
      zona: "Cuerpo",
      descripcion: "Estimulación mitocondrial hormonal.",
      sintomas: "Optimización hormonal.",
      posicion: "Directo a zona testicular (breve).",
      frecuencias: [
        {'nm': 660, 'p': 100},
        {'nm': 850, 'p': 100}
      ],
      hz: "CW",
      duracion: "5",
      prohibidos: ["No hacer de Noche"],
      tipsDespues: ["Ducha fría"]),
  Tratamiento(
      id: "sueno",
      nombre: "Sueño / Melatonina",
      zona: "Cuerpo",
      descripcion: "Luz ambiente tenue para melatonina.",
      sintomas: "Insomnio, dificultad para desconectar.",
      posicion: "Panel lejos, luz indirecta contra pared.",
      frecuencias: [
        {'nm': 630, 'p': 30},
        {'nm': 660, 'p': 30},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "20",
      prohibidos: ["No hacer por la Mañana"]),
  Tratamiento(
      id: "sis_energ",
      nombre: "Energía Sistémica",
      zona: "Cuerpo",
      descripcion: "Boost mitocondrial.",
      sintomas: "Fatiga general, falta de energía.",
      posicion: "Panel frente al torso/pecho.",
      frecuencias: [
        {'nm': 660, 'p': 100},
        {'nm': 850, 'p': 100}
      ],
      hz: "CW",
      duracion: "10"),
  Tratamiento(
      id: "sis_circ",
      nombre: "Circulación",
      zona: "Cuerpo",
      descripcion: "Vasodilatación general.",
      sintomas: "Piernas cansadas, frío en extremidades.",
      posicion: "Panel cubriendo grandes grupos musculares.",
      frecuencias: [
        {'nm': 660, 'p': 100},
        {'nm': 850, 'p': 100}
      ],
      hz: "CW",
      duracion: "20"),
  // CABEZA
  Tratamiento(
      id: "cab_migr",
      nombre: "Migraña",
      zona: "Cabeza",
      descripcion: "Relajación occipital.",
      sintomas: "Dolor pulsátil, tensión en nuca.",
      posicion: "Panel en la nuca (NO ojos).",
      frecuencias: [
        {'nm': 660, 'p': 0},
        {'nm': 850, 'p': 50}
      ],
      hz: "10Hz (Alfa)",
      duracion: "10",
      tipsAntes: ["Oscuridad"]),
  Tratamiento(
      id: "cab_brain",
      nombre: "Salud Cerebral",
      zona: "Cabeza",
      descripcion: "Neuroprotección y cognitiva.",
      sintomas: "Niebla mental, prevención.",
      posicion: "Panel a la frente/cabeza. GAFAS OBLIGATORIAS.",
      frecuencias: [
        {'nm': 810, 'p': 100}
      ],
      hz: "40Hz (Gamma)",
      duracion: "10",
      tipsAntes: ["Gafas Obligatorias"],
      prohibidos: ["Epilepsia"]),
];

// ==============================================================================
// 4. GESTOR DE ESTADO
// ==============================================================================

class AppState extends ChangeNotifier {
  String currentUser = "";
  bool isGuest = false;
  String _apiKey = apiKeyFromBuild;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  Map<String, List<Map<String, dynamic>>> historial = {};
  Map<String, Map<String, String>> planificados = {};
  Map<String, dynamic> ciclosActivos = {};
  Map<String, RutinaDiaria> rutinasEditadas = {};

  List<Tratamiento> catalogo = [];

  // BLE
  final BleManager _bleManager = BleManager();
  bool isConnected = false;

  bool get hasApiKey => _apiKey.isNotEmpty;

  AppState() {
    catalogo = _generarCatalogoCompleto();
    _initBle();
  }

  void _initBle() {
    _bleManager.init();
    // Subscribe to state changes
    _bleManager.connectionState.listen((state) {
      isConnected = state == BluetoothConnectionState.connected;
      notifyListeners();
    });
    // Check initial state
    isConnected = _bleManager.isConnected;
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await _bleManager.connect(device);
  }

  Future<void> disconnectDevice() async {
    await _bleManager.disconnect();
  }

  void setApiKey(String key) {
    _apiKey = key;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString('gemini_api_key', key));
    notifyListeners();
  }

  // --- LOGIN SEGURO Y DINÁMICO ---
  Future<bool> login(String user, String passInput) async {
    user = user.trim(); // Limpiar espacios
    if (user.isEmpty || passInput.isEmpty) return false;

    try {
      var doc = await _db.collection('users').doc(user).get();
      if (!doc.exists) {
        // Usuario nuevo: CREAR
        await _db.collection('users').doc(user).set(
            {'password': passInput, 'created': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        currentUser = user;
        isGuest = false;
        _suscribirseADatosEnNube();
        notifyListeners();
        return true;
      } else {
        // Usuario existe: VALIDAR
        String realPass = doc.data()?['password'] ?? '1234';
        if (passInput == realPass) {
          currentUser = user;
          isGuest = false;
          _suscribirseADatosEnNube();
          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      print("Error login: $e");
      return false;
    }
  }

  void loginGuest() {
    currentUser = "Invitado";
    isGuest = true;
    historial = {};
    planificados = {};
    ciclosActivos = {};
    rutinasEditadas = {};
    catalogo = _generarCatalogoCompleto(); // Catálogo limpio
    notifyListeners();
  }

  Future<void> changePassword(
      String user, String currentPass, String newPass) async {
    var doc = await _db.collection('users').doc(user).get();
    if (doc.exists) {
      String realPass = doc.data()?['password'] ?? '';
      if (realPass == currentPass) {
        await _db.collection('users').doc(user).update({'password': newPass});
      } else {
        throw "Contraseña actual incorrecta";
      }
    } else {
      throw "Usuario no encontrado";
    }
  }

  void logout() {
    _userSubscription?.cancel();
    currentUser = "";
    isGuest = false;
    // Solo descargamos la sesión de la memoria RAM, NO borramos de Firebase
    historial = {};
    planificados = {};
    ciclosActivos = {};
    rutinasEditadas = {};
    catalogo = _generarCatalogoCompleto();
    notifyListeners();
  }

  void _suscribirseADatosEnNube() {
    if (isGuest) return;

    _userSubscription?.cancel();
    _userSubscription =
        _db.collection('users').doc(currentUser).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data()!;

        if (data.containsKey('historial')) {
          historial = Map<String, List<Map<String, dynamic>>>.from(json
              .decode(data['historial'])
              .map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v))));
        }
        if (data.containsKey('planificados')) {
          planificados = json
              .decode(data['planificados'])
              .map((k, v) => MapEntry(k, Map<String, String>.from(v)))
              .cast<String, Map<String, String>>();
        }
        if (data.containsKey('ciclos')) {
          ciclosActivos = json.decode(data['ciclos']);
        }
        if (data.containsKey('rutinas')) {
          rutinasEditadas = json
              .decode(data['rutinas'])
              .map<String, RutinaDiaria>(
                  (k, v) => MapEntry(k, RutinaDiaria.fromJson(v)));
        }

        catalogo = _generarCatalogoCompleto();
        if (data.containsKey('custom_treatments')) {
          List<Tratamiento> customs =
              (json.decode(data['custom_treatments']) as List)
                  .map((e) => Tratamiento.fromJson(e))
                  .toList();
          for (var c in customs) {
            catalogo.removeWhere((element) => element.id == c.id);
            catalogo.add(c);
          }
        }

        catalogo = catalogo.where((t) => !t.oculto).toList();
        catalogo.sort((a, b) => a.zona.compareTo(b.zona));

        notifyListeners();
      } else {
        _guardarTodo();
      }
    }, onError: (e) {
      print("Error suscripción Firebase: $e");
    });
  }

  List<Tratamiento> _generarCatalogoCompleto() {
    List<Tratamiento> lista = [];
    for (var t in DB_DEFINICIONES) {
      if (ZONAS_SIMETRICAS.contains(t.zona)) {
        lista.add(t.copyWith(id: "${t.id}_d", nombre: "${t.nombre} (Dcho)"));
        lista.add(t.copyWith(id: "${t.id}_i", nombre: "${t.nombre} (Izq)"));
      } else {
        lista.add(t);
      }
    }
    return lista;
  }

  Future<void> _guardarTodo() async {
    if (currentUser.isEmpty || isGuest) return;

    List<Tratamiento> aGuardar =
        catalogo.where((t) => t.esCustom || t.oculto).toList();
    await _db.collection('users').doc(currentUser).set({
      'historial': json.encode(historial),
      'planificados': json.encode(planificados),
      'ciclos': json.encode(ciclosActivos),
      'rutinas':
          json.encode(rutinasEditadas.map((k, v) => MapEntry(k, v.toJson()))),
      'custom_treatments':
          json.encode(aGuardar.map((e) => e.toJson()).toList()),
      'last_update': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
  }

  void registrarTratamiento(String fecha, String id, String momento) {
    if (!historial.containsKey(fecha)) historial[fecha] = [];
    historial[fecha]!.add({
      'id': id,
      'hora': DateFormat('HH:mm').format(DateTime.now()),
      'momento': momento
    });
    _guardarTodo();
    notifyListeners();
  }

  void planificarTratamiento(String fecha, String id, String momento) {
    if (!planificados.containsKey(fecha)) planificados[fecha] = {};
    planificados[fecha]![id] = momento;
    _guardarTodo();
    notifyListeners();
  }

  void desplanificarTratamiento(String fecha, String id) {
    if (planificados.containsKey(fecha)) {
      planificados[fecha]!.remove(id);
    }
    notifyListeners();
  }

  Future<void> iniciarCiclo(String id) async {
    ciclosActivos[id] = {
      'activo': true,
      'inicio': DateFormat('HH:mm:ss').format(DateTime.now())
    };
    
    // BLE Command
    if (isConnected) {
      try {
        var t = catalogo.firstWhere((e) => e.id == id);
        
        print("BLE: Starting Treatment '${t.nombre}'");

        // 0. STOP First (Reset state)
        print("BLE: Sending Power OFF (Reset)");
        await _bleManager.write(BleProtocol.setPower(false));
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 1. Set Countdown (Duration)
        int duration = int.tryParse(t.duracion) ?? 10;
        print("BLE: Sending Duration: $duration min");
        await _bleManager.write(BleProtocol.setCountdown(duration));
        await Future.delayed(const Duration(milliseconds: 300));
        
        // 2. Set Pulse (Hz) - Send 0 for CW
        int hz = 0;
        bool isCW = t.hz.toUpperCase().contains("CW");
        if (!isCW) {
           RegExp reg = RegExp(r'(\d+)');
           var match = reg.firstMatch(t.hz);
           if (match != null) {
             hz = int.parse(match.group(1)!);
           }
        }
        print("BLE: Sending Pulse: $hz Hz (Mode: ${hz == 0 ? 'CW' : 'Pulse'})");
        await _bleManager.write(BleProtocol.setPulse(hz));
        await Future.delayed(const Duration(milliseconds: 300));

        // 3. Set Brightness (Frequencies)
        List<int> brightnessValues = [0, 0, 0, 0, 0];
        for (var f in t.frecuencias) {
          int nm = f['nm'];
          int p = (f['p'] as num).toInt();
          if (nm == 630) brightnessValues[0] = p;
          else if (nm == 660) brightnessValues[1] = p;
          else if (nm == 810) brightnessValues[2] = p;
          else if (nm == 830) brightnessValues[3] = p;
          else if (nm == 850) brightnessValues[4] = p;
          else if (nm < 700) brightnessValues[1] = p; 
          else brightnessValues[4] = p; 
        }
        print("BLE: Sending Brightness: $brightnessValues");
        await _bleManager.write(BleProtocol.setBrightness(brightnessValues));
        await Future.delayed(const Duration(milliseconds: 300));
        
        // 4. Quick Start (Use CMD_QUICK_START 0x21 instead of Power On 0x20)
        print("BLE: Sending Quick Start (0x21)");
        await _bleManager.write(BleProtocol.quickStart());
        
        print("BLE: Configuration sent.");
        
      } catch (e) {
        print("BLE Error: $e");
        // Optional: Notify UI of error
      }
    }
    
    notifyListeners();
    notifyListeners();
  }

  /// Helper to just send parameters
  Future<void> _sendParameters(Tratamiento t) async {
        // 1. Set Countdown (Duration)
        int duration = int.tryParse(t.duracion) ?? 10;
        print("BLE: Sending Duration: $duration min");
        await _bleManager.write(BleProtocol.setCountdown(duration));
        await Future.delayed(const Duration(milliseconds: 800));
        
        // 2. Set Pulse (Hz)
        int hz = 0;
        bool isCW = t.hz.toUpperCase().contains("CW");
        if (!isCW) {
           RegExp reg = RegExp(r'(\d+)');
           var match = reg.firstMatch(t.hz);
           if (match != null) {
             hz = int.parse(match.group(1)!);
           }
        }
        print("BLE: Sending Pulse: $hz Hz");
        await _bleManager.write(BleProtocol.setPulse(hz));
        await Future.delayed(const Duration(milliseconds: 800));

        // 3. Set Brightness (Frequencies)
      // FINAL MAPPING v35: Confirmed by v34 logs.
      // Registers 0,1,2 map to Indicies 0,1,2.
      // Registers 3,4 map to Indicies 5,6.
      // Indicies 3,4 are ignored holes.
      // Map: [S1, S2, S3, 0, 0, S4, S5]
      List<int> brightnessValues = [0, 0, 0, 0, 0, 0, 0]; 
      
      // Extract values 
      int p630 = 0;
      int p660 = 0;
      int p810 = 0;
      int p830 = 0;
      int p850 = 0;

      for (var f in t.frecuencias) {
        int nm = f['nm'];
        int p = (f['p'] as num).toInt();
        if (nm == 630) p630 = p;
        else if (nm == 660) p660 = p;
        else if (nm == 810) p810 = p;
        else if (nm == 830) p830 = p;
        else if (nm == 850) p850 = p;
      }

      brightnessValues[0] = p630; // Ch 1 -> Byte 0
      brightnessValues[1] = p660; // Ch 2 -> Byte 1
      brightnessValues[2] = p810; // Ch 3 -> Byte 2
      brightnessValues[3] = 0;    // Hole
      brightnessValues[4] = 0;    // Hole
      brightnessValues[5] = p830; // Ch 4 -> Byte 5
      brightnessValues[6] = p850; // Ch 5 -> Byte 6

      print("BLE: Sending Brightness (Final v35): $brightnessValues");
      await _bleManager.write(BleProtocol.setBrightness(brightnessValues));
      await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Starts a manual treatment not in the catalog
  /// [sequenceMode]: 0=Standard (Stop->Params->Start), 1=Live (Params Only), 2=Inverse (Start->Params)
  Future<void> iniciarCicloManual(Tratamiento t, {int startCommand = 0x21, int sequenceMode = 0, int workMode = 0}) async {
     String tempId = t.id;
     
     ciclosActivos[tempId] = {
       'activo': true,
       'inicio': DateFormat('HH:mm:ss').format(DateTime.now())
     };
     
     // BLE Command
     if (isConnected) {
       try {
         print("BLE: Starting Manual Treatment (Seq: $sequenceMode, Cmd: $startCommand, Mode: $workMode)");

        // DEFINE HELPERS
        Future<void> stop() async {
            print("BLE: Sending Power OFF (Reset)");
            await _bleManager.write(BleProtocol.setPower(false));
            await Future.delayed(const Duration(milliseconds: 500));
        }

        Future<void> start() async {
            if (startCommand == 0x21) {
               print("BLE: Sending Quick Start (0x21) with Mode: $workMode");
               await _bleManager.write(BleProtocol.quickStart(mode: workMode));
            } else if (startCommand == 0x20) {
               print("BLE: Sending Power ON (0x20)");
               await _bleManager.write(BleProtocol.setPower(true));
            } else {
               print("BLE: Skipping Start Command");
            }
            await Future.delayed(const Duration(milliseconds: 300));
        }
        
        // Helper to just send parameters
        Future<void> sendParams() async {
             // 0.5 Set Work Mode
            print("BLE: Sending Work Mode: $workMode");
            await _bleManager.write(BleProtocol.setWorkMode(workMode));
            await Future.delayed(const Duration(milliseconds: 800));

            await _sendParameters(t); // Note: _sendParameters inside also sets workMode=0 hardcoded, we need to fix that
        }

        // EXECUTE SEQUENCE
        if (sequenceMode == 0) {
            // Standard: Stop -> Params -> Start
            await stop();
            await sendParams();
            await start();
        } else if (sequenceMode == 1) {
            // Live: Params Only (Good if already running)
            await sendParams();
        } else if (sequenceMode == 2) {
            // Inverse: Start -> Params (If device needs to be ON to accept params)
            await start();
            await sendParams();
        }
        
       } catch (e) {
         print("BLE Manual Error: $e");
         ciclosActivos.remove(tempId);
       }
     }
     notifyListeners();
  }

  Future<void> detenerCiclo(String id) async {
    if (ciclosActivos.containsKey(id)) {
      ciclosActivos[id]!['activo'] = false;
      ciclosActivos[id]!['fin'] =
          DateFormat('HH:mm:ss').format(DateTime.now());
          
      // BLE Command: Turn Off
      if (isConnected) {
        await _bleManager.write(BleProtocol.setPower(false));
      }

      // Guardar en historial (Mock)
      String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (!historial.containsKey(hoy)) historial[hoy] = [];
      historial[hoy]!.add({
        'id': id,
        'hora': ciclosActivos[id]!['inicio'],
        'momento': 'Clínica'
      });
    }
    notifyListeners();
  }

  bool isTratamientoActivo(String id) {
    if (!ciclosActivos.containsKey(id)) return false;
    return ciclosActivos[id]!['activo'] == true;
  }

  void agregarTratamientoCatalogo(Tratamiento t) {
    int index =
        catalogo.indexWhere((e) => e.id == t.id || e.nombre == t.nombre);
    if (index != -1)
      catalogo[index] = t;
    else
      catalogo.add(t);
    _guardarTodo();
    notifyListeners();
  }

  void ocultarTratamiento(String id) {
    int index = catalogo.indexWhere((e) => e.id == id);
    if (index != -1) {
      if (catalogo[index].esCustom)
        catalogo.removeAt(index);
      else
        catalogo[index].oculto = true;
      _guardarTodo();
    }
    notifyListeners();
  }

  RutinaDiaria obtenerRutina(DateTime fecha) {
    String fStr = DateFormat('yyyy-MM-dd').format(fecha);
    if (rutinasEditadas.containsKey(fStr)) return rutinasEditadas[fStr]!;

    String dow = fecha.weekday.toString();
    List<String> fuerza = List.from(RUTINA_SEMANAL_BASE[dow] ?? []);
    return RutinaDiaria(fuerza: fuerza, cardioSessions: []);
  }

  void guardarRutinaEditada(DateTime fecha, RutinaDiaria rutina) {
    String fStr = DateFormat('yyyy-MM-dd').format(fecha);
    rutinasEditadas[fStr] = rutina;
    _guardarTodo();
    notifyListeners();
  }

  Future<List<Tratamiento>> consultarIA(String dolencia) async {
    if (_apiKey.isNotEmpty) {
      final models = ['gemini-1.5-flash', 'gemini-pro', 'gemini-1.0-pro'];
      for (var m in models) {
        try {
          final model = GenerativeModel(model: m, apiKey: _apiKey);
          final prompt = '''
            Actúa como experto en Fotobiomodulación (Red Light Therapy). Usuario: "$dolencia".
            Responde SOLO con un ARRAY JSON válido.
            Esquema: [{"nombre": "...", "zona": "...", "descripcion": "...", "sintomas": "...", "posicion": "...", "hz": "CW/10Hz/50Hz", "duracion": "10", "frecuencias": [{"nm": 660, "p": 100}, {"nm": 850, "p": 50}], "tipsAntes": ["..."], "tipsDespues": ["..."], "prohibidos": ["..."]}]
          ''';
          final response = await model.generateContent([Content.text(prompt)]);
          String text = response.text ?? "[]";
          text = text.replaceAll(RegExp(r'```json|```'), '').trim();
          List<dynamic> data = json.decode(text);
          return data
              .map((item) => Tratamiento(
                  id: Uuid().v4(),
                  nombre: item['nombre'],
                  zona: item['zona'] ?? "General",
                  descripcion: item['descripcion'],
                  sintomas: item['sintomas'],
                  posicion: item['posicion'],
                  hz: item['hz'],
                  duracion: item['duracion'].toString(),
                  frecuencias:
                      List<Map<String, dynamic>>.from(item['frecuencias']),
                  tipsAntes: List<String>.from(item['tipsAntes'] ?? []),
                  tipsDespues: List<String>.from(item['tipsDespues'] ?? []),
                  prohibidos: List<String>.from(item['prohibidos'] ?? []),
                  esCustom: true))
              .toList();
        } catch (e) {
          print("Fallo modelo $m: $e");
          continue;
        }
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    return [
      Tratamiento(
          id: Uuid().v4(),
          nombre: "Protocolo: $dolencia",
          zona: "Zona Afectada",
          descripcion: "Protocolo generado localmente (Sin conexión IA).",
          sintomas: dolencia,
          posicion: "Sobre la zona de dolor",
          hz: "50Hz (Dolor)",
          duracion: "15",
          frecuencias: [
            {'nm': 660, 'p': 50},
            {'nm': 850, 'p': 100}
          ],
          tipsAntes: ["Limpiar zona", "Sin ropa"],
          tipsDespues: ["Movilidad suave"],
          esCustom: true)
    ];
  }
}

class Uuid {
  String v4() => DateTime.now().microsecondsSinceEpoch.toString();
}

// ==============================================================================
// 5. INTERFAZ DE USUARIO (WEB DASHBOARD + MOBILE RESPONSIVE)
// ==============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MegaPanelApp(),
    ),
  );
}

class MegaPanelApp extends StatelessWidget {
  const MegaPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mega Panel AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB71C1C), brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200)),
            margin: const EdgeInsets.symmetric(vertical: 6)),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    var user = context.watch<AppState>().currentUser;
    if (user.isEmpty) return const LoginScreen();
    return const MainLayout();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  void _tryLogin() async {
    setState(() => _loading = true);
    bool ok =
        await context.read<AppState>().login(_userCtrl.text, _passCtrl.text);
    setState(() => _loading = false);
    if (!ok) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Usuario o contraseña incorrectos"),
            backgroundColor: Colors.red));
    }
  }

  void _showChangePassDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final userCtrl = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Cambiar Contraseña"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: "Usuario")),
                TextField(
                    controller: oldCtrl,
                    decoration:
                        const InputDecoration(labelText: "Contraseña Actual"),
                    obscureText: true),
                TextField(
                    controller: newCtrl,
                    decoration:
                        const InputDecoration(labelText: "Nueva Contraseña"),
                    obscureText: true),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancelar")),
                FilledButton(
                    onPressed: () async {
                      try {
                        await context.read<AppState>().changePassword(
                            userCtrl.text, oldCtrl.text, newCtrl.text);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Contraseña cambiada.")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red));
                      }
                    },
                    child: const Text("Cambiar"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science, size: 64, color: Color(0xFFB71C1C)),
                const SizedBox(height: 20),
                const Text("Mega Panel AI Pro",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                      labelText: "Usuario",
                      border: OutlineInputBorder(),
                      hintText: "Ej: Benja, Eva, Pepe..."),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                      labelText: "Contraseña", border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _tryLogin,
                          child: const Text("Entrar / Crear Usuario"))),
                  const SizedBox(height: 10),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () =>
                              context.read<AppState>().loginGuest(),
                          child: const Text(
                              "Entrar como Invitado (Sin guardar)"))),
                ],
                const SizedBox(height: 20),
                TextButton(
                    onPressed: _showChangePassDialog,
                    child: const Text("Cambiar contraseña"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- LAYOUT PRINCIPAL RESPONSIVE ---
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

    // Check API Key
    if (!state.hasApiKey) {
      return Scaffold(
        body: Center(
            child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Configuración: Introduce tu Gemini API Key"),
                  const SizedBox(height: 10),
                  TextField(
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: "API Key"),
                      onSubmitted: (v) => state.setApiKey(v))
                ]))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return _MobileLayout(
              idx: _idx, onNav: (i) => setState(() => _idx = i));
        } else {
          return _DesktopLayout(
              idx: _idx, onNav: (i) => setState(() => _idx = i));
        }
      },
    );
  }
}

// --- CONTENIDO DEL SIDEBAR (REUTILIZABLE) ---
class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isMobile;

  const _SidebarContent(
      {required this.selectedIndex,
      required this.onItemSelected,
      this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          const SizedBox(height: 40)
        else
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Hola, ${state.currentUser}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16))),
        _SidebarItem(
            icon: Icons.calendar_today,
            label: "Panel Diario",
            selected: selectedIndex == 0,
            onTap: () {
              onItemSelected(0);
              if (isMobile) Navigator.pop(context);
            }),
        _SidebarItem(
            icon: Icons.calendar_month,
            label: "Panel Semanal",
            selected: selectedIndex == 1,
            onTap: () {
              onItemSelected(1);
              if (isMobile) Navigator.pop(context);
            }),
        _SidebarItem(
            icon: Icons.history,
            label: "Historial",
            selected: selectedIndex == 2,
            onTap: () {
              onItemSelected(2);
              if (isMobile) Navigator.pop(context);
            }),
        _SidebarItem(
            icon: Icons.medical_services,
            label: "Clínica",
            selected: selectedIndex == 3,
            onTap: () {
              onItemSelected(3);
              if (isMobile) Navigator.pop(context);
            }),
        const Divider(),
        _SidebarItem(
            icon: Icons.auto_awesome,
            label: "Buscador AI",
            selected: selectedIndex == 4,
            onTap: () {
              onItemSelected(4);
              if (isMobile) Navigator.pop(context);
            }),
        _SidebarItem(
            icon: Icons.settings,
            label: "Gestionar",
            selected: selectedIndex == 5,
            onTap: () {
              onItemSelected(5);
              if (isMobile) Navigator.pop(context);
            }),
        _SidebarItem(
            icon: Icons.settings_remote,
            label: "Control Manual",
            selected: selectedIndex == 6,
            onTap: () {
              onItemSelected(6);
              if (isMobile) Navigator.pop(context);
            }),
        const Spacer(),
        // Bluetooth Disconnect Button
        if (state.isConnected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 icon: const Icon(Icons.bluetooth_disabled, color: Colors.indigo),
                 label: const Text("Desconectar", style: TextStyle(color: Colors.indigo)),
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.indigo)),
                 onPressed: () {
                   state.disconnectDevice();
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Bluetooth Desconectado"))
                   );
                   if (isMobile) Navigator.pop(context);
                 },
               ),
            ),
          ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: state.isConnected
                            ? Colors.green.shade600
                            : Colors.blue.shade700,
                        foregroundColor: Colors.white),
                    icon: Icon(
                        state.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        size: 20),
                    label: Text(
                        state.isConnected ? "Conectado" : "Conectar Panel"),
                    onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const BluetoothScanDialog())))),
        Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
                onPressed: state.logout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text("Salir")))
      ],
    );
  }
}

// --- LAYOUT MOVIL ---
class _MobileLayout extends StatelessWidget {
  final int idx;
  final Function(int) onNav;
  const _MobileLayout({required this.idx, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PanelDiarioView(),
      const PanelSemanalView(),
      const HistorialView(),
      const ClinicaView(),
      const BuscadorIAView(),
      const GestionView(),
      BluetoothCustomView()
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text("Mega Panel AI"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0),
      drawer: Drawer(
          child: _SidebarContent(
              selectedIndex: idx, onItemSelected: onNav, isMobile: true)),
      body: Padding(padding: const EdgeInsets.all(16), child: pages[idx]),
    );
  }
}

// --- LAYOUT ESCRITORIO ---
class _DesktopLayout extends StatelessWidget {
  final int idx;
  final Function(int) onNav;
  const _DesktopLayout({required this.idx, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PanelDiarioView(),
      const PanelSemanalView(),
      const HistorialView(),
      const ClinicaView(),
      const BuscadorIAView(),
      const GestionView(),
      BluetoothCustomView()
    ];
    return Scaffold(
      body: Row(
        children: [
          Container(
              width: 260,
              color: const Color(0xFFF0F2F6),
              child:
                  _SidebarContent(selectedIndex: idx, onItemSelected: onNav)),
          Expanded(
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: pages[idx]))
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: selected ? Colors.white : null,
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? const Color(0xFFB71C1C) : Colors.grey[700]),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color:
                        selected ? const Color(0xFFB71C1C) : Colors.grey[800],
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// --- VISTA 1: DIARIO ---
class PanelDiarioView extends StatelessWidget {
  const PanelDiarioView({super.key});
  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    DateTime hoyDt = DateTime.now();
    String hoy = DateFormat('yyyy-MM-dd').format(hoyDt);
    RutinaDiaria rutina = state.obtenerRutina(hoyDt);
    var hechos = state.historial[hoy] ?? [];
    var planificadosMap = state.planificados[hoy] ?? {};
    List<Tratamiento> listaMostrar = [];
    planificadosMap.forEach((id, momento) {
      var t = state.catalogo.firstWhere((e) => e.id == id,
          orElse: () => Tratamiento(id: "err", nombre: "Error", zona: ""));
      if (t.id != "err") {
        listaMostrar.add(t);
      }
    });
    List<Tratamiento> completados =
        listaMostrar.where((t) => hechos.any((h) => h['id'] == t.id)).toList();
    List<Tratamiento> pendientes =
        listaMostrar.where((t) => !hechos.any((h) => h['id'] == t.id)).toList();

    return ListView(children: [
      const Text("Panel Diario",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text("Fecha: ${DateFormat('yyyy/MM/dd').format(hoyDt)}",
          style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      if (state.currentUser.toLowerCase() == "benja") ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("Fuerza: ${rutina.fuerza.join(", ")}",
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  if (rutina.cardioSessions.isEmpty)
                    const Text("Sin Cardio")
                  else
                    ...rutina.cardioSessions
                        .map((c) => Text("• ${c.getSummary()}"))
                ])),
            IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) =>
                        EditRoutineDialog(fecha: hoyDt, rutinaActual: rutina)))
          ]),
        ),
        const SizedBox(height: 20),
      ],
      _BuscadorManual(
          catalogo: state.catalogo,
          onAdd: (t, momento) =>
              state.planificarTratamiento(hoy, t.id, momento),
          askTime: true),
      const SizedBox(height: 10),
      if (listaMostrar.isNotEmpty)
        OutlinedButton.icon(
            icon: const Icon(Icons.flash_on, color: Colors.orange),
            label: const Text("Registrar Todo"),
            onPressed: () {
              for (var t in listaMostrar) {
                if (!hechos.any((h) => h['id'] == t.id))
                  state.registrarTratamiento(hoy, t.id, "Batch");
              }
            }),
      const SizedBox(height: 20),
      const Text("✅ Completados",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
      ...completados.map((t) => ListTile(
          leading: const Icon(Icons.check_box, color: Colors.green),
          title: Text(t.nombre),
          subtitle: Text(planificadosMap[t.id] ?? "Clínica"))),
      const SizedBox(height: 20),
      const Text("📋 Pendientes",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (pendientes.isEmpty)
        const Text("Nada por hoy.", style: TextStyle(color: Colors.grey)),
      ...pendientes.map((t) => TreatmentCard(
          t: t,
          isPlanned: true,
          plannedMoment: planificadosMap[t.id],
          onDeletePlan: () => state.desplanificarTratamiento(hoy, t.id),
          onStart: () async {
            if (!state.isConnected) {
              await showDialog(
                  context: context,
                  builder: (_) => const BluetoothScanDialog());
            }
            if (state.isConnected) {
              await state.iniciarCiclo(t.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Iniciando ${t.nombre}..."),
                    backgroundColor: Colors.green));
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("No conectado. Intente de nuevo."),
                    backgroundColor: Colors.orange));
              }
            }
          },
          onRegister: () =>
              state.registrarTratamiento(hoy, t.id, planificadosMap[t.id]!))),
    ]);
  }
}

// --- DIALOGO EDICIÓN RUTINA ---
class EditRoutineDialog extends StatefulWidget {
  final DateTime fecha;
  final RutinaDiaria rutinaActual;
  const EditRoutineDialog(
      {super.key, required this.fecha, required this.rutinaActual});
  @override
  State<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends State<EditRoutineDialog> {
  late List<String> fuerzaSel;
  late List<CardioSession> sessions;

  // Valores por defecto
  String selectedType = CARDIO_TYPES[0];
  TextEditingController durationCtrl = TextEditingController(text: "20");

  // Variables temporales para inputs
  int steps = 5000;
  double speed = 6.0;
  double incline = 2.0;
  double resistance = 5.0;
  double watts = 100.0;
  String norwegianMachine = "Cinta"; // Por defecto

  @override
  void initState() {
    super.initState();
    fuerzaSel = List.from(widget.rutinaActual.fuerza);
    sessions = List.from(widget.rutinaActual.cardioSessions);
  }

  void _addSession() {
    CardioSession newSession = CardioSession(
        type: selectedType, duration: int.tryParse(durationCtrl.text) ?? 0);
    if (selectedType == "Andar")
      newSession.steps = steps;
    else if (selectedType == "Elíptica") {
      newSession.resistance = resistance;
      newSession.watts = watts;
    } else if (selectedType == "Cinta Inclinada") {
      newSession.speed = speed;
      newSession.incline = incline;
    } else if (selectedType == "Protocolo Noruego") {
      newSession.duration =
          32; // Duración fija del protocolo (4x4 + calentamiento/enfriamiento aprox)
      newSession.machine = norwegianMachine;
      // Guardar parámetros específicos según la máquina del Noruego
      if (norwegianMachine == "Cinta") {
        newSession.speed = speed;
        newSession.incline = incline;
      } else if (norwegianMachine == "Elíptica") {
        newSession.resistance = resistance;
        newSession.watts = watts;
      } else if (norwegianMachine == "Remo") {
        newSession.speed = speed; // Usamos campo speed para ritmo/velocidad
        newSession.resistance = resistance;
      }
    }
    setState(() => sessions.add(newSession));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar Rutina"),
      content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text("Fuerza:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                    spacing: 5,
                    children: RUTINAS_POSIBLES
                        .map((r) => FilterChip(
                            label: Text(r),
                            selected: fuerzaSel.contains(r),
                            onSelected: (s) => setState(() =>
                                s ? fuerzaSel.add(r) : fuerzaSel.remove(r))))
                        .toList()),
                const Divider(),
                const Text("Cardio:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...sessions.asMap().entries.map((entry) => Card(
                    color: Colors.grey.shade50,
                    child: ListTile(
                        title: Text(entry.value.getSummary()),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(
                                () => sessions.removeAt(entry.key)))))),
                const SizedBox(height: 10),
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade100),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.shade50),
                    child: Column(children: [
                      DropdownButton<String>(
                          isExpanded: true,
                          value: selectedType,
                          items: CARDIO_TYPES
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => selectedType = v!)),
                      if (selectedType == "Andar")
                        Row(children: [
                          const Text("Pasos: "),
                          IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => setState(() {
                                    if (steps > 500) steps -= 500;
                                  })),
                          Text("$steps"),
                          IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => steps += 500))
                        ]),
                      if (selectedType == "Elíptica")
                        Column(children: [
                          TextField(
                              controller: durationCtrl,
                              decoration:
                                  const InputDecoration(labelText: "Min")),
                          Slider(
                              value: resistance,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: resistance.round().toString(),
                              onChanged: (v) => setState(() => resistance = v)),
                          TextField(
                              decoration:
                                  const InputDecoration(labelText: "Watios"),
                              onChanged: (v) => watts = double.tryParse(v) ?? 0)
                        ]),
                      if (selectedType == "Cinta Inclinada")
                        Row(children: [
                          Expanded(
                              child: TextField(
                                  controller: durationCtrl,
                                  decoration:
                                      const InputDecoration(labelText: "Min"))),
                          Expanded(
                              child: TextField(
                                  decoration:
                                      const InputDecoration(labelText: "Km/h"),
                                  onChanged: (v) =>
                                      speed = double.tryParse(v) ?? 6)),
                          Expanded(
                              child: TextField(
                                  decoration:
                                      const InputDecoration(labelText: "% Inc"),
                                  onChanged: (v) =>
                                      incline = double.tryParse(v) ?? 2))
                        ]),
                      if (selectedType == "Protocolo Noruego")
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("⏱️ Duración fija: 32 min (4x4)",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            const SizedBox(height: 5),
                            DropdownButton<String>(
                                value: norwegianMachine,
                                isExpanded: true,
                                items: ["Cinta", "Elíptica", "Remo"]
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text("Máquina: $m")))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => norwegianMachine = v!)),
                            const SizedBox(height: 10),

                            // CAMPOS ESPECÍFICOS NORUEGO
                            if (norwegianMachine == "Cinta")
                              Row(children: [
                                Expanded(
                                    child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Vel (Km/h)",
                                            border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) =>
                                            speed = double.tryParse(v) ?? 0)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Inclinación %",
                                            border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) =>
                                            incline = double.tryParse(v) ?? 0)),
                              ]),

                            if (norwegianMachine == "Remo")
                              Row(children: [
                                Expanded(
                                    child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Velocidad",
                                            border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) =>
                                            speed = double.tryParse(v) ?? 0)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Resistencia",
                                            border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => resistance =
                                            double.tryParse(v) ?? 0)),
                              ]),

                            if (norwegianMachine == "Elíptica")
                              Row(children: [
                                Expanded(
                                    child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Watios",
                                            border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) =>
                                            watts = double.tryParse(v) ?? 0)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Resistencia",
                                            border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => resistance =
                                            double.tryParse(v) ?? 0)),
                              ]),
                          ],
                        ),
                      if (selectedType == "Remo Ergómetro" ||
                          selectedType == "Descanso Cardio")
                        TextField(
                            controller: durationCtrl,
                            decoration:
                                const InputDecoration(labelText: "Minutos")),
                      ElevatedButton(
                          onPressed: _addSession, child: const Text("Añadir"))
                    ]))
              ]))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar")),
        FilledButton(
            onPressed: () {
              context.read<AppState>().guardarRutinaEditada(widget.fecha,
                  RutinaDiaria(fuerza: fuerzaSel, cardioSessions: sessions));
              Navigator.pop(context);
            },
            child: const Text("Guardar"))
      ],
    );
  }
}

// --- VISTA 2: SEMANAL ---
class PanelSemanalView extends StatefulWidget {
  const PanelSemanalView({super.key});
  @override
  State<PanelSemanalView> createState() => _PanelSemanalViewState();
}

class _PanelSemanalViewState extends State<PanelSemanalView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<DateTime> _days = List.generate(
      7,
      (i) =>
          DateTime.now().add(Duration(days: i - DateTime.now().weekday + 1)));
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 7, vsync: this, initialIndex: DateTime.now().weekday - 1);
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    return Column(children: [
      TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          tabs: _days
              .map((d) => Tab(text: "${DateFormat('E').format(d)} ${d.day}"))
              .toList()),
      Expanded(
          child: TabBarView(
              controller: _tabController,
              children: _days.map((d) {
                String fStr = DateFormat('yyyy-MM-dd').format(d);
                var plans = state.planificados[fStr] ?? {};
                RutinaDiaria rut = state.obtenerRutina(d);
                return ListView(padding: const EdgeInsets.all(16), children: [
                  if (state.currentUser.toLowerCase() == "benja")
                    Card(
                        child: ListTile(
                            title: Text("🏋️ ${rut.fuerza.join(", ")}"),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: rut.cardioSessions
                                    .map((c) => Text("• ${c.getSummary()}"))
                                    .toList()),
                            trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => EditRoutineDialog(
                                        fecha: d, rutinaActual: rut))))),
                  const SizedBox(height: 10),
                  _BuscadorManual(
                      catalogo: state.catalogo,
                      onAdd: (t, m) =>
                          state.planificarTratamiento(fStr, t.id, m),
                      askTime: true),
                  const Divider(),
                  ...plans.entries.map((e) {
                    var t = state.catalogo.firstWhere((x) => x.id == e.key,
                        orElse: () =>
                            Tratamiento(id: "", nombre: "?", zona: ""));
                    return TreatmentCard(
                        t: t,
                        isPlanned: true,
                        plannedMoment: e.value,
                        onDeletePlan: () =>
                            state.desplanificarTratamiento(fStr, t.id));
                  })
                ]);
              }).toList()))
    ]);
  }
}

// --- VISTA 3: HISTORIAL ---
class HistorialView extends StatelessWidget {
  const HistorialView({super.key});
  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    List<Map<String, String>> rows = [];
    state.historial.forEach((fecha, lista) {
      for (var item in lista) {
        var t = state.catalogo.firstWhere((element) => element.id == item['id'],
            orElse: () => Tratamiento(id: "", nombre: "???", zona: ""));
        rows.add({
          "Fecha": fecha,
          "Hora": item['hora'],
          "Tratamiento": t.nombre,
          "Momento": item['momento']
        });
      }
    });
    rows.sort((a, b) => b['Fecha']!.compareTo(a['Fecha']!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📊 Historial de Registros",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Fecha")),
                DataColumn(label: Text("Hora")),
                DataColumn(label: Text("Tratamiento")),
                DataColumn(label: Text("Estado"))
              ],
              rows: rows
                  .map((r) => DataRow(cells: [
                        DataCell(Text(r['Fecha']!)),
                        DataCell(Text(r['Hora']!)),
                        DataCell(Text(r['Tratamiento']!)),
                        DataCell(Text(r['Momento']!)),
                      ]))
                  .toList(),
            ),
          ),
        )
      ],
    );
  }
}

// --- VISTA 4: CLÍNICA ---
class ClinicaView extends StatelessWidget {
  const ClinicaView({super.key});
  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    return ListView(children: [
      const Text("🏥 Clínica",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      const Text("Tratamientos Activos en Curso:",
          style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 10),
      ...state.catalogo
          .where((t) => state.ciclosActivos[t.id]?['activo'] == true)
          .map((t) => Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  title: Text(t.nombre),
                  subtitle:
                      Text("Iniciado: ${state.ciclosActivos[t.id]['inicio']}"),
                  trailing: FilledButton(
                      onPressed: () => state.detenerCiclo(t.id),
                      child: const Text("Finalizar")),
                ),
              )),
      const Divider(height: 40),
      const Text("Iniciar Nuevo Tratamiento:",
          style: TextStyle(fontWeight: FontWeight.bold)),
      _BuscadorManual(
        catalogo: state.catalogo,
        onAdd: (t, _) => state.iniciarCiclo(t.id),
        askTime: false,
      )
    ]);
  }
}

// --- VISTA 5: BUSCADOR IA ---
class BuscadorIAView extends StatefulWidget {
  const BuscadorIAView({super.key});
  @override
  State<BuscadorIAView> createState() => _BuscadorIAViewState();
}

class _BuscadorIAViewState extends State<BuscadorIAView> {
  final _ctrl = TextEditingController();
  List<Tratamiento> _results = [];
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Buscador IA",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
              labelText: "Describe dolencia...",
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  setState(() => _loading = true);
                  try {
                    var r = await state.consultarIA(_ctrl.text);
                    if (!context.mounted) return;
                    setState(() {
                      _results = r;
                      _loading = false;
                    });
                  } catch (e) {
                    if (!context.mounted) return;
                    setState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Info: $e"),
                        backgroundColor: Colors.orange));
                  }
                },
              )),
        ),
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) {
              var t = _results[i];
              return TreatmentCard(
                  t: t,
                  onRegister: () {
                    state.agregarTratamientoCatalogo(t);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Guardado en Catálogo")));
                  });
            },
          ),
        )
      ],
    );
  }
}

// --- VISTA 6: GESTION ---
class GestionView extends StatelessWidget {
  const GestionView({super.key});
  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    return ListView(
      children: [
        const Text("⚙️ Gestión de Tratamientos",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...state.catalogo.map((t) => TreatmentCard(
              t: t,
              onDeletePlan: () => state.ocultarTratamiento(t.id),
            ))
      ],
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _BuscadorManual extends StatelessWidget {
  final List<Tratamiento> catalogo;
  final Function(Tratamiento, String) onAdd;
  final bool askTime;

  const _BuscadorManual(
      {required this.catalogo, required this.onAdd, this.askTime = true});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("➕ Añadir Tratamiento Manual"),
      collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300)),
      children: [
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: catalogo.length,
            itemBuilder: (ctx, i) {
              var t = catalogo[i];
              return ListTile(
                title: Text(t.nombre),
                subtitle: Text(t.sintomas,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                            content: SingleChildScrollView(
                              child: SizedBox(
                                width: double.maxFinite,
                                child: TreatmentCard(t: t),
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text("Cancelar")),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  if (askTime) {
                                    showDialog(
                                        context: context,
                                        builder: (_) => SimpleDialog(
                                              title: const Text("¿Cuándo?"),
                                              children: [
                                                "PRE",
                                                "POST",
                                                "NOCHE",
                                                "FLEX"
                                              ]
                                                  .map(
                                                      (m) => SimpleDialogOption(
                                                            child: Text(m),
                                                            onPressed: () {
                                                              onAdd(t, m);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ))
                                                  .toList(),
                                            ));
                                  } else {
                                    onAdd(t, "Now");
                                  }
                                },
                                child: const Text("Seleccionar / Añadir"),
                              )
                            ],
                          ));
                },
              );
            },
          ),
        )
      ],
    );
  }
}

class TreatmentCard extends StatefulWidget {
  final Tratamiento t;
  final bool isPlanned;
  final bool isDone;
  final String? plannedMoment;
  final VoidCallback? onRegister;
  final VoidCallback? onDeletePlan;
  final VoidCallback? onStart;

  const TreatmentCard(
      {super.key,
      required this.t,
      this.isPlanned = false,
      this.isDone = false,
      this.plannedMoment,
      this.onRegister,
      this.onDeletePlan,
      this.onStart});

  @override
  State<TreatmentCard> createState() => _TreatmentCardState();
}

class _TreatmentCardState extends State<TreatmentCard> {
  bool _initiallyExpanded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPlanned && !widget.isDone) {
      _initiallyExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    bool isActive = state.isTratamientoActivo(widget.t.id);
    
    Color statusColor = widget.isDone
        ? Colors.green
        : (isActive ? Colors.red : (widget.isPlanned ? Colors.blue : Colors.grey));

    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: _initiallyExpanded || isActive,
        leading: Icon(
            widget.isDone ? Icons.check_circle : (isActive ? Icons.flash_on : Icons.circle_outlined),
            color: statusColor),
        title: Text(widget.t.nombre,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: widget.isDone ? TextDecoration.lineThrough : null)),
        subtitle: isActive 
             ? const Text("EN CURSO...", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
             : (widget.isPlanned
                ? Text("Planificado: ${widget.plannedMoment}",
                    style: const TextStyle(color: Colors.blue))
                : null),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.t.sintomas.isNotEmpty)
                  _buildSection("Indicado para", widget.t.sintomas,
                      Icons.medical_information, Colors.grey.shade200),
                const SizedBox(height: 10),
                if (widget.t.posicion.isNotEmpty)
                  _buildSection("Posición", widget.t.posicion,
                      Icons.accessibility_new, Colors.purple.shade50),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Icon(Icons.waves, size: 20),
                        Text(widget.t.hz,
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                      Column(children: [
                        const Icon(Icons.timer, size: 20),
                        Text("${widget.t.duracion} min",
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                      Column(children: [
                        const Icon(Icons.light_mode, size: 20),
                        ...widget.t.frecuencias
                            .map((f) => Text("${f['nm']}nm: ${f['p']}%",
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)))
                            .toList()
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.t.tipsAntes.isNotEmpty)
                  _buildSection("Consejos Antes", widget.t.tipsAntes.join("\n"),
                      Icons.info_outline, Colors.blue.shade50),
                const SizedBox(height: 5),
                if (widget.t.tipsDespues.isNotEmpty)
                  _buildSection(
                      "Consejos Después",
                      widget.t.tipsDespues.join("\n"),
                      Icons.check_circle_outline,
                      Colors.green.shade50),
                const SizedBox(height: 5),
                if (widget.t.prohibidos.isNotEmpty)
                  _buildSection("PROHIBIDO", widget.t.prohibidos.join("\n"),
                      Icons.warning_amber, Colors.red.shade50),
                const SizedBox(height: 15),
                
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // STOP BUTTON
                      if (isActive)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.stop, color: Colors.red),
                          label: const Text("Detener Tratamiento", style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          onPressed: () {
                             state.detenerCiclo(widget.t.id);
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Tratamiento detenido"), backgroundColor: Colors.red)
                             );
                          },
                        ),
                        
                      const SizedBox(width: 8),

                      if (widget.onStart != null && !widget.isDone && !isActive)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange.shade700),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Iniciar"),
                          onPressed: widget.onStart,
                        ),
                      const SizedBox(width: 8),
                      // Delete Plan
                      if (widget.isPlanned &&
                          widget.onDeletePlan != null &&
                          !widget.isDone && !isActive)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Quitar"),
                          onPressed: widget.onDeletePlan,
                        ),
                      const SizedBox(width: 8),
                      // Register
                      if (!widget.isDone && !isActive && widget.onRegister != null)
                        FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Registrar"),
                          onPressed: widget.onRegister,
                        ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}
// --- BLUETOOTH DIALOG ---
class BluetoothScanDialog extends StatefulWidget {
  const BluetoothScanDialog({super.key});

  @override
  State<BluetoothScanDialog> createState() => _BluetoothScanDialogState();
}

class _BluetoothScanDialogState extends State<BluetoothScanDialog> {
  final BleManager _ble = BleManager();
  bool showAll = false;
  
  @override
  void initState() {
    super.initState();
    _ble.startScan();
  }

  @override
  void dispose() {
    _ble.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    
    return AlertDialog(
      title: const Text("Dispositivos Bluetooth"),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
             if (state.isConnected)
              ListTile(
                title: Text(state._bleManager.connectedDevice?.platformName ?? "Desconocido"),
                subtitle: const Text("Conectado"),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    state.disconnectDevice();
                    Navigator.pop(context);
                  },
                ),
              ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: _ble.scanResults,
                initialData: const [],
                builder: (c, snapshot) {
                  var results = snapshot.data ?? [];
                  // Filter and Sort
                  var filtered = results.where((r) => r.device.platformName.isNotEmpty).toList();
                  
                  // Strict Filter by default
                  if (!showAll) {
                    filtered = filtered.where((r) {
                      String name = r.device.platformName.toLowerCase();
                      return name.contains("block") || name.contains("panel") || name.contains("mega");
                    }).toList();
                  }

                  filtered.sort((a, b) {
                    var nameA = a.device.platformName.toLowerCase();
                    var nameB = b.device.platformName.toLowerCase();
                    bool aIsBlock = nameA.contains("block");
                    bool bIsBlock = nameB.contains("block");
                    
                    if (aIsBlock && !bIsBlock) return -1;
                    if (!aIsBlock && bIsBlock) return 1;
                    
                    return b.rssi.compareTo(a.rssi);
                  });

                  if (filtered.isEmpty) {
                     return Center(child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Text("Buscando dispositivos..."),
                         if (!showAll)
                           TextButton(
                             onPressed: () => setState(() => showAll = true),
                             child: const Text("Mostrar todos (Debug)")
                           )
                       ],
                     ));
                  }

                  return ListView.builder(
                    itemCount: filtered.length + (showAll ? 0 : 1), // +1 for the toggle button at bottom
                    itemBuilder: (ctx, i) {
                      if (i == filtered.length) {
                        return Center(child: TextButton(
                             onPressed: () => setState(() => showAll = true),
                             child: const Text("Mostrar todos los dispositivos")
                           ));
                      }
                      var d = filtered[i].device;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(d.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${d.remoteId} (${filtered[i].rssi} dBm)"),
                        onTap: () async {
                           // Show loading indicator
                           showDialog(
                             context: context, 
                             barrierDismissible: false,
                             builder: (c) => const Center(child: CircularProgressIndicator())
                           );
                           
                           bool success = await state.connectToDevice(d);
                           
                           if (context.mounted) {
                             Navigator.pop(context); // Dismiss loading
                             if (success) {
                               Navigator.pop(context); // Dismiss scan dialog
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text("Conectado a ${d.platformName}"), backgroundColor: Colors.green)
                               );
                             } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Error al conectar. Intente de nuevo."), backgroundColor: Colors.red)
                               );
                             }
                           }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        )
      ],
    );
  }
}
