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

const Color kManualBg = Color(0xFFE8EDF5);
const Color kManualGradStart = Color(0xFF1ED6CD);
const Color kManualGradEnd = Color(0xFF4B86ED);
const LinearGradient kManualGradient = LinearGradient(
  colors: [kManualGradStart, kManualGradEnd],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

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
      {
        details += "Res: ${resistance.toInt()}, W: ${watts.toInt()}";
      }
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
      descripcion: "Dolor lateral de codo por sobreuso tendinoso.",
      sintomas: "Dolor al agarrar o girar.",
      posicion: "5-15cm lateral sobre epicondilo.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar sobre tumor local o infeccion activa."]),
  Tratamiento(
      id: "codo_golf",
      nombre: "Epitrocleitis (Golfista)",
      zona: "Codo",
      descripcion: "Tendinopatia medial de codo.",
      sintomas: "Dolor en cara interna del codo.",
      posicion: "5-15cm medial sobre epitroclea.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar sobre tumor local o infeccion activa."]),
  Tratamiento(
      id: "codo_calc",
      nombre: "Calcificacion",
      zona: "Codo",
      descripcion: "Coadyuvante en tendinopatia calcifica dolorosa.",
      sintomas: "Dolor punzante y sensibilidad osea.",
      posicion: "5-10cm sobre zona calcificada.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 25},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "13",
      prohibidos: ["Suspender si hay sospecha de rotura completa."]),
  Tratamiento(
      id: "codo_bur",
      nombre: "Bursitis (Apoyo)",
      zona: "Codo",
      descripcion: "Bursitis no septica en fase no aguda.",
      sintomas: "Bulto y dolor a la presion.",
      posicion: "10-20cm sin contacto sobre bursa.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar si hay fiebre o bursitis septica sospechada."]),

  // ESPALDA
  Tratamiento(
      id: "esp_cerv",
      nombre: "Cervicalgia (Cuello)",
      zona: "Espalda",
      descripcion: "Dolor cervical mecanico.",
      sintomas: "Rigidez en cuello y trapecios.",
      posicion: "5-15cm posterior cervical.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "13",
      prohibidos: ["Consultar si hay radiculopatia progresiva."]),
  Tratamiento(
      id: "esp_dors",
      nombre: "Dorsalgia (Alta)",
      zona: "Espalda",
      descripcion: "Dolor dorsal miofascial.",
      sintomas: "Molestia entre escapulas.",
      posicion: "5-15cm dorsal alta paravertebral.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "13",
      prohibidos: ["No usar ante dolor toracico de causa no aclarada."]),
  Tratamiento(
      id: "esp_lumb",
      nombre: "Lumbalgia (Baja)",
      zona: "Espalda",
      descripcion: "Lumbalgia inespecifica cronica o subaguda.",
      sintomas: "Dolor lumbar con rigidez.",
      posicion: "5-15cm lumbar paravertebral.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["Urgencias si hay deficit neurologico o sintomas de cauda equina."]),

  // ANTEBRAZO
  Tratamiento(
      id: "ant_sobre",
      nombre: "Sobrecarga",
      zona: "Antebrazo",
      descripcion: "Sobrecarga muscular por esfuerzo repetido.",
      sintomas: "Fatiga y dureza muscular.",
      posicion: "10-20cm sobre masa muscular.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 25},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar en lesion aguda grave no evaluada."]),
  Tratamiento(
      id: "ant_tend",
      nombre: "Tendinitis",
      zona: "Antebrazo",
      descripcion: "Tendinopatia localizada de antebrazo.",
      sintomas: "Dolor puntual en trayecto tendinoso.",
      posicion: "5-15cm en tendon doloroso.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "11",
      prohibidos: ["No usar sobre infeccion local activa."]),

  // MUNECA
  Tratamiento(
      id: "mun_tunel",
      nombre: "Tunel Carpiano",
      zona: "Muneca",
      descripcion: "Sintomas leves-moderados de tunel carpiano.",
      sintomas: "Hormigueo y dolor nocturno.",
      posicion: "5-10cm sobre tunel carpiano, palma arriba.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 30},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "11",
      prohibidos: ["Derivar si hay atrofia tenar o debilidad progresiva."]),
  Tratamiento(
      id: "mun_art",
      nombre: "Articular (General)",
      zona: "Muneca",
      descripcion: "Dolor articular inespecifico de muneca.",
      sintomas: "Dolor al movimiento.",
      posicion: "5-15cm alrededor de muneca.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "11",
      prohibidos: ["No usar si hay sospecha de fractura aguda."]),

  // PIERNA
  Tratamiento(
      id: "pierna_itb",
      nombre: "Cintilla Iliotibial",
      zona: "Pierna",
      descripcion: "Dolor lateral por sobreuso de cintilla.",
      sintomas: "Dolor lateral externo en muslo o rodilla.",
      posicion: "5-15cm en banda iliotibial lateral.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "13",
      prohibidos: ["No usar si hay edema importante o desgarro mayor sospechado."]),
  Tratamiento(
      id: "pierna_fem",
      nombre: "Sobrecarga Femoral",
      zona: "Pierna",
      descripcion: "Recuperacion muscular post esfuerzo.",
      sintomas: "Pesadez y fatiga en muslo.",
      posicion: "10-20cm en musculo sobrecargado.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 25},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "13",
      prohibidos: ["No usar en desgarro muscular agudo severo."]),

  // PIE
  Tratamiento(
      id: "pie_fasc",
      nombre: "Fascitis Plantar",
      zona: "Pie",
      descripcion: "Fascitis plantar cronica/subaguda.",
      sintomas: "Dolor en talon al apoyar.",
      posicion: "5-15cm en fascia plantar y talon.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay rotura fascial o infeccion local."]),
  Tratamiento(
      id: "pie_esg",
      nombre: "Esguince (Dorsal)",
      zona: "Pie",
      descripcion: "Esguince leve/moderado en recuperacion.",
      sintomas: "Dolor e hinchazon en tobillo o empeine.",
      posicion: "10-20cm en zona de esguince.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "11",
      prohibidos: ["No usar con sospecha de fractura o inestabilidad severa."]),
  Tratamiento(
      id: "pie_lat",
      nombre: "Lateral (5o Metatarso)",
      zona: "Pie",
      descripcion: "Dolor lateral por sobrecarga local.",
      sintomas: "Molestia en borde externo del pie.",
      posicion: "10-20cm en borde lateral del pie.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "11",
      prohibidos: ["Descartar fractura por estres antes de usar."]),

  // HOMBRO
  Tratamiento(
      id: "homb_tend",
      nombre: "Tendinitis",
      zona: "Hombro",
      descripcion: "Tendinopatia del manguito rotador.",
      sintomas: "Dolor al elevar el brazo.",
      posicion: "5-15cm sobre manguito rotador y deltoides.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 25},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay sospecha de rotura completa del manguito."]),
  Tratamiento(
      id: "homb_supra",
      nombre: "Tendinopatia Supraespinoso",
      zona: "Hombro",
      descripcion: "Tendinopatia del supraespinoso (manguito rotador).",
      sintomas: "Dolor en elevacion y arco doloroso subacromial.",
      posicion: "5-15cm sobre insercion del supraespinoso y espacio subacromial.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 30},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay rotura completa no evaluada clinicamente."]),

  // RODILLA
  Tratamiento(
      id: "rod_gen",
      nombre: "General/Menisco",
      zona: "Rodilla",
      descripcion: "Dolor de rodilla degenerativo.",
      sintomas: "Molestia articular y rigidez.",
      posicion: "5-15cm periarticular de rodilla.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 40}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar con bloqueo mecanico severo agudo."]),
  Tratamiento(
      id: "rod_pfps",
      nombre: "Dolor Patelofemoral",
      zona: "Rodilla",
      descripcion: "Dolor anterior de rodilla por sobreuso.",
      sintomas: "Dolor al subir/bajar escaleras o sentadillas.",
      posicion: "5-15cm periarticular anterior de rodilla.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 40}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: [
        "No usar con derrame agudo severo o bloqueo articular.",
        "No sustituye rehabilitacion de fuerza de cadera/cuadriceps."
      ]),
  Tratamiento(
      id: "rod_rotul",
      nombre: "Tendinopatia Rotuliana",
      zona: "Rodilla",
      descripcion: "Tendinopatia del tendon rotuliano por sobrecarga.",
      sintomas: "Dolor infrapatelar al salto, sentadilla o carrera.",
      posicion: "5-10cm sobre polo inferior de rotula y tendon rotuliano.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 30},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay sospecha de rotura parcial alta o completa."]),
  Tratamiento(
      id: "tob_aquiles",
      nombre: "Tendinopatia de Aquiles",
      zona: "Tobillo",
      descripcion: "Tendinopatia aquilea cronica o subaguda.",
      sintomas: "Dolor y rigidez matinal en tendon de Aquiles.",
      posicion: "5-15cm sobre tendon aquileo, evitando calor.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 25},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 35}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay sospecha de rotura del tendon de Aquiles."]),
  Tratamiento(
      id: "cara_atm",
      nombre: "Dolor Temporomandibular (ATM)",
      zona: "Cara",
      descripcion: "Dolor miofascial/ATM de causa mecanica.",
      sintomas: "Dolor al masticar, rigidez mandibular o clic doloroso.",
      posicion: "5-10cm sobre ATM y masetero, evitando ojos.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 25},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 15}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: [
        "No usar sobre glandula tiroidea.",
        "Derivar si hay trismus severo o bloqueo mandibular agudo."
      ]),

  // PIEL
  Tratamiento(
      id: "piel_cicat",
      nombre: "Cicatrices",
      zona: "Piel",
      descripcion: "Coadyuvante en cicatriz cerrada.",
      sintomas: "Textura o color irregular de cicatriz.",
      posicion: "15-25cm sobre cicatriz cerrada.",
      frecuencias: [
        {'nm': 630, 'p': 30},
        {'nm': 660, 'p': 50},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar en cicatriz con infeccion activa."]),
  Tratamiento(
      id: "piel_acne",
      nombre: "Acne",
      zona: "Piel",
      descripcion: "Acne inflamatorio leve-moderado (coadyuvante).",
      sintomas: "Brotes inflamatorios y rojez.",
      posicion: "15-25cm frente al rostro con gafas.",
      frecuencias: [
        {'nm': 630, 'p': 20},
        {'nm': 660, 'p': 80},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar como monoterapia en acne noduloquistico severo."]),
  Tratamiento(
      id: "piel_quem",
      nombre: "Quemaduras",
      zona: "Piel",
      descripcion: "Quemadura superficial no complicada.",
      sintomas: "Piel enrojecida y sensible.",
      posicion: "20-30cm sin calor sobre quemadura superficial.",
      frecuencias: [
        {'nm': 630, 'p': 30},
        {'nm': 660, 'p': 40},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 10},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "6",
      prohibidos: ["No usar en quemadura profunda o necrosis."]),
  Tratamiento(
      id: "pie_ulc",
      nombre: "Ulcera Pie Diabetico (Apoyo)",
      zona: "Pie",
      descripcion: "Ulcera superficial no complicada (coadyuvante).",
      sintomas: "Lesion cronica superficial en pie diabetico.",
      posicion: "20-30cm sin contacto sobre borde perilesional.",
      frecuencias: [
        {'nm': 630, 'p': 30},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 15},
        {'nm': 830, 'p': 10},
        {'nm': 850, 'p': 15}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: [
        "No sustituye desbridamiento o antibiotico indicado.",
        "No usar ante isquemia critica u osteomielitis no controlada."
      ]),
  Tratamiento(
      id: "boca_mucos",
      nombre: "Mucositis Oral (Oncologia, Apoyo)",
      zona: "Boca",
      descripcion: "Mucositis por quimio/radioterapia como coadyuvante.",
      sintomas: "Dolor oral, ulceras y sensibilidad al comer.",
      posicion: "15-25cm extraoral (labios/mejillas), sin calor.",
      frecuencias: [
        {'nm': 630, 'p': 40},
        {'nm': 660, 'p': 40},
        {'nm': 810, 'p': 10},
        {'nm': 830, 'p': 10},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: [
        "Uso solo como apoyo al protocolo oncologico.",
        "No aplicar sobre sangrado activo no controlado."
      ]),

  // ESTETICA
  Tratamiento(
      id: "fat_front",
      nombre: "Grasa Abdomen Frontal",
      zona: "Abdomen",
      descripcion: "Protocolo estetico corporal coadyuvante.",
      sintomas: "Adiposidad abdominal localizada.",
      posicion: "5-15cm sobre abdomen frontal.",
      frecuencias: [
        {'nm': 630, 'p': 70},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: [
        "No usar en embarazo o hernia abdominal.",
        "No usar sobre cancer activo local."
      ]),
  Tratamiento(
      id: "face_rejuv",
      nombre: "Facial Rejuvenecimiento",
      zona: "Cara",
      descripcion: "Fotoenvejecimiento y arruga fina.",
      sintomas: "Piel apagada o lineas finas.",
      posicion: "20-30cm frente al rostro con gafas.",
      frecuencias: [
        {'nm': 630, 'p': 40},
        {'nm': 660, 'p': 50},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 10}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar con dermatitis activa o fotosensibilidad marcada."]),
  Tratamiento(
      id: "anti_cuello",
      nombre: "Antiaging Cuello",
      zona: "Piel",
      descripcion: "Coadyuvante para fotoenvejecimiento en cuello.",
      sintomas: "Flacidez y lineas finas cervicales.",
      posicion: "20-30cm sobre cuello anterior y lateral, evitando tiroides directa.",
      frecuencias: [
        {'nm': 630, 'p': 45},
        {'nm': 660, 'p': 45},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 10}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["Evitar irradiacion directa sobre glandula tiroidea."]),
  Tratamiento(
      id: "anti_manos",
      nombre: "Antiaging Manos",
      zona: "Mano",
      descripcion: "Coadyuvante en fotoenvejecimiento dorsal de manos.",
      sintomas: "Textura irregular y signos de edad en dorso de manos.",
      posicion: "15-25cm sobre dorso de manos.",
      frecuencias: [
        {'nm': 630, 'p': 45},
        {'nm': 660, 'p': 45},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 10}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar sobre lesiones cutaneas activas no evaluadas."]),

  // SISTEMICO
  Tratamiento(
      id: "testo",
      nombre: "Testosterona",
      zona: "Cuerpo",
      descripcion: "Uso experimental, evidencia baja.",
      sintomas: "Objetivo hormonal experimental.",
      posicion: "20-30cm, protocolo experimental.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 15},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "4",
      prohibidos: [
        "No usar en cancer testicular o prostatico.",
        "No recomendado sin seguimiento medico."
      ]),
  Tratamiento(
      id: "sueno",
      nombre: "Sueno / Melatonina",
      zona: "Cuerpo",
      descripcion: "Higiene de sueno y relajacion nocturna.",
      sintomas: "Dificultad para desconectar al final del dia.",
      posicion: "30-50cm luz indirecta por la noche.",
      frecuencias: [
        {'nm': 630, 'p': 60},
        {'nm': 660, 'p': 40},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: [
        "No usar por la manana.",
        "Precaucion en trastorno bipolar no controlado."
      ]),
  Tratamiento(
      id: "sis_energ",
      nombre: "Energia Sistemica",
      zona: "Cuerpo",
      descripcion: "Coadyuvante para fatiga inespecifica.",
      sintomas: "Sensacion de baja energia.",
      posicion: "15-30cm sobre torso o grupos musculares grandes.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No sustituye estudio medico de fatiga persistente."]),
  Tratamiento(
      id: "sis_circ",
      nombre: "Circulacion",
      zona: "Cuerpo",
      descripcion: "Coadyuvante en sensacion de mala perfusion.",
      sintomas: "Piernas cansadas o frias.",
      posicion: "15-30cm en grupos musculares grandes.",
      frecuencias: [
        {'nm': 630, 'p': 10},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["No usar si hay sospecha de TVP o isquemia critica."]),

  // CABEZA
  Tratamiento(
      id: "cab_migr",
      nombre: "Migrana",
      zona: "Cabeza",
      descripcion: "Coadyuvante en migrana/tensional.",
      sintomas: "Dolor de cabeza recurrente.",
      posicion: "15-25cm en nuca o frontal, evitando ojos.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 30},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 30}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: [
        "No usar en epilepsia fotosensible.",
        "Evaluar aura atipica de nueva aparicion."
      ]),
  Tratamiento(
      id: "cab_brain",
      nombre: "Salud Cerebral",
      zona: "Cabeza",
      descripcion: "Uso experimental para cognicion/sueno.",
      sintomas: "Niebla mental o objetivo cognitivo.",
      posicion: "20-30cm frontal, siempre con gafas.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 0},
        {'nm': 810, 'p': 60},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar en epilepsia fotosensible.", "Uso experimental en cognicion."]),

  // RECUPERACION / RENDIMIENTO / SESION (NUEVOS)
  Tratamiento(
      id: "rec_gluteo_post",
      nombre: "Recuperacion Gluteos/Isquios (Post)",
      zona: "Cadera",
      descripcion: "Recuperacion post-entreno en cadena posterior.",
      sintomas: "Fatiga en gluteos e isquios tras fuerza o WOD.",
      posicion: "10-20cm sobre gluteo mayor e isquios.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 15},
        {'nm': 810, 'p': 35},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar sobre desgarro muscular agudo severo."]),
  Tratamiento(
      id: "rec_gemelos_post",
      nombre: "Recuperacion Gemelos/Tobillo (Post)",
      zona: "Pierna",
      descripcion: "Recuperacion de musculatura distal tras carrera o salto.",
      sintomas: "Carga en gemelos y fatiga distal.",
      posicion: "10-20cm sobre gemelos y region aquilea distal.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 15},
        {'nm': 810, 'p': 35},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay sospecha de rotura aquilea o trombosis."]),
  Tratamiento(
      id: "perf_prime",
      nombre: "Activacion Pre-entreno (Prime Movers)",
      zona: "Cuerpo",
      descripcion: "Activacion breve previa de musculos motores principales.",
      sintomas: "Preparacion neuromuscular antes de sesion intensa.",
      posicion: "10-20cm sobre cuadriceps, gluteos, dorsales o pectoral.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No reemplaza calentamiento dinamico."]),
  Tratamiento(
      id: "perf_stab",
      nombre: "Activacion Estabilizadores (Core/Escapula)",
      zona: "Espalda",
      descripcion: "Activacion de estabilizadores articulares antes de entrenar.",
      sintomas: "Necesidad de control postural en push/pull.",
      posicion: "10-20cm paravertebral y region escapular.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No usar si hay dolor agudo neurologico no evaluado."]),
  Tratamiento(
      id: "perf_transfer",
      nombre: "Activacion Transferencia de Fuerza (Cadera/Escapula)",
      zona: "Cadera",
      descripcion: "Activacion pre-sesion de zonas de transferencia de fuerza.",
      sintomas: "Objetivo de rendimiento tecnico en patrones complejos.",
      posicion: "10-20cm sobre cadera lateral y control escapular.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No sustituye trabajo tecnico del patron de movimiento."]),
  Tratamiento(
      id: "ses_pierna",
      nombre: "Dia Pierna (Cuadriceps + Gluteos)",
      zona: "Pierna",
      descripcion: "Protocolo pre-entreno para dia de pierna.",
      sintomas: "Preparacion de tren inferior dominante de rodilla/cadera.",
      posicion: "10-20cm sobre cuadriceps y gluteos.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No reemplaza movilidad ni series de aproximacion."]),
  Tratamiento(
      id: "ses_tiron",
      nombre: "Dia Tiron (Dorsales + Espalda Media)",
      zona: "Espalda",
      descripcion: "Protocolo pre-entreno para sesion pull.",
      sintomas: "Preparacion de dorsales, romboides y biceps.",
      posicion: "10-20cm en dorsales y zona escapular.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No sustituye activacion escapular ni tecnica de tiron."]),
  Tratamiento(
      id: "ses_empuje",
      nombre: "Dia Empuje (Pecho + Hombro)",
      zona: "Hombro",
      descripcion: "Protocolo pre-entreno para sesion push.",
      sintomas: "Preparacion de pectoral, deltoides anterior y triceps.",
      posicion: "10-20cm sobre pectoral y hombro anterior.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No sustituye calentamiento progresivo del hombro."]),
  Tratamiento(
      id: "ses_wod",
      nombre: "WOD Crossfit (Cadera + Dorsales)",
      zona: "Cuerpo",
      descripcion: "Protocolo pre-WOD para patrones de potencia y tiron.",
      sintomas: "Preparacion de cadena posterior y traccion.",
      posicion: "10-20cm en cadera posterior y dorsales.",
      frecuencias: [
        {'nm': 630, 'p': 0},
        {'nm': 660, 'p': 10},
        {'nm': 810, 'p': 45},
        {'nm': 830, 'p': 25},
        {'nm': 850, 'p': 20}
      ],
      hz: "CW",
      duracion: "8",
      prohibidos: ["No reemplaza calentamiento especifico del WOD."]),

  // GRASA LOCALIZADA (NUEVOS)
  Tratamiento(
      id: "fat_abd_low",
      nombre: "Grasa Abdomen Bajo",
      zona: "Abdomen",
      descripcion: "Coadyuvante en adiposidad subcutanea infraumbilical.",
      sintomas: "Acumulo graso en abdomen inferior.",
      posicion: "5-15cm sobre abdomen bajo.",
      frecuencias: [
        {'nm': 630, 'p': 70},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["No usar en embarazo o hernia abdominal."]),
  Tratamiento(
      id: "fat_flancos",
      nombre: "Grasa Flancos",
      zona: "Abdomen",
      descripcion: "Coadyuvante en adiposidad subcutanea lateral.",
      sintomas: "Acumulo graso en cintura lateral.",
      posicion: "5-15cm sobre flancos bilaterales.",
      frecuencias: [
        {'nm': 630, 'p': 70},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["No usar sobre neoplasia activa local."]),
  Tratamiento(
      id: "fat_caderas",
      nombre: "Grasa Caderas",
      zona: "Cadera",
      descripcion: "Coadyuvante en adiposidad gluteofemoral lateral.",
      sintomas: "Deposito adiposo en cadera lateral.",
      posicion: "5-15cm sobre caderas bilaterales.",
      frecuencias: [
        {'nm': 630, 'p': 70},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["No usar en embarazo."]),
  Tratamiento(
      id: "fat_muslo_ext",
      nombre: "Grasa Muslo Externo",
      zona: "Pierna",
      descripcion: "Coadyuvante en adiposidad lateral de muslo.",
      sintomas: "Acumulo adiposo subcutaneo en muslo externo.",
      posicion: "5-15cm sobre muslo externo bilateral.",
      frecuencias: [
        {'nm': 630, 'p': 70},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["No usar sobre hematoma activo o lesion muscular aguda."]),
  Tratamiento(
      id: "fat_lumbar_low",
      nombre: "Grasa Lumbar Baja",
      zona: "Espalda",
      descripcion: "Coadyuvante en adiposidad lumbar posterior.",
      sintomas: "Acumulo adiposo en zona lumbar baja.",
      posicion: "5-15cm en region lumbar baja.",
      frecuencias: [
        {'nm': 630, 'p': 70},
        {'nm': 660, 'p': 30},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 0}
      ],
      hz: "CW",
      duracion: "18",
      prohibidos: ["No usar sobre lesiones cutaneas activas."]),

  // DOLOR / LESION (NUEVOS)
  Tratamiento(
      id: "mio_trigger",
      nombre: "Puntos Gatillo Miofasciales",
      zona: "Espalda",
      descripcion: "Coadyuvante en puntos gatillo y dolor miofascial.",
      sintomas: "Dolor localizado con banda tensa palpable.",
      posicion: "5-10cm sobre punto gatillo, sin presion directa excesiva.",
      frecuencias: [
        {'nm': 630, 'p': 5},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 30},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar sobre infeccion cutanea activa."]),
  Tratamiento(
      id: "trap_contract",
      nombre: "Contractura Trapecio/Lumbar",
      zona: "Espalda",
      descripcion: "Sobrecarga muscular localizada en trapecio o lumbar.",
      sintomas: "Rigidez y dolor postural.",
      posicion: "10-20cm sobre zona contracturada.",
      frecuencias: [
        {'nm': 630, 'p': 5},
        {'nm': 660, 'p': 20},
        {'nm': 810, 'p': 30},
        {'nm': 830, 'p': 20},
        {'nm': 850, 'p': 25}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay fiebre o dolor de origen visceral no aclarado."]),

  // PIEL / ANTIAGING / CICATRIZ (NUEVOS)
  Tratamiento(
      id: "piel_estrias",
      nombre: "Estrias (Apoyo)",
      zona: "Piel",
      descripcion: "Coadyuvante estetico en estrias recientes o antiguas.",
      sintomas: "Alteracion de textura y color por distension cutanea.",
      posicion: "15-25cm sobre zona con estrias.",
      frecuencias: [
        {'nm': 630, 'p': 45},
        {'nm': 660, 'p': 45},
        {'nm': 810, 'p': 0},
        {'nm': 830, 'p': 0},
        {'nm': 850, 'p': 10}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["Evidencia clinica limitada en estrias; usar expectativas realistas."]),
  Tratamiento(
      id: "piel_cicat_rec",
      nombre: "Cicatriz Reciente (Cerrada)",
      zona: "Piel",
      descripcion: "Coadyuvante en remodelacion temprana de cicatriz cerrada.",
      sintomas: "Eritema o rigidez leve post-cierre.",
      posicion: "15-25cm sobre cicatriz cerrada no infectada.",
      frecuencias: [
        {'nm': 630, 'p': 35},
        {'nm': 660, 'p': 45},
        {'nm': 810, 'p': 10},
        {'nm': 830, 'p': 5},
        {'nm': 850, 'p': 5}
      ],
      hz: "CW",
      duracion: "10",
      prohibidos: ["No usar en herida abierta o con signos de infeccion."]),
  Tratamiento(
      id: "piel_fibrosis",
      nombre: "Cicatriz Antigua/Fibrosis (Apoyo)",
      zona: "Piel",
      descripcion: "Coadyuvante en fibrosis cicatricial cronica.",
      sintomas: "Rigidez, retraccion o baja elasticidad local.",
      posicion: "10-20cm sobre banda fibrotica.",
      frecuencias: [
        {'nm': 630, 'p': 25},
        {'nm': 660, 'p': 35},
        {'nm': 810, 'p': 20},
        {'nm': 830, 'p': 10},
        {'nm': 850, 'p': 10}
      ],
      hz: "CW",
      duracion: "12",
      prohibidos: ["No usar si hay sospecha de queloide activo inflamado."]),
];

const Map<String, List<String>> _clasificacionTratamientos = {
  // 1. Recuperacion muscular
  "pierna_fem": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.2.3 Lower Knee-dominant",
    "Muslo (cuadriceps + rodilla)"
  ],
  "rec_gluteo_post": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.2.4 Lower Hip-dominant",
    "Gluteos / isquios / lumbar baja"
  ],
  "rec_gemelos_post": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.2.5 Lower Distal",
    "Gemelos / tobillo / fascia plantar"
  ],
  "ant_sobre": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.1.3 Musculos accesorios / fatiga localizada",
    "Antebrazos"
  ],
  "esp_dors": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.2.2 Upper Pull",
    "Dorsales / espalda media-alta"
  ],
  "esp_lumb": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.1.2 Estabilizadores y postural",
    "Lumbar / core"
  ],
  "sueno": [
    "1 Recuperacion muscular (post entreno / crossfit / gym)",
    "1.1.2 Estabilizadores y postural",
    "Recuperacion neurovegetativa (sueno)"
  ],

  // 2. Rendimiento deportivo
  "perf_prime": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1.1 Musculos motores principales (prime movers)",
    "Cuadriceps / gluteos / dorsales / pectoral"
  ],
  "perf_stab": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1.2 Estabilizadores articulares",
    "Manguito / core / erectores espinales"
  ],
  "perf_transfer": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1.3 Zonas de transferencia de fuerza",
    "Cadera / escapulas"
  ],
  "sis_energ": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1.1 Musculos motores principales (prime movers)",
    "Activacion sistemica previa"
  ],
  "cab_brain": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1.2 Estabilizadores articulares",
    "Activacion cognitiva (experimental)"
  ],
  "testo": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1.1 Musculos motores principales (prime movers)",
    "Objetivo hormonal (experimental)"
  ],

  // Sesion por tipo integrada en 2. Rendimiento deportivo
  "ses_pierna": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1 Musculos motores principales (prime movers)",
    "Cuadriceps + gluteos"
  ],
  "ses_tiron": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1 Musculos motores principales (prime movers)",
    "Dorsales + espalda media"
  ],
  "ses_empuje": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.1 Musculos motores principales (prime movers)",
    "Pecho + hombro"
  ],
  "ses_wod": [
    "2 Rendimiento deportivo (antes de entrenar)",
    "2.3 Zonas de transferencia de fuerza",
    "Cadera + dorsales"
  ],

  // 4. Grasa localizada
  "fat_front": [
    "4 Grasa localizada / metabolismo local",
    "4.2.1 Abdomen bajo",
    "Abdomen frontal"
  ],
  "fat_abd_low": [
    "4 Grasa localizada / metabolismo local",
    "4.2.1 Abdomen bajo",
    "Abdomen infraumbilical"
  ],
  "fat_flancos": [
    "4 Grasa localizada / metabolismo local",
    "4.2.2 Flancos",
    "Cintura lateral"
  ],
  "fat_caderas": [
    "4 Grasa localizada / metabolismo local",
    "4.2.3 Caderas",
    "Cadera lateral"
  ],
  "fat_muslo_ext": [
    "4 Grasa localizada / metabolismo local",
    "4.2.4 Muslo externo",
    "Muslo lateral"
  ],
  "fat_lumbar_low": [
    "4 Grasa localizada / metabolismo local",
    "4.2.5 Zona lumbar baja",
    "Lumbar posterior"
  ],
  "sis_circ": [
    "4 Grasa localizada / metabolismo local",
    "4.1.2 Zonas con peor perfusion",
    "Perfusion periferica"
  ],

  // 5. Dolor / lesion
  "codo_epi": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Codo lateral (epicondilo)"
  ],
  "codo_golf": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Codo medial (epitroclea)"
  ],
  "codo_calc": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Calcificacion tendinosa"
  ],
  "codo_bur": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "Codo / bursa"
  ],
  "ant_tend": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Tendones de antebrazo"
  ],
  "mun_tunel": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "Muneca / tunel carpiano"
  ],
  "mun_art": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "Muneca articular"
  ],
  "pierna_itb": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.3 Sobrecarga muscular localizada",
    "Cintilla iliotibial"
  ],
  "pie_fasc": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Fascia plantar"
  ],
  "pie_esg": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "Tobillo / esguince"
  ],
  "pie_lat": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.3 Sobrecarga muscular localizada",
    "Pie lateral / metatarso"
  ],
  "homb_tend": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Manguito rotador"
  ],
  "homb_supra": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Supraespinoso"
  ],
  "rod_gen": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "Rodilla general / menisco"
  ],
  "rod_pfps": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "Rodilla patelofemoral"
  ],
  "rod_rotul": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Tendon rotuliano"
  ],
  "tob_aquiles": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.2 Tendinopatias",
    "Tendon de Aquiles"
  ],
  "esp_cerv": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.3 Sobrecarga muscular localizada",
    "Cervical / trapecio"
  ],
  "mio_trigger": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.4 Puntos gatillo / contracturas",
    "Puntos miofasciales"
  ],
  "trap_contract": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.4 Puntos gatillo / contracturas",
    "Trapecio / lumbar"
  ],
  "cara_atm": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.1.1 Dolor articular",
    "ATM / masetero"
  ],
  "cab_migr": [
    "5 Dolor / lesion (articular, tendones, sobrecargas)",
    "5.2.3 Profundo (articulacion, inserciones)",
    "Cefalea / migrana"
  ],

  // 6. Piel / antiaging / cicatrices
  "face_rejuv": [
    "6 Piel / antiaging / cicatrices",
    "6.2.1 Cara",
    "6.1.1 Antiaging / colageno"
  ],
  "anti_cuello": [
    "6 Piel / antiaging / cicatrices",
    "6.2.2 Cuello",
    "6.1.1 Antiaging / colageno"
  ],
  "anti_manos": [
    "6 Piel / antiaging / cicatrices",
    "6.2.3 Manos",
    "6.1.1 Antiaging / colageno"
  ],
  "piel_acne": [
    "6 Piel / antiaging / cicatrices",
    "6.2.1 Cara",
    "6.1.4 Acne / inflamacion cutanea"
  ],
  "piel_cicat": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.3 Cicatrices antiguas / fibrosis"
  ],
  "piel_cicat_rec": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.2 Cicatrices recientes"
  ],
  "piel_fibrosis": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.3 Cicatrices antiguas / fibrosis"
  ],
  "piel_estrias": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.5 Estrias"
  ],
  "piel_quem": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.2 Cicatrices recientes"
  ],
  "pie_ulc": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.2 Cicatrices recientes"
  ],
  "boca_mucos": [
    "6 Piel / antiaging / cicatrices",
    "6.2.4 Zonas con cicatriz especifica",
    "6.1.4 Acne / inflamacion cutanea"
  ],
};

