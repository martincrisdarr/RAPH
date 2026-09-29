import 'sintoma_categoria.dart';
import 'sintoma_pregunta.dart';
import 'sintoma_instruccion.dart';

class SintomaFormulario {
  final int id;
  final String codigo;
  final String? codigoColor;
  final String nombre;
  final String? descripcion;
  final SintomaCategoria? categoria;
  final String? criterioRojo;
  final String? criterioAmarillo;
  final String? criterioVerde;
  final bool llamarPolicia;
  final bool llamarBomberos;
  final bool llamarDefensaCivil;
  final bool llamarJefatura;
  final List<SintomaPregunta> preguntas;
  final List<SintomaInstruccion> instrucciones;

  SintomaFormulario({
    required this.id,
    required this.codigo,
    this.codigoColor,
    required this.nombre,
    this.descripcion,
    this.categoria,
    this.criterioRojo,
    this.criterioAmarillo,
    this.criterioVerde,
    this.llamarPolicia = false,
    this.llamarBomberos = false,
    this.llamarDefensaCivil = false,
    this.llamarJefatura = false,
    required this.preguntas,
    this.instrucciones = const [],
  });

  factory SintomaFormulario.fromJson(Map<String, dynamic> json) {
    var rawPreguntas = json['preguntas'] as List? ?? [];
    List<SintomaPregunta> preguntasList =
        rawPreguntas.map((p) => SintomaPregunta.fromJson(p)).toList();

    var rawInstrucciones = json['instrucciones'] as List? ?? [];
    List<SintomaInstruccion> instruccionesList =
        rawInstrucciones.map((i) => SintomaInstruccion.fromJson(i)).toList();

    return SintomaFormulario(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      codigoColor: json['codigo_color'] ?? json['codigoColor'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      categoria: json['categoria'] != null
          ? SintomaCategoria.fromJson(json['categoria'])
          : null,
      criterioRojo: json['criterio_rojo'] ?? json['criterioRojo'],
      criterioAmarillo: json['criterio_amarillo'] ?? json['criterioAmarillo'],
      criterioVerde: json['criterio_verde'] ?? json['criterioVerde'],
      llamarPolicia: (json['llamar_policia'] == 1 || json['llamar_policia'] == true),
      llamarBomberos: (json['llamar_bomberos'] == 1 || json['llamar_bomberos'] == true),
      llamarDefensaCivil: (json['llamar_defensacivil'] == 1 || json['llamar_defensacivil'] == true),
      llamarJefatura: (json['llamar_jefatura'] == 1 || json['llamar_jefatura'] == true),
      preguntas: preguntasList,
      instrucciones: instruccionesList,
    );
  }
}
