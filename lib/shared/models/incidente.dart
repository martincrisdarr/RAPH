class Incidente {
  final int? idIncidente;
  final String? direccion;
  final int? idLocalidad;
  final double? latitud;
  final double? longitud;
  final String? direccionAuto;
  final String? descripcion;
  final DateTime? fechaHoraAuto;

  Incidente({
    this.idIncidente,
    this.direccion,
    this.idLocalidad,
    this.latitud,
    this.longitud,
    this.direccionAuto,
    this.descripcion,
    this.fechaHoraAuto,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      idIncidente: json['idincidente'] != null ? int.tryParse(json['idincidente'].toString()) : null,
      direccion: json['direccion'],
      idLocalidad: json['idlocalidad'] != null ? int.tryParse(json['idlocalidad'].toString()) : null,
      latitud: json['latitud'] != null ? double.tryParse(json['latitud'].toString()) : null,
      longitud: json['longitud'] != null ? double.tryParse(json['longitud'].toString()) : null,
      direccionAuto: json['direccion_auto'],
      descripcion: json['descripcion'],
      fechaHoraAuto: json['fechahoraauto'] != null ? DateTime.tryParse(json['fechahoraauto']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (idIncidente != null) map['idincidente'] = idIncidente;
    if (direccion != null) map['direccion'] = direccion;
    if (idLocalidad != null) map['idlocalidad'] = idLocalidad;
    if (latitud != null) map['latitud'] = latitud;
    if (longitud != null) map['longitud'] = longitud;
    if (direccionAuto != null) map['direccion_auto'] = direccionAuto;
    if (descripcion != null) map['descripcion'] = descripcion;
    if (fechaHoraAuto != null) map['fechahoraauto'] = fechaHoraAuto?.toIso8601String();
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
    DateTime? fechaHoraAuto,
  }) {
    return Incidente(
      idIncidente: idIncidente ?? this.idIncidente,
      direccion: direccion ?? this.direccion,
      idLocalidad: idLocalidad ?? this.idLocalidad,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccionAuto: direccionAuto ?? this.direccionAuto,
      descripcion: descripcion ?? this.descripcion,
      fechaHoraAuto: fechaHoraAuto ?? this.fechaHoraAuto,
    );
  }
}