String _zonaClasificadaPorId(String id) {
  final c = _clasificacionTratamientos[id];
  if (c == null) {
    return "5 Dolor / lesion (articular, tendones, sobrecargas) > 5.1.3 Sobrecarga muscular localizada > General";
  }
  return "${c[0]} > ${c[1]} > ${c[2]}";
}

int _compararCatalogo(Tratamiento a, Tratamiento b) {
  final byZona = a.zona.compareTo(b.zona);
  if (byZona != 0) return byZona;
  return a.nombre.compareTo(b.nombre);
}

const Set<String> _idsTendinopatia = {
  "codo_epi",
  "codo_golf",
  "codo_calc",
  "ant_tend",
  "pierna_itb",
  "pie_fasc",
  "homb_tend",
  "homb_supra",
  "rod_rotul",
  "tob_aquiles",
};

const Set<String> _idsDolorMuscular = {
  "codo_bur",
  "esp_cerv",
  "esp_dors",
  "esp_lumb",
  "ant_sobre",
  "pierna_fem",
  "pie_esg",
  "pie_lat",
  "sis_energ",
  "sis_circ",
  "rec_gluteo_post",
  "rec_gemelos_post",
  "mio_trigger",
  "trap_contract",
};

const Set<String> _idsRecuperacionPost = {
  "pierna_fem",
  "ant_sobre",
  "esp_dors",
  "esp_lumb",
  "rec_gluteo_post",
  "rec_gemelos_post",
};
const Set<String> _idsRendimientoPre = {"perf_prime", "perf_stab", "perf_transfer", "sis_energ"};
const Set<String> _idsSesionTipo = {"ses_pierna", "ses_tiron", "ses_empuje", "ses_wod"};
const Set<String> _idsGrasaLocalizada = {
  "fat_front",
  "fat_abd_low",
  "fat_flancos",
  "fat_caderas",
  "fat_muslo_ext",
  "fat_lumbar_low",
};
const Set<String> _idsTriggerContractura = {"mio_trigger", "trap_contract"};

