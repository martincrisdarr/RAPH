class Configuracion {
  final int idconfiguracion;
  final int idconfiguraciontipo;
  final String nombre;
  final String descripcion;
  final int activo;
  final int tipoActivo;
  final int orden;

  Configuracion({
    required this.idconfiguracion,
    required this.idconfiguraciontipo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.tipoActivo,
    required this.orden,
  });

  factory Configuracion.fromJson(Map<String, dynamic> json) {
    return Configuracion(
      idconfiguracion: json['idconfiguracion'] as int,
      idconfiguraciontipo: json['idconfiguraciontipo'] as int,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      activo: json['activo'] as int? ?? 1,
      tipoActivo: json['tipo_activo'] as int? ?? 1,
      orden: json['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idconfiguracion': idconfiguracion,
      'idconfiguraciontipo': idconfiguraciontipo,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'tipo_activo': tipoActivo,
      'orden': orden,
    };
  }

  // Comparamos por id para que los Dropdown funcionen correctamente si pasas listas diferentes.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Configuracion && other.idconfiguracion == idconfiguracion;
  }

  @override
  int get hashCode => idconfiguracion.hashCode;
}
