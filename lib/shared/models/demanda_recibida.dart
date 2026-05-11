import 'configuracion.dart';
import 'incidente.dart';

class DemandaRecibida {
  final int? idDemandaRecibida;
  final DateTime? fechaHora;
  final String? usuario;
  final int? idCfgTipoIngreso;
  final int? nroLlamadaEntrante;
  final String? apellidoNombre;
  final String? dni;
  final int? idCfgEstado;
  final int? idIncidente;
  final Configuracion? estado;
  final Configuracion? tipoIngreso;
  final Incidente? incidente;

  DemandaRecibida({
    this.idDemandaRecibida,
    this.fechaHora,
    this.usuario,
    this.idCfgTipoIngreso,
    this.nroLlamadaEntrante,
    this.apellidoNombre,
    this.dni,
    this.idCfgEstado,
    this.idIncidente,
    this.estado,
    this.tipoIngreso,
    this.incidente,
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
      idIncidente: json['idincidente'] != null ? int.tryParse(json['idincidente'].toString()) : null,
      estado: json['estado'] != null ? Configuracion.fromJson(json['estado']) : null,
      tipoIngreso: json['tipo_ingreso'] != null ? Configuracion.fromJson(json['tipo_ingreso']) : null,
      incidente: json['incidente'] != null ? Incidente.fromJson(json['incidente']) : null,
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
    if (idIncidente != null) map['idincidente'] = idIncidente;
    if (estado != null) map['estado'] = estado?.toJson();
    if (tipoIngreso != null) map['tipo_ingreso'] = tipoIngreso?.toJson();
    if (incidente != null) map['incidente'] = incidente?.toJson();
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
    int? idIncidente,
    Configuracion? estado,
    Configuracion? tipoIngreso,
    Incidente? incidente,
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
      idIncidente: idIncidente ?? this.idIncidente,
      estado: estado ?? this.estado,
      tipoIngreso: tipoIngreso ?? this.tipoIngreso,
      incidente: incidente ?? this.incidente,
    );
  }
}