const Set<String> _idsRodilla = {"rod_gen", "rod_pfps"};
const Set<String> _idsCefalea = {"cab_migr"};
const Set<String> _idsNeuroExperimental = {"cab_brain"};
const Set<String> _idsPielRegenerativa = {
  "piel_cicat",
  "piel_cicat_rec",
  "piel_fibrosis",
  "piel_quem",
  "pie_ulc"
};
const Set<String> _idsPielEstetica = {"face_rejuv", "anti_cuello", "anti_manos", "piel_acne"};
const Set<String> _idsEstrias = {"piel_estrias"};
const Set<String> _idsPulso10 = {
  "codo_epi",
  "codo_golf",
  "codo_bur",
  "pie_esg",
  "cab_migr",
  "cara_atm",
  "tob_aquiles",
};

const List<Map<String, int>> _mixDeepTendon = [
  {'nm': 630, 'p': 0},
  {'nm': 660, 'p': 15},
  {'nm': 810, 'p': 35},
  {'nm': 830, 'p': 25},
  {'nm': 850, 'p': 25},
];

const List<Map<String, int>> _mixDolorMuscular = [
  {'nm': 630, 'p': 5},
  {'nm': 660, 'p': 15},
  {'nm': 810, 'p': 30},
  {'nm': 830, 'p': 25},
  {'nm': 850, 'p': 25},
];

