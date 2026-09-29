class SintomaInstruccion {
  final int id;
  final String? codigo;
  final String instruccion;
  final int orden;

  SintomaInstruccion({
    required this.id,
    this.codigo,
    required this.instruccion,
    this.orden = 0,
  });

  factory SintomaInstruccion.fromJson(Map<String, dynamic> json) {
    return SintomaInstruccion(
      id: json['id'] ?? json['idsintomainstruccion'] ?? 0,
      codigo: json['codigo'],
      instruccion: json['instruccion'] ?? '',
      orden: json['orden'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'instruccion': instruccion,
    'orden': orden,
  };
}
