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

  Victima toVictima(int? idIncidente) {
    return Victima(
      idVictima: idVictima,
      nombresApellidos: nombre.isNotEmpty ? nombre : null,
      dni: int.tryParse(dni),
      idConfGenero: idConfGenero,
      edad: int.tryParse(edad),
      estadoActual: sintomasSeleccionados.isNotEmpty
          ? sintomasSeleccionados.join(', ')
          : null,
      idIncidente: idIncidente,
      observaciones: observaciones.isNotEmpty ? observaciones : null,
      idMovilAsignado: idMovilAsignado,
      reporte: reporte,
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
    if (victima.estadoActual != null && victima.estadoActual!.isNotEmpty) {
      v.sintomasSeleccionados = victima.estadoActual!.split(',').map((s) => s.trim()).toList();
    }
    return v;
  }
}
