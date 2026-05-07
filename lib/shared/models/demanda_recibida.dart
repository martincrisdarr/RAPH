class DemandaRecibida {
  final int? idDemandaRecibida;
  final DateTime? fechaHora;
  final String? usuario;
  final int? idCfgTipoIngreso;
  final int? nroLlamadaEntrante;
  final String? apellidoNombre;
  final String? dni;
  final int? idCfgEstado;

  DemandaRecibida({
    this.idDemandaRecibida,
    this.fechaHora,
    this.usuario,
    this.idCfgTipoIngreso,
    this.nroLlamadaEntrante,
    this.apellidoNombre,
    this.dni,
    this.idCfgEstado,
  });

  factory DemandaRecibida.fromJson(Map<String, dynamic> json) {
    return DemandaRecibida(
      idDemandaRecibida: json['iddemandarecibida'] != null ? int.tryParse(json['iddemandarecibida'].toString()) : null,
      fechaHora: json['fechahora'] != null ? DateTime.tryParse(json['fechahora']) : null,
      usuario: json['usuario'],
      idCfgTipoIngreso: json['idcfg_tipo_ingreso'] != null ? int.tryParse(json['idcfg_tipo_ingreso'].toString()) : null,
      nroLlamadaEntrante: json['nro_llamada_entrante'] != null ? int.tryParse(json['nro_llamada_entrante'].toString()) : null,
      apellidoNombre: json['apellido_nombre'],
      dni: json['dni'],
      idCfgEstado: json['idcfg_estado'] != null ? int.tryParse(json['idcfg_estado'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (idDemandaRecibida != null) map['iddemandarecibida'] = idDemandaRecibida;
    if (fechaHora != null) map['fechahora'] = fechaHora?.toIso8601String();
    if (usuario != null) map['usuario'] = usuario;
    if (idCfgTipoIngreso != null) map['idcfg_tipo_ingreso'] = idCfgTipoIngreso;
    if (nroLlamadaEntrante != null) map['nro_llamada_entrante'] = nroLlamadaEntrante;
    if (apellidoNombre != null) map['apellido_nombre'] = apellidoNombre;
    if (dni != null) map['dni'] = dni;
    if (idCfgEstado != null) map['idcfg_estado'] = idCfgEstado;
    return map;
  }
  
  DemandaRecibida copyWith({
    int? idDemandaRecibida,
    DateTime? fechaHora,
    String? usuario,
    int? idCfgTipoIngreso,
    int? nroLlamadaEntrante,
    String? apellidoNombre,
    String? dni,
    int? idCfgEstado,
  }) {
    return DemandaRecibida(
      idDemandaRecibida: idDemandaRecibida ?? this.idDemandaRecibida,
      fechaHora: fechaHora ?? this.fechaHora,
      usuario: usuario ?? this.usuario,
      idCfgTipoIngreso: idCfgTipoIngreso ?? this.idCfgTipoIngreso,
      nroLlamadaEntrante: nroLlamadaEntrante ?? this.nroLlamadaEntrante,
      apellidoNombre: apellidoNombre ?? this.apellidoNombre,
      dni: dni ?? this.dni,
      idCfgEstado: idCfgEstado ?? this.idCfgEstado,
    );
  }
}
