import 'sintoma_categoria.dart';

class Sintoma {
  final int id;
  final String codigo;
  final String? codigoColor;
  final String nombre;
  final String? descripcion;
  final int? idCategoria;
  final SintomaCategoria? categoria;
  final String? criterioRojo;
  final String? criterioAmarillo;
  final String? criterioVerde;
  final bool llamarPolicia;
  final bool llamarBomberos;
  final bool llamarDefensaCivil;
  final bool llamarJefatura;

  Sintoma({
    required this.id,
    required this.codigo,
    this.codigoColor,
    required this.nombre,
    this.descripcion,
    this.idCategoria,
    this.categoria,
    this.criterioRojo,
    this.criterioAmarillo,
    this.criterioVerde,
    this.llamarPolicia = false,
    this.llamarBomberos = false,
    this.llamarDefensaCivil = false,
    this.llamarJefatura = false,
  });

  factory Sintoma.fromJson(Map<String, dynamic> json) {
    return Sintoma(
      id: json['id'] ?? json['idsintoma'] ?? 0,
      codigo: json['codigo'] ?? '',
      codigoColor: json['codigo_color'] ?? json['codigoColor'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      idCategoria: json['idsintomacategoria'] ?? json['categoria']?['id'],
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
    );
  }
}
