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
    final Map<String, dynamic>? uObj = json['unidad'] is Map<String, dynamic> ? json['unidad'] : null;
    final Map<String, dynamic>? mObj = json['movil'] is Map<String, dynamic> ? json['movil'] : null;
    final Map<String, dynamic>? tObj = json['tipo_unidad'] is Map<String, dynamic> ? json['tipo_unidad'] : null;

    final String parsedId = (json['idmovilunidad'] ?? json['idunidad'] ?? uObj?['id_unidad'] ?? json['id'] ?? '').toString();
    final String idUnidadReal = (json['idunidad'] ?? uObj?['id_unidad'] ?? parsedId).toString();

    final String parsedPatente = (json['patente'] ?? uObj?['patente'] ?? '').toString();
    final String parsedMarca = (json['marca'] ?? uObj?['marca'] ?? '').toString();
    final String parsedModelo = (json['modelo'] ?? uObj?['modelo'] ?? '').toString();
    final String parsedTipo = (json['tipo'] ?? tObj?['nombre'] ?? uObj?['tipo'] ?? 'Alta Complejidad').toString();

    final int activoInt = json['activo'] is int
        ? json['activo']
        : (json['activo'] == true || json['activo'] == 1 ? 1 : 0);
    final String parsedEstado = json['estado'] ?? (activoInt == 1 ? 'Activo' : 'Fuera de Servicio');
    final String? parsedMovilId = (json['idMovilAsignado'] ?? json['idmovil'] ?? mObj?['idmovil'])?.toString();

    final String finalMarca = parsedMarca.isNotEmpty
        ? parsedMarca
        : (mObj != null && mObj['nombre'] != null && (mObj['nombre'] as String).isNotEmpty
            ? 'Vehículo (${mObj['nombre']})'
            : 'Unidad Vehicular');

    final String finalModelo = parsedModelo.isNotEmpty
        ? parsedModelo
        : 'ID #$idUnidadReal';

    final String finalPatente = parsedPatente.isNotEmpty
        ? parsedPatente
        : 'U-$idUnidadReal';

    return Unidad(
      id: parsedId,
      patente: finalPatente,
      marca: finalMarca,
      modelo: finalModelo,
      tipo: parsedTipo,
      estado: parsedEstado,
      idMovilAsignado: parsedMovilId,
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