const List<Map<String, int>> _mixRodilla = [
  {'nm': 630, 'p': 0},
  {'nm': 660, 'p': 15},
  {'nm': 810, 'p': 35},
  {'nm': 830, 'p': 20},
  {'nm': 850, 'p': 30},
];

const List<Map<String, int>> _mixTunelCarpiano = [
  {'nm': 630, 'p': 0},
  {'nm': 660, 'p': 10},
  {'nm': 810, 'p': 40},
  {'nm': 830, 'p': 20},
  {'nm': 850, 'p': 30},
];

const List<Map<String, int>> _mixCefalea = [
  {'nm': 630, 'p': 0},
  {'nm': 660, 'p': 15},
  {'nm': 810, 'p': 40},
  {'nm': 830, 'p': 20},
  {'nm': 850, 'p': 25},
];

const List<Map<String, int>> _mixNeuroExperimental = [
  {'nm': 630, 'p': 0},
  {'nm': 660, 'p': 0},
  {'nm': 810, 'p': 70},
  {'nm': 830, 'p': 20},
  {'nm': 850, 'p': 10},
];

const List<Map<String, int>> _mixSueno = [
  {'nm': 630, 'p': 60},
  {'nm': 660, 'p': 40},
  {'nm': 810, 'p': 0},
  {'nm': 830, 'p': 0},
  {'nm': 850, 'p': 0},
];

const List<Map<String, int>> _mixPielRegenerativa = [
  {'nm': 630, 'p': 35},
  {'nm': 660, 'p': 35},
  {'nm': 810, 'p': 10},
  {'nm': 830, 'p': 10},
  {'nm': 850, 'p': 10},
];

List<Map<String, dynamic>> _copyFrecuencias(List<Map<String, int>> source) {
  return source.map((f) => {'nm': f['nm'], 'p': f['p']}).toList();
}

List<String> _mergeUniqueStrings(List<String> base, List<String> extra) {
  final out = List<String>.from(base);
  for (final e in extra) {
    if (e.trim().isEmpty) continue;
    if (!out.contains(e)) out.add(e);
  }
  return out;
}

List<String> _tipsAntesCientificosPorId(String id) {
  if (_idsRendimientoPre.contains(id) || _idsSesionTipo.contains(id)) {
    return ["Dosimetria objetivo pre-sesion: 3-6 J por punto, aplicar 5-10 min antes del esfuerzo."];
  }
  if (_idsRecuperacionPost.contains(id)) {
    return ["Dosimetria objetivo post-sesion: 6-12 J por zona (20-100 mW/cm2), progresar segun tolerancia."];
  }
  if (_idsGrasaLocalizada.contains(id)) {
    return ["Uso coadyuvante: combinar con entrenamiento y control nutricional para respuesta metabolica local."];
  }
  if (_idsTriggerContractura.contains(id)) {
    return ["Aplicar en puntos dolorosos 4-8 J por punto y reevaluar sensibilidad 24-48h."];
  }
  if (_idsEstrias.contains(id)) {
    return ["Evidencia clinica limitada en estrias; usar con expectativas conservadoras."];
  }
  if (_idsTendinopatia.contains(id)) {
    return [
      "Dosimetria objetivo: 4-8 J por punto doloroso (20-100 mW/cm2), priorizando 810/830/850nm."
    ];
  }
  if (_idsDolorMuscular.contains(id) || _idsRodilla.contains(id)) {
    return ["Dosimetria objetivo: 6-12 J por zona (20-100 mW/cm2), progresar segun tolerancia."];
  }
  if (id == "mun_tunel") {
    return ["Dosimetria objetivo: 4-8 J por punto sobre tunel carpiano, protocolo conservador."];
  }
  if (_idsPielRegenerativa.contains(id) || id == "boca_mucos") {
    return ["Dosimetria objetivo: 2-6 J/cm2 (irradiancia baja, sin calor en tejido lesionado)."];
  }
  if (_idsPielEstetica.contains(id)) {
    return ["Dosimetria objetivo: 4-10 J/cm2 en piel superficial, 2-4 sesiones/semana."];
  }
  if (_idsNeuroExperimental.contains(id) || _idsCefalea.contains(id)) {
    return ["Iniciar con dosis bajas (8-10 min) y aumentar solo si no hay cefalea o agitacion post-sesion."];
  }
  if (id == "sueno") {
    return ["Aplicar por la noche (60-120 min antes de dormir), evitando luz azul intensa posterior."];
  }
  if (id == "fat_front") {
    return ["Evidencia estetica: usar como coadyuvante junto a dieta/ejercicio; no reemplaza control calorico."];
  }
  return [];
}

