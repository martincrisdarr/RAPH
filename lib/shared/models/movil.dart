class Movil {
  final String id; // idmovil
  final String nombre; // e.g. "Móvil 1", "Móvil 2" (SerSienDspMovil: nombre)
  final String? descripcion; // Descripción del móvil (SerSienDspMovil: descripcion)
  final int activo; // 1 = Activo, 0 = Inactivo (SerSienDspMovil: activo)
  final int? idmovilEstado; // ID de la tabla ser_sien_dsp_movil_estado
  final String estado; // e.g. "Disponible", "Despachado", "En sitio", "Traslado", "Inactivo"
  final String? idUnidadAsignada; // ID of the physical vehicle (Unidad)
  final double latitud;
  final double longitud;
  final int? idIncidenteActivo; // ID of active incident they are assigned to

  Movil({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activo = 1,
    this.idmovilEstado,
    required this.estado,
    this.idUnidadAsignada,
    required this.latitud,
    required this.longitud,
    this.idIncidenteActivo,
  });

  factory Movil.fromJson(Map<String, dynamic> json) {
    String? unidadAsignadaId = json['idUnidadAsignada']?.toString();
    if (unidadAsignadaId == null && json['unidades'] is List && (json['unidades'] as List).isNotEmpty) {
      final primeraUnidad = (json['unidades'] as List).first;
      if (primeraUnidad is Map) {
        unidadAsignadaId = (primeraUnidad['idmovilunidad'] ?? primeraUnidad['idunidad'])?.toString();
      }
    }

    int? parsedIdEstado = json['idmovil_estado'] != null ? int.tryParse(json['idmovil_estado'].toString()) : null;

    return Movil(
      id: (json['idmovil'] ?? json['id'] ?? '').toString(),
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      activo: json['activo'] is int
          ? json['activo']
          : (json['activo'] == true ? 1 : (int.tryParse(json['activo']?.toString() ?? '1') ?? 1)),
      idmovilEstado: parsedIdEstado,
      estado: json['estado'] ?? (json['activo'] == 0 ? 'Inactivo' : 'Disponible'),
      idUnidadAsignada: unidadAsignadaId,
      latitud: (json['latitud'] as num?)?.toDouble() ?? -38.9516,
      longitud: (json['longitud'] as num?)?.toDouble() ?? -68.0591,
      idIncidenteActivo: json['idIncidenteActivo'] != null
          ? int.tryParse(json['idIncidenteActivo'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idmovil': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'idmovil_estado': idmovilEstado,
      'estado': estado,
      'idUnidadAsignada': idUnidadAsignada,
      'latitud': latitud,
      'longitud': longitud,
      'idIncidenteActivo': idIncidenteActivo,
    };
  }

  Movil copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    int? activo,
    int? idmovilEstado,
    String? estado,
    String? idUnidadAsignada,
    double? latitud,
    double? longitud,
    int? idIncidenteActivo,
    bool clearIncidente = false,
    bool clearUnidad = false,
  }) {
    return Movil(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      idmovilEstado: idmovilEstado ?? this.idmovilEstado,
      estado: estado ?? this.estado,
      idUnidadAsignada: clearUnidad ? null : (idUnidadAsignada ?? this.idUnidadAsignada),
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      idIncidenteActivo: clearIncidente ? null : (idIncidenteActivo ?? this.idIncidenteActivo),
    );
  }
}

