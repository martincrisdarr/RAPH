class SintomaPreguntaOpcion {
  final int id;
  final String valor;
  final String descripcion;

  SintomaPreguntaOpcion({
    required this.id,
    required this.valor,
    required this.descripcion,
  });

  factory SintomaPreguntaOpcion.fromJson(Map<String, dynamic> json) {
    return SintomaPreguntaOpcion(
      id: json['id'] ?? json['idsintomapreguntaopcion'] ?? 0,
      valor: json['valor'] ?? '',
      descripcion: json['descripcion'] ?? '',
    );
  }
}

class SintomaPregunta {
  final int id;
  final String codigo;
  final String pregunta;
  final String tipo; // BOOLEAN, SINGLE_OPTION, MULTIPLE_OPTION, TEXT, NUMBER, TIME, DURATION
  final bool obligatoria;
  final int orden;
  final List<SintomaPreguntaOpcion> opciones;

  SintomaPregunta({
    required this.id,
    required this.codigo,
    required this.pregunta,
    required this.tipo,
    required this.obligatoria,
    required this.orden,
    required this.opciones,
  });

  factory SintomaPregunta.fromJson(Map<String, dynamic> json) {
    var rawOpciones = json['opciones'] as List? ?? [];
    List<SintomaPreguntaOpcion> opcionesList =
        rawOpciones.map((opc) => SintomaPreguntaOpcion.fromJson(opc)).toList();

    return SintomaPregunta(
      id: json['id'] ?? json['idsintomapregunta'] ?? 0,
      codigo: json['codigo'] ?? '',
      pregunta: json['pregunta'] ?? '',
      tipo: (json['tipo'] ?? 'TEXT').toString().toUpperCase(),
      obligatoria: json['obligatoria'] == true || json['obligatoria'] == 1,
      orden: json['orden'] ?? 0,
      opciones: opcionesList,
    );
  }
}
