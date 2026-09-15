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
    final map = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final idDemanda = map['iddemandarecibida'] ?? map['idDemandaRecibida'] ?? map['id'];

    return DemandaRecibida(
      idDemandaRecibida: idDemanda != null ? int.tryParse(idDemanda.toString()) : null,
      fechaHora: map['fechahora'] != null ? DateTime.tryParse(map['fechahora']) : null,
      usuario: map['usuario'],
      idCfgTipoIngreso: map['idcfg_tipo_ingreso'] != null ? int.tryParse(map['idcfg_tipo_ingreso'].toString()) : null,
      nroLlamadaEntrante: map['nro_llamada_entrante'] != null ? int.tryParse(map['nro_llamada_entrante'].toString()) : null,
      apellidoNombre: map['apellido_nombre'],
      dni: map['dni'],
      idCfgEstado: map['idcfg_estado'] != null ? int.tryParse(map['idcfg_estado'].toString()) : null,
      idIncidente: map['idincidente'] != null ? int.tryParse(map['idincidente'].toString()) : null,
      estado: map['estado'] != null ? Configuracion.fromJson(map['estado']) : null,
      tipoIngreso: map['tipo_ingreso'] != null ? Configuracion.fromJson(map['tipo_ingreso']) : null,
      incidente: map['incidente'] != null ? Incidente.fromJson(map['incidente']) : null,
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
    bool clearNroLlamada = false,
  }) {
    return DemandaRecibida(
      idDemandaRecibida: idDemandaRecibida ?? this.idDemandaRecibida,
      fechaHora: fechaHora ?? this.fechaHora,
      usuario: usuario ?? this.usuario,
      idCfgTipoIngreso: idCfgTipoIngreso ?? this.idCfgTipoIngreso,
      nroLlamadaEntrante: clearNroLlamada ? null : (nroLlamadaEntrante ?? this.nroLlamadaEntrante),
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
