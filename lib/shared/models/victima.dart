class Victima {
  final int? idVictima;
  final String? nombresApellidos;
  final int? dni;
  final int? idConfGenero;
  final int? edad;
  final String? estadoActual;
  final int? idConfCodigo;
  final int? idIncidente;
  final DateTime? fechahoraSolicitaDespacho;
  final DateTime? fechahoraConfirmaDespacho;

  Victima({
    this.idVictima,
    this.nombresApellidos,
    this.dni,
    this.idConfGenero,
    this.edad,
    this.estadoActual,
    this.idConfCodigo,
    this.idIncidente,
    this.fechahoraSolicitaDespacho,
    this.fechahoraConfirmaDespacho,
  });

  factory Victima.fromJson(Map<String, dynamic> json) {
    return Victima(
      idVictima: json['idvictima'] != null ? int.tryParse(json['idvictima'].toString()) : null,
      nombresApellidos: json['nombres_apellidos'],
      dni: json['dni'] != null ? int.tryParse(json['dni'].toString()) : null,
      idConfGenero: json['idconf_genero'] != null ? int.tryParse(json['idconf_genero'].toString()) : null,
      edad: json['edad'] != null ? int.tryParse(json['edad'].toString()) : null,
      estadoActual: json['estado_actual'],
      idConfCodigo: json['idconf_codigo'] != null ? int.tryParse(json['idconf_codigo'].toString()) : null,
      idIncidente: json['idincidente'] != null ? int.tryParse(json['idincidente'].toString()) : null,
      fechahoraSolicitaDespacho: json['fechahora_solicita_despacho'] != null
          ? DateTime.tryParse(json['fechahora_solicita_despacho'])
          : null,
      fechahoraConfirmaDespacho: json['fechahora_confirma_despacho'] != null
          ? DateTime.tryParse(json['fechahora_confirma_despacho'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (idVictima != null) map['idvictima'] = idVictima;
    if (nombresApellidos != null) map['nombres_apellidos'] = nombresApellidos;
    if (dni != null) map['dni'] = dni;
    if (idConfGenero != null) map['idconf_genero'] = idConfGenero;
    if (edad != null) map['edad'] = edad;
    if (estadoActual != null) map['estado_actual'] = estadoActual;
    if (idConfCodigo != null) map['idconf_codigo'] = idConfCodigo;
    if (idIncidente != null) map['idincidente'] = idIncidente;
    if (fechahoraSolicitaDespacho != null) map['fechahora_solicita_despacho'] = fechahoraSolicitaDespacho!.toIso8601String();
    if (fechahoraConfirmaDespacho != null) map['fechahora_confirma_despacho'] = fechahoraConfirmaDespacho!.toIso8601String();
    return map;
  }

  Victima copyWith({
    int? idVictima,
    String? nombresApellidos,
    int? dni,
    int? idConfGenero,
    int? edad,
    String? estadoActual,
    int? idConfCodigo,
    int? idIncidente,
    DateTime? fechahoraSolicitaDespacho,
    DateTime? fechahoraConfirmaDespacho,
  }) {
    return Victima(
      idVictima: idVictima ?? this.idVictima,
      nombresApellidos: nombresApellidos ?? this.nombresApellidos,
      dni: dni ?? this.dni,
      idConfGenero: idConfGenero ?? this.idConfGenero,
      edad: edad ?? this.edad,
      estadoActual: estadoActual ?? this.estadoActual,
      idConfCodigo: idConfCodigo ?? this.idConfCodigo,
      idIncidente: idIncidente ?? this.idIncidente,
      fechahoraSolicitaDespacho: fechahoraSolicitaDespacho ?? this.fechahoraSolicitaDespacho,
      fechahoraConfirmaDespacho: fechahoraConfirmaDespacho ?? this.fechahoraConfirmaDespacho,
    );
  }
}
