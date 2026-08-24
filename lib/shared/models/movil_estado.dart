class MovilEstado {
  final int idmovilEstado;
  final String nombre;
  final String? descripcion;
  final int orden;
  final int activo;

  MovilEstado({
    required this.idmovilEstado,
    required this.nombre,
    this.descripcion,
    this.orden = 1,
    this.activo = 1,
  });

  factory MovilEstado.fromJson(Map<String, dynamic> json) {
    return MovilEstado(
      idmovilEstado: int.tryParse(json['idmovil_estado']?.toString() ?? '0') ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      orden: int.tryParse(json['orden']?.toString() ?? '1') ?? 1,
      activo: int.tryParse(json['activo']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idmovil_estado': idmovilEstado,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
      'activo': activo,
    };
  }
}
