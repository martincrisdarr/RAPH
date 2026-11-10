class Hospital {
  final int idhospital;
  final String nombre;
  final String direccion;
  final String localidad;
  final String telefono;
  final String complejidad;
  final double? latitud;
  final double? longitud;
  final int activo;
  final double? distanciaKm;
  final bool esMasCercano;

  const Hospital({
    required this.idhospital,
    required this.nombre,
    required this.direccion,
    this.localidad = 'Neuquén',
    this.telefono = '',
    this.complejidad = 'General',
    this.latitud,
    this.longitud,
    this.activo = 1,
    this.distanciaKm,
    this.esMasCercano = false,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      idhospital: _parseInt(json['idhospital']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      localidad: (json['localidad'] ?? 'Neuquén').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      complejidad: (json['complejidad'] ?? 'General').toString(),
      latitud: _parseDouble(json['latitud']),
      longitud: _parseDouble(json['longitud']),
      activo: _parseInt(json['activo']) ?? 1,
      distanciaKm: _parseDouble(json['distancia_km']),
      esMasCercano: json['es_mas_cercano'] == true || json['es_mas_cercano'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idhospital': idhospital,
      'nombre': nombre,
      'direccion': direccion,
      'localidad': localidad,
      'telefono': telefono,
      'complejidad': complejidad,
      'latitud': latitud,
      'longitud': longitud,
      'activo': activo,
    };
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '.'));
  }
}

