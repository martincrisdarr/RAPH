import 'package:flutter/material.dart';

class VictimaDespachoResumen {
  final int index;
  final int? idVictima;
  final String nombre;
  final String? triage;
  final String? movilNombre;
  final String? idMovil;
  final String estadoOperativo;
  final String? hospitalNombre;
  final bool isFinalizado;
  final int paso;
  final int? idDespacho;

  const VictimaDespachoResumen({
    required this.index,
    this.idVictima,
    required this.nombre,
    this.triage,
    this.movilNombre,
    this.idMovil,
    required this.estadoOperativo,
    this.hospitalNombre,
    required this.isFinalizado,
    required this.paso,
    this.idDespacho,
  });

  Color get triageColor {
    switch (triage?.toLowerCase()) {
      case 'rojo':
        return Colors.red.shade600;
      case 'amarillo':
        return Colors.yellow.shade700;
      case 'verde':
        return Colors.green.shade600;
      default:
        return const Color(0xFF64748B); // Slate / Gris
    }
  }

  Color get estadoColor {
    switch (estadoOperativo.toLowerCase()) {
      case 'en_sitio':
      case 'en sitio':
        return const Color(0xFF06B6D4); // Cyan
      case 'traslado':
      case 'en_traslado':
        return const Color(0xFFA855F7); // Púrpura
      case 'finalizado':
      case 'en_hospital':
      case 'arribado':
        return const Color(0xFF10B981); // Verde
      case 'despachado':
      case 'en_camino':
      case 'en camino':
        return const Color(0xFFF59E0B); // Ámbar / Naranja
      default:
        return const Color(0xFF64748B); // Gris
    }
  }

  String get estadoLabel {
    switch (estadoOperativo.toLowerCase()) {
      case 'en_sitio':
      case 'en sitio':
        return 'EN SITIO';
      case 'traslado':
      case 'en_traslado':
        if (hospitalNombre != null && hospitalNombre!.isNotEmpty) {
          return 'EN TRASLADO → $hospitalNombre';
        }
        return 'EN TRASLADO';
      case 'finalizado':
      case 'en_hospital':
      case 'arribado':
        return 'FINALIZADO';
      case 'despachado':
      case 'en_camino':
      case 'en camino':
        return 'EN CAMINO';
      case 'sin_despacho':
        return 'SIN MÓVIL';
      default:
        return estadoOperativo.toUpperCase();
    }
  }

  IconData get estadoIcon {
    switch (estadoOperativo.toLowerCase()) {
      case 'en_sitio':
      case 'en sitio':
        return Icons.location_on_rounded;
      case 'traslado':
      case 'en_traslado':
        return Icons.local_hospital_rounded;
      case 'finalizado':
      case 'en_hospital':
      case 'arribado':
        return Icons.check_circle_rounded;
      case 'despachado':
      case 'en_camino':
      case 'en camino':
        return Icons.directions_car_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}

