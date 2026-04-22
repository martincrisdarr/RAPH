class Localidad {
  final int id;
  final String descripcion;
  final String nombreCompleto;
  final String categoria;
  final String? provinciaId;
  final String? provinciaNombre;

  Localidad({
    required this.id,
    required this.descripcion,
    required this.nombreCompleto,
    required this.categoria,
    this.provinciaId,
    this.provinciaNombre,
  });

  factory Localidad.fromJson(Map<String, dynamic> json) {
    return Localidad(
      id: json['id'] as int,
      descripcion: json['descripcion'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      provinciaId: json['provincia_id']?.toString(),
      provinciaNombre: json['provincia_nombre'] as String?,
    );
  }

  @override
  String toString() => descripcion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Localidad && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
