class Unidad {
  final String id;
  final String patente;
  final String marca;
  final String modelo;
  final String tipo; // e.g. "Alta Complejidad", "Baja Complejidad", "Furgón", etc.
  final String estado; // e.g. "Activo", "Mantenimiento", "Fuera de Servicio"
  final String? idMovilAsignado; // ID of the Mobile currently using this vehicle

  Unidad({
    required this.id,
    required this.patente,
    required this.marca,
    required this.modelo,
    required this.tipo,
    required this.estado,
    this.idMovilAsignado,
  });

  factory Unidad.fromJson(Map<String, dynamic> json) {
    return Unidad(
      id: json['id'] ?? '',
      patente: json['patente'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      tipo: json['tipo'] ?? 'Baja Complejidad',
      estado: json['estado'] ?? 'Activo',
      idMovilAsignado: json['idMovilAsignado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patente': patente,
      'marca': marca,
      'modelo': modelo,
      'tipo': tipo,
      'estado': estado,
      'idMovilAsignado': idMovilAsignado,
    };
  }

  Unidad copyWith({
    String? id,
    String? patente,
    String? marca,
    String? modelo,
    String? tipo,
    String? estado,
    String? idMovilAsignado,
    bool clearMovil = false,
  }) {
    return Unidad(
      id: id ?? this.id,
      patente: patente ?? this.patente,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      idMovilAsignado: clearMovil ? null : (idMovilAsignado ?? this.idMovilAsignado),
    );
  }
}
