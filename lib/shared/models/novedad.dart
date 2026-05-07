class Novedad {
  final int? idNovedad;
  final String descripcion;
  final int? idIncidente;
  final DateTime? fechaHora;
  final DateTime? fechaHoraAuto;
  final String? usuario;
  final int? idNovedadTipo;

  Novedad({
    this.idNovedad,
    required this.descripcion,
    this.idIncidente,
    this.fechaHora,
    this.fechaHoraAuto,
    this.usuario,
    this.idNovedadTipo,
  });

  factory Novedad.fromJson(Map<String, dynamic> json) {
    return Novedad(
      idNovedad: json['idnovedad'] != null ? int.tryParse(json['idnovedad'].toString()) : null,
      descripcion: json['descripcion'] ?? '',
      idIncidente: json['idincidente'] != null ? int.tryParse(json['idincidente'].toString()) : null,
      fechaHora: json['fechahora'] != null ? DateTime.tryParse(json['fechahora']) : null,
      fechaHoraAuto: json['fechahoraauto'] != null ? DateTime.tryParse(json['fechahoraauto']) : null,
      usuario: json['usuario'],
      idNovedadTipo: json['idnovedadtipo'] != null ? int.tryParse(json['idnovedadtipo'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (idNovedad != null) map['idnovedad'] = idNovedad;
    map['descripcion'] = descripcion;
    if (idIncidente != null) map['idincidente'] = idIncidente;
    if (fechaHora != null) map['fechahora'] = fechaHora!.toIso8601String();
    if (fechaHoraAuto != null) map['fechahoraauto'] = fechaHoraAuto!.toIso8601String();
    if (usuario != null) map['usuario'] = usuario;
    if (idNovedadTipo != null) map['idnovedadtipo'] = idNovedadTipo;
    return map;
  }

  Novedad copyWith({
    int? idNovedad,
    String? descripcion,
    int? idIncidente,
    DateTime? fechaHora,
    DateTime? fechaHoraAuto,
    String? usuario,
    int? idNovedadTipo,
  }) {
    return Novedad(
      idNovedad: idNovedad ?? this.idNovedad,
      descripcion: descripcion ?? this.descripcion,
      idIncidente: idIncidente ?? this.idIncidente,
      fechaHora: fechaHora ?? this.fechaHora,
      fechaHoraAuto: fechaHoraAuto ?? this.fechaHoraAuto,
      usuario: usuario ?? this.usuario,
      idNovedadTipo: idNovedadTipo ?? this.idNovedadTipo,
    );
  }
}