List<String> _tipsDespuesCientificosPorId(String id) {
  if (_idsRendimientoPre.contains(id) || _idsSesionTipo.contains(id)) {
    return [
      "Fuente: PubMed PMID:35802348 (meta-analisis PBM pre-ejercicio y rendimiento).",
      "Fuente: PubMed PMID:39883205 (revision 2025 sobre PBM en rendimiento deportivo).",
      "Fuente: PubMed PMID:38781474 (meta-analisis de ejercicio/resistencia; busqueda en Cochrane, CINAHL, EMBASE, Web of Science y MEDLINE).",
    ];
  }
  if (_idsRecuperacionPost.contains(id)) {
    return [
      "Fuente: PubMed PMID:38150056 (meta-analisis PBM en dano muscular y recuperacion de fuerza).",
      "Fuente: PubMed PMID:40700213 (review 2025 PBM y DOMS/recuperacion).",
      "Fuente: PubMed PMID:38759478 (J Photochemistry and Photobiology B; revisión dosimétrica en musculoesqueletico).",
    ];
  }
  if (_idsGrasaLocalizada.contains(id)) {
    return [
      "Fuente: PubMed PMID:20014253 (ensayo clinico 635nm en contorno corporal).",
      "Fuente: PubMed PMID:20393809 (spot fat reduction trial).",
      "Fuente: PubMed PMID:41423522 (revision sistematica 2025 sobre LLLT en circunferencia corporal).",
    ];
  }
  if (_idsTriggerContractura.contains(id)) {
    return [
      "Fuente: PubMed PMID:35962884 (meta-analisis dolor miofascial cervical con LLLT).",
      "Fuente: PubMed PMID:19913903 (meta-analisis dolor cervical cronico).",
    ];
  }
  if (_idsEstrias.contains(id)) {
    return [
      "Fuente: evidencia clinica directa limitada para PBM en estrias; extrapolacion de protocolos de remodelacion dermica.",
    ];
  }
  if (_idsPielEstetica.contains(id) && id != "piel_acne") {
    return [
      "Fuente: PubMed PMID:36780572 (RCT rejuvenecimiento facial LED/PBM).",
      "Fuente: PubMed PMID:32427553 (Photobiomodulation, Photomedicine, and Laser Surgery; rejuvenecimiento piel).",
      "Fuente: Journal of Biophotonics 2018;11:e201700355 (PBM 650/830/850nm en rejuvenecimiento).",
    ];
  }
  if (_idsTendinopatia.contains(id)) {
    return [
      "Fuente: PubMed PMID:36171024 (meta-analisis en tendinopatia de miembro inferior y fascitis plantar).",
      "Fuente: PubMed PMID:34391447 (meta-analisis tendinopatias; busqueda en PubMed, EMBASE, CINAHL, SCOPUS y Cochrane).",
      "Fuente: PubMed PMID:37288499 (Lasers in Surgery and Medicine; dolor y funcion en tendinopatia).",
      "Fuente: WALT PBM Recommendations (tendinopathy dosimetry, 780-860nm).",
    ];
  }
  if (id == "esp_cerv" || id == "esp_dors") {
    return ["Fuente: PubMed PMID:19913903 (meta-analisis dolor cervical)."];
  }
  if (id == "esp_lumb") {
    return ["Fuente: PubMed PMID:27207675 (meta-analisis lumbalgia cronica)."];
  }
  if (_idsDolorMuscular.contains(id) &&
      id != "esp_cerv" &&
      id != "esp_dors" &&
      id != "esp_lumb" &&
      id != "sis_energ" &&
      id != "sis_circ") {
    return [
      "Fuente: WALT PBM Recommendations (dolor musculoesqueletico, dosimetria conservadora).",
      "Fuente: PubMed PMID:27207675 (soporte indirecto de analgesia en dolor musculoesqueletico).",
      "Fuente: Clinical Rehabilitation 2022;36(10):1293-1305 (PMID:35918813; LLLT en dolor lumbar cronico).",
    ];
  }
  if (_idsRodilla.contains(id)) {
    return [
      "Fuente: PubMed PMID:38775202 (knee OA, metanalisis 2024).",
      "Fuente: PubMed PMID:41517270 (J Photochemistry and Photobiology B; busqueda en PubMed, Scopus, ScienceDirect, CENTRAL y Google Scholar; PMCID: PMC12786645).",
    ];
  }
  if (id == "mun_tunel") {
    return [
      "Fuente: PubMed PMID:35611937 (Cochrane review sindrome tunel carpiano).",
      "Fuente: PubMed PMID:39776290 (meta-analisis 2025; busqueda en PubMed, EMBASE, Scopus, CINAHL, Cochrane y Google Scholar).",
      "Fuente: Journal of Clinical Laser Medicine & Surgery 1998;16(3):143-151 (PMID:9743652).",
    ];
  }
  if (id == "mun_art") {
    return ["Fuente: WALT PBM Recommendations (articulaciones perifericas, recomendacion por dosis)."];
  }
  if (id == "cara_atm") {
    return [
      "Fuente: PubMed PMID:39225295 (meta-analisis LLLT en trastorno temporomandibular).",
      "Fuente: WALT PBM Recommendations (temporomandibular dosimetry).",
    ];
  }
  if (id == "piel_cicat") {
    return ["Fuente: PubMed PMID:36045183 (830nm para prevencion de cicatriz)."];
  }
  if (id == "piel_acne") {
    return [
      "Fuente: PubMed PMID:10809858 (RCT blue-red light en acne).",
      "Fuente: PubMed PMID:34696155 (revision sistematica acne, luz visible).",
    ];
  }
  if (id == "piel_quem" || id == "pie_ulc") {
    return ["Fuente: PubMed PMID:39172550 (revision/meta PBM en cicatrizacion de heridas y quemaduras)."];
  }
  if (id == "boca_mucos") {
    return [
      "Fuente: PubMed PMID:34742930 (meta-analisis PBM para mucositis oral por cancer).",
      "Fuente: PubMed PMID:37853254 (revision 2024; busqueda en MEDLINE, LILACS, EMBASE, Cochrane, Scopus, CINAHL y ClinicalTrials.gov).",
    ];
  }
  if (id == "fat_front") {
    return [
      "Fuente: PubMed PMID:20014253 (635nm body contouring trial).",
      "Fuente: PubMed PMID:20393809 (spot fat reduction trial).",
    ];
  }
  if (id == "sis_energ" || id == "sis_circ") {
    return [
      "Fuente: PubMed PMID:32064652 (microcirculacion, ensayo en humanos).",
      "Fuente: PubMed PMID:37072603 (funcion endotelial, ensayo clinico).",
    ];
  }
  if (id == "testo") {
    return [
      "Fuente: PubMed PMID:38028870 (fertilidad masculina/LLLT; evidencia indirecta para objetivo hormonal).",
    ];
  }
  if (id == "sueno") {
    return ["Fuente: PubMed PMID:41125953 (insomnio, RCT con PBM)."];
  }
  if (id == "cab_migr") {
    return [
      "Fuente: PubMed PMID:35054491 (revision sistematica cefalea primaria).",
      "Fuente: PubMed PMID:39198866 (piloto RCT migrana cronica).",
    ];
  }
  if (id == "cab_brain") {
    return [
      "Fuente: PubMed PMID:36371017 (revision sistematica tPBM cognicion).",
      "Fuente: PubMed PMID:38849495 (Journal of NeuroEngineering and Rehabilitation; revision clinica tPBM).",
      "Fuente: PubMed PMID:40437278 (meta-analisis 2025, tPBM en deterioro cognitivo; PMCID: PMC12199797).",
      "Fuente: ClinicalTrials.gov NCT06757374 (tPBM en deterioro cognitivo, en curso).",
      "Fuente: ClinicalTrials.gov NCT04619121 (tPBM para disfuncion cognitiva, completado).",
    ];
  }
  return [];
}

List<String> _fuentesMultibasePorId(String id) {
  final common = <String>[
    "Rastreo multibase: PubMed (NCBI E-utilities), Europe PMC y PMCID en PubMed Central, Cochrane Library/CENTRAL, EMBASE, CINAHL, Scopus, ScienceDirect, Google Scholar y Semantic Scholar.",
    "Revistas priorizadas: Photobiomodulation, Photomedicine, and Laser Surgery; Lasers in Medical Science; Lasers in Surgery and Medicine; Journal of Biophotonics; Journal of Photochemistry and Photobiology B; Journal of Clinical Laser Medicine & Surgery; Journal of NeuroEngineering and Rehabilitation; Clinical Rehabilitation.",
  ];
  if (_idsNeuroExperimental.contains(id) || id == "testo") {
    common.add("ClinicalTrials.gov y preprints (bioRxiv/arXiv) se usan como evidencia preliminar, no para fijar dosis definitivas.");
  }
  return common;
}

List<String> _prohibidosExtraPorId(String id) {
  final extra = <String>["No irradiar ojos directamente; usar gafas de proteccion."];
  if (id == "testo" || id == "cab_brain" || id == "sueno") {
    extra.add("Evidencia clinica aun limitada; usar solo como protocolo complementario.");
  }
  if (id == "pie_ulc" || id == "boca_mucos") {
    extra.add("Usar con seguimiento clinico y control de infeccion.");
  }
  if (_idsCefalea.contains(id) || _idsNeuroExperimental.contains(id)) {
    extra.add("Suspender si aumenta cefalea, fotofobia o insomnio.");
  }
  return extra;
}

