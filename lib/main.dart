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
];

const Set<String> _idsTendinopatia = {
  "codo_epi",
  "codo_golf",
  "codo_calc",
  "ant_tend",
  "pierna_itb",
  "pie_fasc",
  "homb_tend",
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
};

const Set<String> _idsRodilla = {"rod_gen", "rod_pfps"};
const Set<String> _idsCefalea = {"cab_migr"};
const Set<String> _idsNeuroExperimental = {"cab_brain"};
const Set<String> _idsPielRegenerativa = {"piel_cicat", "piel_quem", "pie_ulc"};
const Set<String> _idsPielEstetica = {"face_rejuv", "piel_acne"};
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
  if (_idsTendinopatia.contains(id)) {
    return [
      "Fuente: PubMed PMID:36171024 (meta-analisis en tendinopatia de miembro inferior y fascitis plantar).",
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
    ];
  }
  if (_idsRodilla.contains(id)) {
    return [
      "Fuente: PubMed PMID:38775202 (knee OA, metanalisis 2024).",
      "Fuente: ScienceDirect doi:10.1016/j.ptsp.2025.11.009 (patellofemoral pain, metanalisis).",
    ];
  }
  if (id == "mun_tunel") {
    return ["Fuente: PubMed PMID:35611937 (Cochrane review sindrome tunel carpiano)."];
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
  if (id == "face_rejuv") {
    return ["Fuente: PubMed PMID:36780572 (RCT rejuvenecimiento facial LED/PBM)."];
  }
  if (id == "piel_quem" || id == "pie_ulc") {
    return ["Fuente: PubMed PMID:39172550 (revision/meta PBM en cicatrizacion de heridas y quemaduras)."];
  }
  if (id == "boca_mucos") {
    return ["Fuente: PubMed PMID:34742930 (meta-analisis PBM para mucositis oral por cancer)."];
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
      "Fuente: ClinicalTrials.gov NCT06757374 (tPBM en deterioro cognitivo, en curso).",
    ];
  }
  return [];
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

  return Tratamiento(
    id: t.id,
    nombre: t.nombre,
    zona: t.zona,
    descripcion: t.descripcion,
    sintomas: t.sintomas,
    posicion: t.posicion,
    hz: hz,
    duracion: duracion,
    frecuencias: frecuencias,
    tipsAntes: _mergeUniqueStrings(t.tipsAntes, _tipsAntesCientificosPorId(t.id)),
    tipsDespues: _mergeUniqueStrings(t.tipsDespues, _tipsDespuesCientificosPorId(t.id)),
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
    for (var base in DB_DEFINICIONES) {
      final t = _aplicarActualizacionCientifica(base);
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
        await _bleManager.write(BleProtocol.setPower(true));
        await Future.delayed(const Duration(milliseconds: 360));

        // Some firmwares ignore dimming updates until the run state is active.
        await _sendParameters(t, workMode: 0);
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
    const dimmingDelay = Duration(milliseconds: 120);

    final brightness = _brightnessByChannel(t);

    print("BLE: Sending Work Mode: $workMode");
    await _bleManager.write(BleProtocol.setWorkMode(workMode));
    await Future.delayed(modeDelay);

    for (final channel in [0, 1, 2, 3, 4]) {
      final value = brightness[channel] ?? 0;
      print("BLE: Dimming Ch$channel -> $value%");
      await _bleManager.write(BleProtocol.setBrightnessChannel(channel, value));
      await Future.delayed(dimmingDelay);
    }

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
      const BluetoothCustomView()
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
      const BluetoothCustomView()
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

