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
  final String? observaciones;
  final String? idMovilAsignado;
  final int? idDespacho;
  final String? reporte;

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
    this.observaciones,
    this.idMovilAsignado,
    this.idDespacho,
    this.reporte,
  });

  factory Victima.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'];
    final personaSinDni = json['persona_sin_dni'];

    String? nombresApellidos = json['nombres_apellidos'] ?? json['nombre'];
    int? dni = json['dni'] != null ? int.tryParse(json['dni'].toString()) : null;
    int? idConfGenero = json['idconf_genero'] != null ? int.tryParse(json['idconf_genero'].toString()) : null;

    if (persona is Map<String, dynamic>) {
      final nombre = (persona['nombre'] ?? '').toString().trim();
      final apellido = (persona['apellido'] ?? '').toString().trim();
      final full = '$nombre $apellido'.trim();
      if (full.isNotEmpty) nombresApellidos = full;
      if (persona['dni'] != null) dni = int.tryParse(persona['dni'].toString());
      if (persona['idconf_genero'] != null) idConfGenero = int.tryParse(persona['idconf_genero'].toString());
    } else if (personaSinDni is Map<String, dynamic>) {
      final nombre = (personaSinDni['nombre'] ?? '').toString().trim();
      final apellido = (personaSinDni['apellido'] ?? '').toString().trim();
      final full = '$nombre $apellido'.trim();
      if (full.isNotEmpty) nombresApellidos = full;
      if (personaSinDni['idconf_genero'] != null) idConfGenero = int.tryParse(personaSinDni['idconf_genero'].toString());
    }

    int? idDespacho = json['iddespacho'] != null ? int.tryParse(json['iddespacho'].toString()) : null;
    String? idMovilAsignado = json['id_movil_asignado']?.toString();
    if (json['despachos'] is List) {
      final despachosList = json['despachos'] as List;
      final activos = despachosList.where((d) {
        if (d is Map) {
          final act = d['activo'];
          return act == 1 || act == '1' || act == true;
        }
        return false;
      }).toList();

      final despachoActivo = activos.isNotEmpty ? activos.last : (despachosList.isNotEmpty ? despachosList.last : null);
      if (despachoActivo is Map) {
        if (idDespacho == null && despachoActivo['iddespacho'] != null) {
          idDespacho = int.tryParse(despachoActivo['iddespacho'].toString());
        }
        if (idMovilAsignado == null || idMovilAsignado.isEmpty) {
          if (despachoActivo['movilunidad'] is Map && despachoActivo['movilunidad']['idmovil'] != null) {
            idMovilAsignado = despachoActivo['movilunidad']['idmovil'].toString();
          } else if (despachoActivo['idmovilunidad'] != null) {
            idMovilAsignado = despachoActivo['idmovilunidad'].toString();
          }
        }
      }
    }

    return Victima(
      idVictima: json['idvictima'] != null ? int.tryParse(json['idvictima'].toString()) : null,
      nombresApellidos: nombresApellidos,
      dni: dni,
      idConfGenero: idConfGenero,
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
      observaciones: json['observaciones'],
      idMovilAsignado: idMovilAsignado,
      idDespacho: idDespacho,
      reporte: json['reporte'],
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
    if (observaciones != null) map['observaciones'] = observaciones;
    if (idMovilAsignado != null) map['id_movil_asignado'] = idMovilAsignado;
    if (idDespacho != null) map['iddespacho'] = idDespacho;
    if (reporte != null) map['reporte'] = reporte;
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
    String? observaciones,
    String? idMovilAsignado,
    int? idDespacho,
    String? reporte,
    bool clearMovil = false,
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
      observaciones: observaciones ?? this.observaciones,
      idMovilAsignado: clearMovil ? null : (idMovilAsignado ?? this.idMovilAsignado),
      idDespacho: clearMovil ? null : (idDespacho ?? this.idDespacho),
      reporte: reporte ?? this.reporte,
    );
  }
}