Tratamiento _aplicarActualizacionCientifica(Tratamiento t) {
  var hz = t.hz;
  var duracion = t.duracion;
  var frecuencias =
      List<Map<String, dynamic>>.from(t.frecuencias.map((f) => {'nm': f['nm'], 'p': f['p']}));

  if (_idsPulso10.contains(t.id)) hz = "10Hz";
  if (t.id == "cab_brain") hz = "40Hz";

  if (_idsRecuperacionPost.contains(t.id)) frecuencias = _copyFrecuencias(_mixDolorMuscular);
  if (_idsTendinopatia.contains(t.id)) frecuencias = _copyFrecuencias(_mixDeepTendon);
  if (_idsDolorMuscular.contains(t.id)) frecuencias = _copyFrecuencias(_mixDolorMuscular);
  if (_idsRodilla.contains(t.id)) frecuencias = _copyFrecuencias(_mixRodilla);
  if (t.id == "mun_tunel") frecuencias = _copyFrecuencias(_mixTunelCarpiano);
  if (_idsCefalea.contains(t.id)) frecuencias = _copyFrecuencias(_mixCefalea);
  if (t.id == "cab_brain") frecuencias = _copyFrecuencias(_mixNeuroExperimental);
  if (t.id == "sueno") frecuencias = _copyFrecuencias(_mixSueno);
  if (_idsPielRegenerativa.contains(t.id) || t.id == "boca_mucos") {
    frecuencias = _copyFrecuencias(_mixPielRegenerativa);
  }

  if (_idsRodilla.contains(t.id)) duracion = "14";
  if (t.id == "cab_brain" || t.id == "cab_migr") duracion = "10";
  if (t.id == "boca_mucos") duracion = "8";
  if (t.id == "pie_ulc") duracion = "10";
  if (_idsRendimientoPre.contains(t.id) || _idsSesionTipo.contains(t.id)) duracion = "8";
  if (_idsGrasaLocalizada.contains(t.id)) duracion = "18";

  return Tratamiento(
    id: t.id,
    nombre: t.nombre,
    zona: _zonaClasificadaPorId(t.id),
    descripcion: t.descripcion,
    sintomas: t.sintomas,
    posicion: t.posicion,
    hz: hz,
    duracion: duracion,
    frecuencias: frecuencias,
    tipsAntes: _mergeUniqueStrings(t.tipsAntes, _tipsAntesCientificosPorId(t.id)),
    tipsDespues: _mergeUniqueStrings(
        _mergeUniqueStrings(t.tipsDespues, _tipsDespuesCientificosPorId(t.id)),
        _fuentesMultibasePorId(t.id)),
    prohibidos: _mergeUniqueStrings(t.prohibidos, _prohibidosExtraPorId(t.id)),
    esCustom: t.esCustom,
    oculto: t.oculto,
  );
}

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
        catalogo.sort(_compararCatalogo);

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
    for (var base in DB_DEFINICIONES) {
      final t = _aplicarActualizacionCientifica(base);
      if (ZONAS_SIMETRICAS.contains(base.zona)) {
        lista.add(t.copyWith(id: "${t.id}_d", nombre: "${t.nombre} (Dcho)"));
        lista.add(t.copyWith(id: "${t.id}_i", nombre: "${t.nombre} (Izq)"));
      } else {
        lista.add(t);
      }
    }
    lista.sort(_compararCatalogo);
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

  void desregistrarTratamiento(String fecha, String id) {
    if (!historial.containsKey(fecha)) return;
    final registros = historial[fecha]!;
    for (int i = registros.length - 1; i >= 0; i--) {
      if (registros[i]['id'] == id) {
        registros.removeAt(i);
        break;
      }
    }
    if (registros.isEmpty) {
      historial.remove(fecha);
    }
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
    _guardarTodo();
    notifyListeners();
  }

  Future<void> iniciarCiclo(String id) async {
    ciclosActivos[id] = {
      'activo': true,
      'inicio': DateFormat('HH:mm:ss').format(DateTime.now())
    };

    if (isConnected) {
      try {
        final t = catalogo.firstWhere((e) => e.id == id);
        print("BLE: Starting Treatment '${t.nombre}'");
        print("BLE: Params -> duracion=${t.duracion} min, hz='${t.hz}', frecuencias=${t.frecuencias}");

        // Force a clean baseline before applying parameters.
        await _bleManager.write(BleProtocol.setPower(false));
        await Future.delayed(const Duration(milliseconds: 500));

        await _sendParameters(t, workMode: 0);
        // Wake/run handshake for panels that stay idle until explicit power-on.
        await _bleManager.write(BleProtocol.setPower(true));
        await Future.delayed(const Duration(milliseconds: 220));
        await _bleManager.write(BleProtocol.quickStart(mode: 0));
        await Future.delayed(const Duration(milliseconds: 360));

        // Re-apply only values that are commonly ignored before run becomes active.
        await _sendTimeAndPulse(t, phase: "post-start");
        await _sendBrightness(t, phase: "post-start");
        await _readBackRunState(reason: "after iniciarCiclo");
        print("BLE: Configuration sent.");
      } catch (e) {
        print("BLE Error: $e");
      }
    }

    notifyListeners();
  }

  Map<int, int> _brightnessByChannel(Tratamiento t) {
    final values = <int, int>{0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
    for (final f in t.frecuencias) {
      final nm = (f['nm'] as num).toInt();
      final rawP = (f['p'] as num).toInt();
      final p = rawP < 0 ? 0 : (rawP > 100 ? 100 : rawP);
      if (nm == 630) {
        values[0] = p;
      } else if (nm == 660) {
        values[1] = p;
      } else if (nm == 810) {
        values[2] = p;
      } else if (nm == 830) {
        values[3] = p;
      } else if (nm == 850) {
        values[4] = p;
      } else if (nm < 700) {
        values[1] = p;
      } else {
        values[4] = p;
      }
    }
    return values;
  }

  int _pulseFromTratamiento(Tratamiento t) {
    final isCW = t.hz.toUpperCase().contains("CW");
    if (isCW) return 0;
    final match = RegExp(r'(\d+)').firstMatch(t.hz);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  int _durationMinutesFromTratamiento(Tratamiento t) {
    final raw = int.tryParse(t.duracion) ?? 10;
    if (raw < 1) return 1;
    if (raw > 60) return 60;
    return raw;
  }

  Future<void> _sendTimeAndPulse(Tratamiento t, {String phase = ""}) async {
    const commandDelay = Duration(milliseconds: 220);
    final durationMinutes = _durationMinutesFromTratamiento(t);
    final pulseHz = _pulseFromTratamiento(t);
    final phaseLabel = phase.isEmpty ? "" : "[$phase] ";

    print("BLE: ${phaseLabel}Sending Duration: $durationMinutes min");
    await _bleManager.write(BleProtocol.setCountdown(durationMinutes));
    await Future.delayed(commandDelay);

    print("BLE: ${phaseLabel}Sending Pulse: $pulseHz Hz");
    await _bleManager.write(BleProtocol.setPulse(pulseHz));
    await Future.delayed(commandDelay);
  }

  Future<void> _sendBrightness(Tratamiento t, {String phase = ""}) async {
    const dimmingDelay = Duration(milliseconds: 120);
    final brightness = _brightnessByChannel(t);
    final phaseLabel = phase.isEmpty ? "" : "[$phase] ";

    for (final channel in [0, 1, 2, 3, 4]) {
      final value = brightness[channel] ?? 0;
      print("BLE: ${phaseLabel}Dimming Ch$channel -> $value%");
      await _bleManager.write(BleProtocol.setBrightnessChannel(channel, value));
      await Future.delayed(dimmingDelay);
    }
  }

  Future<void> _readBackRunState({String reason = ""}) async {
    const readDelay = Duration(milliseconds: 180);
    final suffix = reason.isEmpty ? "" : " ($reason)";
    print("BLE: Reading state$suffix...");
    await _bleManager.write(BleProtocol.getStatus());
    await Future.delayed(readDelay);
    await _bleManager.write(BleProtocol.getCountdown());
    await Future.delayed(readDelay);
    await _bleManager.write(BleProtocol.getBrightness());
  }

  Future<void> _sendParameters(Tratamiento t, {int workMode = 0}) async {
    const modeDelay = Duration(milliseconds: 200);

    print("BLE: Sending Work Mode: $workMode");
    await _bleManager.write(BleProtocol.setWorkMode(workMode));
    await Future.delayed(modeDelay);

    await _sendBrightness(t);
    await _sendTimeAndPulse(t, phase: "pre-start");
  }

  /// Starts a manual treatment not in the catalog
  /// [sequenceMode]: 0=Params->Start, 1=Params only, 2=Start->Params, 3=Stop->Params->Start
  Future<void> iniciarCicloManual(Tratamiento t, {int startCommand = 0x21, int sequenceMode = 0, int workMode = 0}) async {
    final tempId = t.id;

    ciclosActivos[tempId] = {
      'activo': true,
      'inicio': DateFormat('HH:mm:ss').format(DateTime.now())
    };

    if (isConnected) {
      try {
        print("BLE: Starting Manual Treatment (Seq: $sequenceMode, Cmd: $startCommand, Mode: $workMode)");
        bool started = false;

        Future<void> stop() async {
          print("BLE: Sending Power OFF (Reset)");
          await _bleManager.write(BleProtocol.setPower(false));
          await Future.delayed(const Duration(milliseconds: 500));
        }

        Future<void> start() async {
          if (startCommand == 0x21) {
            print("BLE: Sending Quick Start (0x21) with Mode: $workMode");
            await _bleManager.write(BleProtocol.quickStart(mode: workMode));
            started = true;
          } else if (startCommand == 0x20) {
            print("BLE: Sending Power ON (0x20)");
            await _bleManager.write(BleProtocol.setPower(true));
            started = true;
          } else {
            print("BLE: Skipping Start Command");
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }

        Future<void> sendParams() async {
          await _sendParameters(t, workMode: workMode);
        }

        if (sequenceMode == 0) {
          await sendParams();
          await start();
        } else if (sequenceMode == 1) {
          await sendParams();
        } else if (sequenceMode == 2) {
          await start();
          await sendParams();
        } else if (sequenceMode == 3) {
          await stop();
          await Future.delayed(const Duration(milliseconds: 1000));
          await sendParams();
          await start();
        }

        if (started) {
          await Future.delayed(const Duration(milliseconds: 260));
          await _sendTimeAndPulse(t, phase: "post-start");
          await _readBackRunState(reason: "after iniciarCicloManual");
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
    if (index != -1) {
      catalogo[index] = t;
    } else {
      catalogo.add(t);
    }
    _guardarTodo();
    notifyListeners();
  }

  void ocultarTratamiento(String id) {
    int index = catalogo.indexWhere((e) => e.id == id);
    if (index != -1) {
      if (catalogo[index].esCustom) {
        catalogo.removeAt(index);
      } else {
        catalogo[index].oculto = true;
      }
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
            Actua como experto en fotobiomodulacion (red light therapy). Usuario: "$dolencia".
            Prioriza evidencia clinica humana y revisiones sistematicas en este orden:
            1) PubMed/MEDLINE
            2) ClinicalTrials.gov
            3) Cochrane Library / CENTRAL
            4) Europe PMC
            5) EMBASE
            6) CINAHL
            7) Scopus
            8) ScienceDirect
            9) Revistas especializadas (Photomedicine and Laser Surgery, Lasers in Medical Science, Journal of Biophotonics, Journal of Photochemistry and Photobiology, Lasers in Surgery and Medicine)
            10) Google Scholar solo como apoyo secundario

            Reglas:
            - No inventes evidencia ni afirmaciones.
            - Si la evidencia es debil o contradictoria, se conservador y anadelo en "prohibidos".
            - Devuelve 1 a 3 protocolos seguros.
            - Usa solo estas longitudes: 630, 660, 810, 830, 850.
            - Porcentajes entre 0 y 100.
            - hz permitido: CW, 10Hz, 40Hz, 50Hz.
            - duracion entre 5 y 20 minutos.
            - Incluye en tipsDespues una linea de evidencia breve tipo: "Fuente: PubMed PMID:xxxxx" o "ClinicalTrials.gov: NCTxxxx".

            Responde SOLO con un ARRAY JSON valido.
            Esquema: [{"nombre":"...","zona":"...","descripcion":"...","sintomas":"...","posicion":"...","hz":"CW/10Hz/40Hz/50Hz","duracion":"10","frecuencias":[{"nm":660,"p":100},{"nm":850,"p":50}],"tipsAntes":["..."],"tipsDespues":["..."],"prohibidos":["..."]}]
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Usuario o contraseña incorrectos"),
            backgroundColor: Colors.red));
      }
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

