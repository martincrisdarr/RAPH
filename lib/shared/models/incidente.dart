import 'victima.dart';
import 'novedad.dart';

class Incidente {
  final int? idIncidente;
  final String? direccion;
  final int? idLocalidad;
  final double? latitud;
  final double? longitud;
  final String? direccionAuto;
  final String? descripcion;
  final int? idConfCodigo;
  final String? codigoTriage;
  final String? reporte;
  final DateTime? fechaHoraAuto;
  final int? activo;
  final List<Victima>? victimas;
  final List<Novedad>? novedades;

  Incidente({
    this.idIncidente,
    this.direccion,
    this.idLocalidad,
    this.latitud,
    this.longitud,
    this.direccionAuto,
    this.descripcion,
    this.idConfCodigo,
    this.codigoTriage,
    this.reporte,
    this.fechaHoraAuto,
    this.activo = 1,
    this.victimas,
    this.novedades,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    int? parsedIdConf = json['idconf_codigo'] != null ? int.tryParse(json['idconf_codigo'].toString()) : null;
    String? triage = json['codigo_triage'];
    if (triage == null && parsedIdConf != null) {
      if (parsedIdConf == 29) triage = 'Rojo';
      else if (parsedIdConf == 30) triage = 'Amarillo';
      else if (parsedIdConf == 31) triage = 'Verde';
    }

    return Incidente(
      idIncidente: json['idincidente'] != null ? int.tryParse(json['idincidente'].toString()) : null,
      direccion: json['direccion'],
      idLocalidad: json['idlocalidad'] != null ? int.tryParse(json['idlocalidad'].toString()) : null,
      latitud: json['latitud'] != null ? double.tryParse(json['latitud'].toString()) : null,
      longitud: json['longitud'] != null ? double.tryParse(json['longitud'].toString()) : null,
      direccionAuto: json['direccion_auto'],
      descripcion: json['descripcion'],
      idConfCodigo: parsedIdConf,
      codigoTriage: triage,
      reporte: json['reporte'],
      fechaHoraAuto: json['fechahoraauto'] != null ? DateTime.tryParse(json['fechahoraauto']) : null,
      activo: json['activo'] != null ? int.tryParse(json['activo'].toString()) : 1,
      victimas: json['victimas'] != null ? (json['victimas'] as List).map((v) => Victima.fromJson(v)).toList() : null,
      novedades: json['novedades'] != null ? (json['novedades'] as List).map((n) => Novedad.fromJson(n)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    int? finalIdConf = idConfCodigo;
    if (finalIdConf == null && codigoTriage != null) {
      if (codigoTriage == 'Rojo') finalIdConf = 29;
      else if (codigoTriage == 'Amarillo') finalIdConf = 30;
      else if (codigoTriage == 'Verde') finalIdConf = 31;
    }

    if (idIncidente != null) map['idincidente'] = idIncidente;
    if (direccion != null) map['direccion'] = direccion;
    if (idLocalidad != null) map['idlocalidad'] = idLocalidad;
    if (latitud != null) map['latitud'] = latitud;
    if (longitud != null) map['longitud'] = longitud;
    if (direccionAuto != null) map['direccion_auto'] = direccionAuto;
    if (descripcion != null) map['descripcion'] = descripcion;
    if (finalIdConf != null) map['idconf_codigo'] = finalIdConf;
    if (codigoTriage != null) map['codigo_triage'] = codigoTriage;
    if (reporte != null) map['reporte'] = reporte;
    if (fechaHoraAuto != null) map['fechahoraauto'] = fechaHoraAuto?.toIso8601String();
    if (activo != null) map['activo'] = activo;
    if (victimas != null) map['victimas'] = victimas?.map((v) => v.toJson()).toList();
    if (novedades != null) map['novedades'] = novedades?.map((n) => n.toJson()).toList();
    return map;
  }

  Incidente copyWith({
    int? idIncidente,
    String? direccion,
    int? idLocalidad,
    double? latitud,
    double? longitud,
    String? direccionAuto,
    String? descripcion,
    int? idConfCodigo,
    String? codigoTriage,
    String? reporte,
    DateTime? fechaHoraAuto,
    int? activo,
    List<Victima>? victimas,
    List<Novedad>? novedades,
  }) {
    return Incidente(
      idIncidente: idIncidente ?? this.idIncidente,
      direccion: direccion ?? this.direccion,
      idLocalidad: idLocalidad ?? this.idLocalidad,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccionAuto: direccionAuto ?? this.direccionAuto,
      descripcion: descripcion ?? this.descripcion,
      idConfCodigo: idConfCodigo ?? this.idConfCodigo,
      codigoTriage: codigoTriage ?? this.codigoTriage,
      reporte: reporte ?? this.reporte,
      fechaHoraAuto: fechaHoraAuto ?? this.fechaHoraAuto,
      activo: activo ?? this.activo,
      victimas: victimas ?? this.victimas,
      novedades: novedades ?? this.novedades,
    );
  }
}
