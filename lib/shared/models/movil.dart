class Movil {
  final String id;
  final String nombre; // e.g. "Móvil 1", "Móvil 2"
  final String estado; // e.g. "Disponible", "Despachado", "En sitio", "Traslado", "Inactivo"
  final String? idUnidadAsignada; // ID of the physical vehicle (Unidad)
  final double latitud;
  final double longitud;
  final int? idIncidenteActivo; // ID of active incident they are assigned to
  final String? personal; // e.g. "Dr. Gómez, Enf. Ruiz, Chof. Díaz"

  Movil({
    required this.id,
    required this.nombre,
    required this.estado,
    this.idUnidadAsignada,
    required this.latitud,
    required this.longitud,
    this.idIncidenteActivo,
    this.personal,
  });

  factory Movil.fromJson(Map<String, dynamic> json) {
    return Movil(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      estado: json['estado'] ?? 'Inactivo',
      idUnidadAsignada: json['idUnidadAsignada'],
      latitud: (json['latitud'] as num?)?.toDouble() ?? -38.9516,
      longitud: (json['longitud'] as num?)?.toDouble() ?? -68.0591,
      idIncidenteActivo: json['idIncidenteActivo'] != null
          ? int.tryParse(json['idIncidenteActivo'].toString())
          : null,
      personal: json['personal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'estado': estado,
      'idUnidadAsignada': idUnidadAsignada,
      'latitud': latitud,
      'longitud': longitud,
      'idIncidenteActivo': idIncidenteActivo,
      'personal': personal,
    };
  }

  Movil copyWith({
    String? id,
    String? nombre,
    String? estado,
    String? idUnidadAsignada,
    double? latitud,
    double? longitud,
    int? idIncidenteActivo,
    String? personal,
    bool clearIncidente = false,
    bool clearUnidad = false,
  }) {
    return Movil(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      estado: estado ?? this.estado,
      idUnidadAsignada: clearUnidad ? null : (idUnidadAsignada ?? this.idUnidadAsignada),
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      idIncidenteActivo: clearIncidente ? null : (idIncidenteActivo ?? this.idIncidenteActivo),
      personal: personal ?? this.personal,
    );
  }
}
