import 'sintoma_categoria.dart';
import 'sintoma_pregunta.dart';

class SintomaFormulario {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final SintomaCategoria? categoria;
  final List<SintomaPregunta> preguntas;

  SintomaFormulario({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.categoria,
    required this.preguntas,
  });

  factory SintomaFormulario.fromJson(Map<String, dynamic> json) {
    var rawPreguntas = json['preguntas'] as List? ?? [];
    List<SintomaPregunta> preguntasList =
        rawPreguntas.map((p) => SintomaPregunta.fromJson(p)).toList();

    return SintomaFormulario(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      categoria: json['categoria'] != null
          ? SintomaCategoria.fromJson(json['categoria'])
          : null,
      preguntas: preguntasList,
    );
  }
}
