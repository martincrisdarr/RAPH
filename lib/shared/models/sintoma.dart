import 'sintoma_categoria.dart';

class Sintoma {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final int? idCategoria;
  final SintomaCategoria? categoria;

  Sintoma({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.idCategoria,
    this.categoria,
  });

  factory Sintoma.fromJson(Map<String, dynamic> json) {
    return Sintoma(
      id: json['id'] ?? json['idsintoma'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      idCategoria: json['idsintomacategoria'] ?? json['categoria']?['id'],
      categoria: json['categoria'] != null
          ? SintomaCategoria.fromJson(json['categoria'])
          : null,
    );
  }
}
