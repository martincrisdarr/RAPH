class Unidad {
  final String id;
  final String patente;
  final String marca;
  final String modelo;
  final String tipo; // e.g. "Ambulancia"
  final String estado; // e.g. "Activo", "Mantenimiento", "Fuera de Servicio"
  final String? idMovilAsignado; // ID del móvil actualmente asignado a este vehículo
  final int? idMovilUnidad; // ID del registro en ser_sien_dsp_movil_unidad
  final String? nombreMovilAsignado; // Nombre del móvil (ej: "Móvil 1")
  final String? imagen;
  final int? anio;

  Unidad({
    required this.id,
    required this.patente,
    required this.marca,
    required this.modelo,
    required this.tipo,
    required this.estado,
    this.idMovilAsignado,
    this.idMovilUnidad,
    this.nombreMovilAsignado,
    this.imagen,
    this.anio,
  });

  /// Mapea los datos directamente desde el endpoint externo:
  /// https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_veh_vie_unidad_despacho?filter[id_tipo_unidad]=11
  factory Unidad.fromJson(Map<String, dynamic> json) {
    final String parsedId = (json['id_unidad'] ?? json['id'] ?? '').toString();
    final String parsedPatente = (json['dominio'] ?? json['patente'] ?? '').toString().trim();
    final String parsedMarca = (json['marca'] ?? '').toString().trim();
    final String parsedModelo = (json['modelo'] ?? '').toString().trim();
    final String parsedTipo = (json['tipo'] ?? 'Ambulancia').toString().trim();

    final String parsedEstado;
    if (json['estado'] is String && (json['estado'] as String).trim().isNotEmpty) {
      parsedEstado = (json['estado'] as String).trim();
    } else if (json['activo'] != null) {
      final isActivo = json['activo'] == 1 || json['activo'] == '1' || json['activo'] == true;
      parsedEstado = isActivo ? 'Activo' : 'Fuera de Servicio';
    } else {
      parsedEstado = 'Activo';
    }

    final String? parsedMovilId = (json['idmovil'] ?? json['idMovilAsignado'])?.toString();
    final int? parsedMovilUnidadId = json['idmovilunidad'] is int
        ? json['idmovilunidad']
        : int.tryParse(json['idmovilunidad']?.toString() ?? json['idMovilUnidad']?.toString() ?? '');
    final String? parsedMovilNombre = (json['movil'] ?? json['nombreMovilAsignado'])?.toString();
    final String? parsedImagen = json['imagen']?.toString();

    final int? parsedAnio = json['anio'] is int
        ? json['anio']
        : int.tryParse(json['anio']?.toString() ?? '');

    return Unidad(
      id: parsedId,
      patente: parsedPatente.isNotEmpty ? parsedPatente : 'U-$parsedId',
      marca: parsedMarca.isNotEmpty ? parsedMarca : 'Ambulancia',
      modelo: parsedModelo.isNotEmpty ? parsedModelo : 'ID #$parsedId',
      tipo: parsedTipo.isNotEmpty ? parsedTipo : 'Ambulancia',
      estado: parsedEstado,
      idMovilAsignado: (parsedMovilId != null && parsedMovilId != 'null' && parsedMovilId.isNotEmpty) ? parsedMovilId : null,
      idMovilUnidad: parsedMovilUnidadId,
      nombreMovilAsignado: (parsedMovilNombre != null && parsedMovilNombre != 'null' && parsedMovilNombre.isNotEmpty) ? parsedMovilNombre : null,
      imagen: (parsedImagen != null && parsedImagen.isNotEmpty) ? parsedImagen : null,
      anio: parsedAnio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_unidad': id,
      'patente': patente,
      'dominio': patente,
      'marca': marca,
      'modelo': modelo,
      'tipo': tipo,
      'estado': estado,
      'idMovilAsignado': idMovilAsignado,
      'idmovil': idMovilAsignado,
      'idMovilUnidad': idMovilUnidad,
      'idmovilunidad': idMovilUnidad,
      'nombreMovilAsignado': nombreMovilAsignado,
      'movil': nombreMovilAsignado,
      'imagen': imagen,
      'anio': anio,
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
    int? idMovilUnidad,
    String? nombreMovilAsignado,
    String? imagen,
    int? anio,
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
      idMovilUnidad: clearMovil ? null : (idMovilUnidad ?? this.idMovilUnidad),
      nombreMovilAsignado: clearMovil ? null : (nombreMovilAsignado ?? this.nombreMovilAsignado),
      imagen: imagen ?? this.imagen,
      anio: anio ?? this.anio,
    );
  }
}
