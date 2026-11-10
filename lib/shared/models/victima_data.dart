import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'victima.dart';

class VictimaData {
  String id = UniqueKey().toString();
  int? idVictima;
  String nombre = '';
  String edad = '';
  int? idConfGenero;
  String dni = '';
  String? codigoTriage;
  List<String> sintomasSeleccionados = [];
  String busqueda = '';
  List<PlatformFile> archivosAdjuntos = [];
  String observaciones = '';
  String? idMovilAsignado;
  String? reporte;
  DateTime? fechaHoraCierre;
  String? usuarioCierre;
  int? idVictimaEvaluacion;
  int? idSintomaSeleccionadoId;
  int? idVictimaSintomaActivo;

  bool get isCerrada => reporte != null && reporte!.trim().isNotEmpty;

  Victima toVictima(int? idIncidente) {
    int? idConfCodigo;
    final triage = codigoTriage?.toLowerCase();
    if (triage == 'rojo') {
      idConfCodigo = 29;
    } else if (triage == 'amarillo') {
      idConfCodigo = 30;
    } else if (triage == 'verde') {
      idConfCodigo = 31;
    }

    return Victima(
      idVictima: idVictima,
      nombresApellidos: nombre.isNotEmpty ? nombre : null,
      dni: int.tryParse(dni),
      idConfGenero: idConfGenero,
      idConfCodigo: idConfCodigo,
      edad: int.tryParse(edad),
      estadoActual: sintomasSeleccionados.isNotEmpty
          ? sintomasSeleccionados.join(', ')
          : null,
      idIncidente: idIncidente,
      observaciones: observaciones.isNotEmpty ? observaciones : null,
      idMovilAsignado: idMovilAsignado,
      reporte: reporte,
      fechaHoraCierre: fechaHoraCierre,
      usuarioCierre: usuarioCierre,
    );
  }

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'idVictima': idVictima,
        'nombre': nombre,
        'edad': edad,
        'idConfGenero': idConfGenero,
        'dni': dni,
        'codigoTriage': codigoTriage,
        'sintomasSeleccionados': sintomasSeleccionados,
        'observaciones': observaciones,
        'idMovilAsignado': idMovilAsignado,
        'reporte': reporte,
        'fechaHoraCierre': fechaHoraCierre?.toIso8601String(),
        'usuarioCierre': usuarioCierre,
      };

  static VictimaData fromStorageJson(Map<String, dynamic> json) {
    final v = VictimaData();
    v.id = json['id'] ?? v.id;
    v.idVictima = json['idVictima'];
    v.nombre = json['nombre'] ?? '';
    v.edad = json['edad'] ?? '';
    v.idConfGenero = json['idConfGenero'];
    v.dni = json['dni'] ?? '';
    v.codigoTriage = json['codigoTriage'];
    v.sintomasSeleccionados = List<String>.from(json['sintomasSeleccionados'] ?? []);
    v.observaciones = json['observaciones'] ?? '';
    v.idMovilAsignado = json['idMovilAsignado'];
    v.reporte = json['reporte'];
    v.fechaHoraCierre = json['fechaHoraCierre'] != null
        ? DateTime.tryParse(json['fechaHoraCierre'].toString())
        : null;
    v.usuarioCierre = json['usuarioCierre'];
    return v;
  }

  static VictimaData fromVictima(Victima victima) {
    final v = VictimaData();
    v.idVictima = victima.idVictima;
    v.nombre = victima.nombresApellidos ?? '';
    v.edad = victima.edad?.toString() ?? '';
    v.idConfGenero = victima.idConfGenero;
    v.dni = victima.dni?.toString() ?? '';
    v.observaciones = victima.observaciones ?? '';
    v.idMovilAsignado = victima.idMovilAsignado;
    v.reporte = victima.reporte;
    v.fechaHoraCierre = victima.fechaHoraCierre;
    v.usuarioCierre = victima.usuarioCierre;

    if (victima.idConfCodigo == 29) {
      v.codigoTriage = 'Rojo';
    } else if (victima.idConfCodigo == 30) {
      v.codigoTriage = 'Amarillo';
    } else if (victima.idConfCodigo == 31) {
      v.codigoTriage = 'Verde';
    }

    if (victima.estadoActual != null && victima.estadoActual!.isNotEmpty) {
      v.sintomasSeleccionados = victima.estadoActual!.split(',').map((s) => s.trim()).toList();
    }
    return v;
  }
}
