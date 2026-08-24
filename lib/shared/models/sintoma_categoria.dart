class SintomaCategoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? icono;

  SintomaCategoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
  });

  factory SintomaCategoria.fromJson(Map<String, dynamic> json) {
    return SintomaCategoria(
      id: json['id'] ?? json['idsintomacategoria'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      icono: json['icono'],
    );
  }
}