class _ManualSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ManualSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: kManualGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualGradientActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool compact;

  const _ManualGradientActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: kManualGradient,
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16, vertical: compact ? 8 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: compact ? 16 : 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : 15,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
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
    return Container(
      color: kManualBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            const SizedBox(height: 32)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: _ManualSectionHeader(
                title: "HOLA, ${state.currentUser.toUpperCase()}",
                icon: Icons.person_outline,
              ),
            ),
          _SidebarItem(
              icon: Icons.tune,
              label: "Configurar Tratamientos",
              selected: selectedIndex == 0,
              onTap: () {
                onItemSelected(0);
                if (isMobile) Navigator.pop(context);
              }),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, color: Color(0xFFBFD5E8)),
          ),
          const SizedBox(height: 6),
          _SidebarItem(
              icon: Icons.auto_awesome,
              label: "Buscador AI",
              selected: selectedIndex == 1,
              onTap: () {
                onItemSelected(1);
                if (isMobile) Navigator.pop(context);
              }),
          _SidebarItem(
              icon: Icons.settings,
              label: "Gestionar",
              selected: selectedIndex == 2,
              onTap: () {
                onItemSelected(2);
                if (isMobile) Navigator.pop(context);
              }),
          _SidebarItem(
              icon: Icons.settings_remote,
              label: "Control Manual",
              selected: selectedIndex == 3,
              onTap: () {
                onItemSelected(3);
                if (isMobile) Navigator.pop(context);
              }),
          const Spacer(),
          if (state.isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: SizedBox(
                width: double.infinity,
                child: _ManualGradientActionButton(
                  label: "Desconectar",
                  icon: Icons.bluetooth_disabled,
                  onPressed: () {
                    state.disconnectDevice();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bluetooth Desconectado")));
                    if (isMobile) Navigator.pop(context);
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: SizedBox(
              width: double.infinity,
              child: _ManualGradientActionButton(
                label: state.isConnected ? "Conectado" : "Conectar Panel",
                icon: state.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth,
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const BluetoothScanDialog(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: _ManualGradientActionButton(
                label: "Salir",
                icon: Icons.logout,
                onPressed: state.logout,
              ),
            ),
          )
        ],
      ),
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
      const ConfigurarTratamientosView(),
      const BuscadorIAView(),
      const GestionView(),
      const BluetoothCustomView()
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text("Mega Panel AI"),
          backgroundColor: kManualBg,
          foregroundColor: const Color(0xFF255F86),
          elevation: 0),
      drawer: Drawer(
          backgroundColor: kManualBg,
          child: _SidebarContent(
              selectedIndex: idx, onItemSelected: onNav, isMobile: true)),
      body: Container(
          color: kManualBg,
          child: Padding(padding: const EdgeInsets.all(16), child: pages[idx])),
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
      const ConfigurarTratamientosView(),
      const BuscadorIAView(),
      const GestionView(),
      const BluetoothCustomView()
    ];
    return Scaffold(
      body: Row(
        children: [
          Container(
              width: 260,
              color: kManualBg,
              child:
                  _SidebarContent(selectedIndex: idx, onItemSelected: onNav)),
          Expanded(
              child: Container(
                  color: kManualBg,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      child: pages[idx])))
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: kManualGradient,
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x332B86E7),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: selected ? 1 : 0.78,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TratamientosSubmenuPage { menu, diario, semanal, historial, clinica }

class ConfigurarTratamientosView extends StatefulWidget {
  const ConfigurarTratamientosView({super.key});

  @override
  State<ConfigurarTratamientosView> createState() =>
      _ConfigurarTratamientosViewState();
}

class _ConfigurarTratamientosViewState extends State<ConfigurarTratamientosView> {
  _TratamientosSubmenuPage _page = _TratamientosSubmenuPage.menu;

  String get _subtitle {
    switch (_page) {
      case _TratamientosSubmenuPage.diario:
        return "Panel Diario";
      case _TratamientosSubmenuPage.semanal:
        return "Panel Semanal";
      case _TratamientosSubmenuPage.historial:
        return "Historial";
      case _TratamientosSubmenuPage.clinica:
        return "Clínica";
      case _TratamientosSubmenuPage.menu:
        return "Configurar Tratamientos";
    }
  }

  Widget _submenuButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ManualGradientActionButton(
        label: label,
        icon: icon,
        onPressed: onTap,
      ),
    );
  }

  Widget _currentView() {
    switch (_page) {
      case _TratamientosSubmenuPage.diario:
        return const PanelDiarioView();
      case _TratamientosSubmenuPage.semanal:
        return const PanelSemanalView();
      case _TratamientosSubmenuPage.historial:
        return const HistorialView();
      case _TratamientosSubmenuPage.clinica:
        return const ClinicaView();
      case _TratamientosSubmenuPage.menu:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inMenu = _page == _TratamientosSubmenuPage.menu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ManualSectionHeader(
            title: inMenu ? "CONFIGURAR TRATAMIENTOS" : _subtitle.toUpperCase(),
            icon: inMenu ? Icons.tune : Icons.arrow_forward_ios),
        const SizedBox(height: 12),
        if (!inMenu)
          Align(
            alignment: Alignment.centerLeft,
            child: _ManualGradientActionButton(
              label: "Volver al submenú",
              icon: Icons.arrow_back,
              compact: true,
              onPressed: () {
                setState(() => _page = _TratamientosSubmenuPage.menu);
              },
            ),
          ),
        if (!inMenu) const SizedBox(height: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: inMenu
                ? ListView(
                    key: const ValueKey("menu"),
                    children: [
                      _submenuButton(
                          label: "Panel Diario",
                          icon: Icons.calendar_today,
                          onTap: () => setState(
                              () => _page = _TratamientosSubmenuPage.diario)),
                      _submenuButton(
                          label: "Panel Semanal",
                          icon: Icons.calendar_month,
                          onTap: () => setState(
                              () => _page = _TratamientosSubmenuPage.semanal)),
                      _submenuButton(
                          label: "Historial",
                          icon: Icons.history,
                          onTap: () => setState(
                              () => _page = _TratamientosSubmenuPage.historial)),
                      _submenuButton(
                          label: "Clínica",
                          icon: Icons.medical_services,
                          onTap: () => setState(
                              () => _page = _TratamientosSubmenuPage.clinica)),
                    ],
                  )
                : KeyedSubtree(
                    key: ValueKey(_page.name),
                    child: _currentView(),
                  ),
          ),
        ),
      ],
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
      const _ManualSectionHeader(
          title: "PANEL DIARIO", icon: Icons.calendar_today),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white70, borderRadius: BorderRadius.circular(14)),
        child: Text("Fecha: ${DateFormat('yyyy/MM/dd').format(hoyDt)}",
            style: const TextStyle(
                color: Color(0xFF255F86), fontWeight: FontWeight.w600)),
      ),
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
        _ManualGradientActionButton(
            icon: Icons.flash_on,
            label: "Registrar Todo",
            onPressed: () {
              for (var t in listaMostrar) {
                if (!hechos.any((h) => h['id'] == t.id)) {
                  state.registrarTratamiento(hoy, t.id, "Batch");
                }
              }
            }),
      const SizedBox(height: 20),
      const Text("✅ Completados",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
      ...completados.map((t) => ListTile(
          leading: const Icon(Icons.check_box, color: Colors.green),
          title: Text(t.nombre),
          subtitle: Text(planificadosMap[t.id] ?? "Clinica"),
          trailing: IconButton(
            icon: const Icon(Icons.undo, color: Colors.orange),
            tooltip: "Deshacer registro",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Deshacer registro"),
                      content: Text(
                          "Se quitara '${t.nombre}' de completados. Continuar?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar")),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Deshacer")),
                      ],
                    ),
                  ) ??
                  false;
              if (!confirm) return;
              state.desregistrarTratamiento(hoy, t.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Registro eliminado: ${t.nombre}")),
                );
              }
            },
          ))),
      const SizedBox(height: 20),
      const Text("📋 Pendientes",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (pendientes.isEmpty)
        const Text("Nada por hoy.", style: TextStyle(color: Colors.grey)),
      ...pendientes.map((t) => TreatmentCard(
          t: t,
          isPlanned: true,
          plannedMoment: planificadosMap[t.id],
          onDeletePlan: () async {
            final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Quitar planificado"),
                    content: Text("Quitar '${t.nombre}' de pendientes?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar")),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Quitar")),
                    ],
                  ),
                ) ??
                false;
            if (!confirm) return;
            state.desplanificarTratamiento(hoy, t.id);
          },
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
          onRegister: () async {
            final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Confirmar realizado"),
                    content:
                        Text("Confirmas que realizaste '${t.nombre}'?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar")),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Confirmar")),
                    ],
                  ),
                ) ??
                false;
            if (!confirm) return;
            state.registrarTratamiento(hoy, t.id, planificadosMap[t.id]!);
          })),
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
    if (selectedType == "Andar") {
      newSession.steps = steps;
    }
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
      const _ManualSectionHeader(
          title: "PANEL SEMANAL", icon: Icons.calendar_month),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          gradient: kManualGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicator: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(14)),
            dividerColor: Colors.transparent,
            tabs: _days
                .map((d) => Tab(text: "${DateFormat('E').format(d)} ${d.day}"))
                .toList()),
      ),
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
                        onDeletePlan: () async {
                          final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Quitar planificado"),
                                  content:
                                      Text("Quitar '${t.nombre}' de este dia?"),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancelar")),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Quitar")),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!confirm) return;
                          state.desplanificarTratamiento(fStr, t.id);
                        });
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
        const _ManualSectionHeader(
            title: "HISTORIAL DE REGISTROS", icon: Icons.history),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white70, borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.all(10),
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
      const _ManualSectionHeader(title: "CLÍNICA", icon: Icons.medical_services),
      const SizedBox(height: 14),
      const Text("Tratamientos Activos en Curso:",
          style:
              TextStyle(color: Color(0xFF255F86), fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      ...state.catalogo
          .where((t) => state.ciclosActivos[t.id]?['activo'] == true)
          .map((t) => Card(
                color: Colors.white70,
                child: ListTile(
                  title: Text(t.nombre),
                  subtitle:
                      Text("Iniciado: ${state.ciclosActivos[t.id]['inicio']}"),
                  trailing: SizedBox(
                    width: 120,
                    child: _ManualGradientActionButton(
                        label: "Finalizar",
                        compact: true,
                        onPressed: () => state.detenerCiclo(t.id)),
                  ),
                ),
              )),
      const Divider(height: 40),
      const Text("Iniciar Nuevo Tratamiento:",
          style: TextStyle(fontWeight: FontWeight.bold)),
      _BuscadorManual(
        catalogo: state.catalogo,
        onAdd: (t, _) async {
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
    final useHierarchicalSelector = DateTime.now().microsecondsSinceEpoch >= 0;
    if (useHierarchicalSelector) {
      String? nivel1;
      String? nivel2;
      String? nivel3;

      String limpiarNivel(String raw) {
        final cleaned = raw
            .replaceFirst(RegExp(r'^\s*\d+\s*[\)\.\-:]*\s*'), '')
            .trim();
        return cleaned.isEmpty ? raw.trim() : cleaned;
      }

      List<String> niveles(Tratamiento t) {
        final parts = t.zona
            .split(">")
            .map((e) => limpiarNivel(e.trim()))
            .where((e) => e.isNotEmpty)
            .toList();
        while (parts.length < 3) {
          parts.add("");
        }
        return [parts[0], parts[1], parts[2]];
      }

      List<String> opcionesNivel1() {
        final set = <String>{};
        for (final t in catalogo) {
          final n1 = niveles(t)[0];
          if (n1.isNotEmpty) set.add(n1);
        }
        final out = set.toList()..sort();
        return out;
      }

      List<String> opcionesNivel2(String n1) {
        final set = <String>{};
        for (final t in catalogo) {
          final n = niveles(t);
          if (n[0] == n1 && n[1].isNotEmpty) set.add(n[1]);
        }
        final out = set.toList()..sort();
        return out;
      }

      List<String> opcionesNivel3(String n1, String n2) {
        final set = <String>{};
        for (final t in catalogo) {
          final n = niveles(t);
          if (n[0] == n1 && n[1] == n2 && n[2].isNotEmpty) set.add(n[2]);
        }
        final out = set.toList()..sort();
        return out;
      }

      List<Tratamiento> tratamientosFiltrados() {
        if (nivel1 == null || nivel2 == null) return [];
        var out = catalogo.where((t) {
          final n = niveles(t);
          return n[0] == nivel1 && n[1] == nivel2;
        }).toList();
        final n3Options = opcionesNivel3(nivel1!, nivel2!);
        if (n3Options.isNotEmpty) {
          if (nivel3 == null) return [];
          out = out.where((t) => niveles(t)[2] == nivel3).toList();
        }
        out.sort((a, b) => a.nombre.compareTo(b.nombre));
        return out;
      }

      return StatefulBuilder(builder: (context, setInnerState) {
        final n1Options = opcionesNivel1();
        if (nivel1 != null && !n1Options.contains(nivel1)) {
          nivel1 = null;
          nivel2 = null;
          nivel3 = null;
        }
        final n2Options = nivel1 == null ? <String>[] : opcionesNivel2(nivel1!);
        if (nivel2 != null && !n2Options.contains(nivel2)) {
          nivel2 = null;
          nivel3 = null;
        }
        final n3Options =
            (nivel1 == null || nivel2 == null) ? <String>[] : opcionesNivel3(nivel1!, nivel2!);
        if (nivel3 != null && !n3Options.contains(nivel3)) {
          nivel3 = null;
        }
        final tratamientos = tratamientosFiltrados();

        return ExpansionTile(
          backgroundColor: Colors.white70,
          collapsedBackgroundColor: Colors.white70,
          iconColor: const Color(0xFF255F86),
          collapsedIconColor: const Color(0xFF255F86),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF255F86)),
              SizedBox(width: 8),
              Expanded(
                child: Text("Añadir Tratamiento Manual",
                    style: TextStyle(
                        color: Color(0xFF255F86), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.blue.shade100)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.blue.shade100)),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: nivel1,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Grupo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    hint: const Text("Selecciona grupo"),
                    items: n1Options
                        .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      setInnerState(() {
                        nivel1 = v;
                        nivel2 = null;
                        nivel3 = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (nivel1 != null)
                    DropdownButtonFormField<String>(
                      initialValue: nivel2,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Subgrupo",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                      hint: const Text("Selecciona subgrupo"),
                      items: n2Options
                          .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        setInnerState(() {
                          nivel2 = v;
                          nivel3 = null;
                        });
                      },
                    ),
                  if (nivel1 != null) const SizedBox(height: 10),
                  if (nivel2 != null && n3Options.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: nivel3,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Zona",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                      hint: const Text("Selecciona zona"),
                      items: n3Options
                          .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        setInnerState(() {
                          nivel3 = v;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: tratamientos.isEmpty
                        ? Center(
                            child: Text(
                              nivel1 == null
                                  ? "Selecciona Grupo para continuar."
                                  : (nivel2 == null
                                      ? "Selecciona Subgrupo para ver tratamientos."
                                      : (n3Options.isNotEmpty && nivel3 == null)
                                          ? "Selecciona Zona para ver tratamientos."
                                          : "No hay tratamientos para esta ruta."),
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: tratamientos.length,
                            itemBuilder: (ctx, i) {
                              final t = tratamientos[i];
                              return ListTile(
                                title: Text(t.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text("${t.zona}\n${t.sintomas}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
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
                                                  onPressed: () =>
                                                      Navigator.pop(dialogCtx),
                                                  child: const Text("Cancelar")),
                                              FilledButton(
                                                onPressed: () {
                                                  Navigator.pop(dialogCtx);
                                                  if (askTime) {
                                                    showDialog(
                                                        context: context,
                                                        builder: (_) =>
                                                            SimpleDialog(
                                                              title: const Text(
                                                                  "Cuando?"),
                                                              children: [
                                                                "PRE",
                                                                "POST",
                                                                "NOCHE",
                                                                "FLEX"
                                                              ]
                                                                  .map((m) =>
                                                                      SimpleDialogOption(
                                                                        child: Text(m),
                                                                        onPressed:
                                                                            () {
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
                                                child: const Text(
                                                    "Seleccionar / Anadir"),
                                              )
                                            ],
                                          ));
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      });
    }
    return ExpansionTile(
      backgroundColor: Colors.white70,
      collapsedBackgroundColor: Colors.white70,
      iconColor: const Color(0xFF255F86),
      collapsedIconColor: const Color(0xFF255F86),
      title: const Row(
        children: [
          Icon(Icons.add_circle_outline, color: Color(0xFF255F86)),
          SizedBox(width: 8),
          Expanded(
            child: Text("Añadir Tratamiento Manual",
                style: TextStyle(
                    color: Color(0xFF255F86), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.blue.shade100)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.blue.shade100)),
      children: [
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: catalogo.length,
            itemBuilder: (ctx, i) {
              var t = catalogo[i];
              return ListTile(
                title: Text(t.nombre,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text("${t.zona}\n${t.sintomas}",
                    maxLines: 2, overflow: TextOverflow.ellipsis),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                if (widget.t.zona.isNotEmpty)
                  _buildSection("Grupo / Parte", widget.t.zona,
                      Icons.category_outlined, Colors.amber.shade50),
                const SizedBox(height: 10),
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
                        ...widget.t.frecuencias.map((f) => Text(
                            "${f['nm']}nm: ${f['p']}%",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)))
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
                
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
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
                        
                      if (widget.onStart != null && !widget.isDone && !isActive)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange.shade700),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Iniciar"),
                          onPressed: widget.onStart,
                        ),
                      // Delete Plan
                      if (widget.isPlanned &&
                          widget.onDeletePlan != null &&
                          !widget.isDone && !isActive)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Quitar"),
                          onPressed: widget.onDeletePlan,
                        ),
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

  String _displayName(ScanResult result) {
    final advName = result.advertisementData.advName.trim();
    final platformName = result.device.platformName.trim();
    if (advName.isNotEmpty) return advName;
    if (platformName.isNotEmpty) return platformName;
    return "Dispositivo sin nombre";
  }

  bool _matchesDefaultFilter(ScanResult result) {
    final normalized =
        _displayName(result).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final matchesName = normalized.contains("blockbluelight") ||
        normalized.contains("bluelight") ||
        normalized.contains("blockblue") ||
        (normalized.contains("block") && normalized.contains("light"));
    if (matchesName) return true;

    // Some firmwares advertise with empty/non-standard names.
    // Keep list restricted to likely target devices by BLE service fingerprint.
    final serviceMatches = result.advertisementData.serviceUuids.any((uuid) {
      final s = uuid.str.toLowerCase();
      return s.contains("fff0") || s.contains("fff1") || s.contains("fff2");
    });
    return serviceMatches;
  }

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
    final connectedDevice = state._bleManager.connectedDevice;
    final connectedName = (() {
      final name = connectedDevice?.platformName.trim() ?? "";
      if (name.isNotEmpty) return name;
      return connectedDevice?.remoteId.str ?? "Desconocido";
    })();

    return AlertDialog(
      title: const Text("Dispositivos Bluetooth"),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: "Re-escanear",
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await _ble.stopScan();
                  await _ble.startScan();
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
            if (state.isConnected)
              ListTile(
                title: Text(connectedName),
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
                  var filtered =
                      List<ScanResult>.from(results).where(_matchesDefaultFilter).toList();

                  filtered.sort((a, b) {
                    var nameA = _displayName(a).toLowerCase();
                    var nameB = _displayName(b).toLowerCase();
                    bool aIsBlock = nameA.contains("block");
                    bool bIsBlock = nameB.contains("block");

                    if (aIsBlock && !bIsBlock) return -1;
                    if (!aIsBlock && bIsBlock) return 1;

                    return b.rssi.compareTo(a.rssi);
                  });

                  if (filtered.isEmpty) {
                    return Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bluetooth_searching, size: 28),
                        const SizedBox(height: 8),
                        const Text("Buscando dispositivos..."),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await _ble.stopScan();
                            await _ble.startScan();
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Reintentar escaneo"),
                        ),
                      ],
                    ));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      var d = filtered[i].device;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(_displayName(filtered[i]),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                                 SnackBar(content: Text("Conectado a ${_displayName(filtered[i])}"), backgroundColor: Colors.green)
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

