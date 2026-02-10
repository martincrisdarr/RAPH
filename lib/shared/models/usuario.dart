class Usuario {
  // Constantes para campos JSON
  static const String PARAM_USER = "user";
  static const String PARAM_PASS = "pass";
  static const String PARAM_NOMBRE = "nombre";
  static const String PARAM_APELLIDO = "apellido";
  static const String PARAM_DNI = "dni";
  static const String PARAM_IMAGEN = "imagen";
  static const String PARAM_MAIL = "mail";
  static const String PARAM_ID_ORGANISMO = "idorganismo";
  static const String PARAM_ACTIVO = "activo";
  static const String PARAM_VERIFICATION_CODE = "verification_code";
  static const String PARAM_ES_HUMANO = "es_humano";

  final String user;
  final String nombre;
  final String apellido;
  final int dni;
  final String? imagen;
  final String mail;
  final int idOrganismo;
  final int activo;
  final String? verificationCode;
  final int esHumano;
  String? passPlaintxt;

  Usuario({
    required this.user,
    required this.nombre,
    required this.apellido,
    required this.dni,
    this.imagen,
    required this.mail,
    required this.idOrganismo,
    required this.activo,
    this.verificationCode,
    required this.esHumano,
    this.passPlaintxt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      user: json[PARAM_USER] ?? '',
      nombre: json[PARAM_NOMBRE] ?? '',
      apellido: json[PARAM_APELLIDO] ?? '',
      dni: json[PARAM_DNI] is int
          ? json[PARAM_DNI]
          : int.tryParse(json[PARAM_DNI]?.toString() ?? '0') ?? 0,
      imagen: json[PARAM_IMAGEN],
      mail: json[PARAM_MAIL] ?? '',
      idOrganismo: json[PARAM_ID_ORGANISMO] is int
          ? json[PARAM_ID_ORGANISMO]
          : int.tryParse(json[PARAM_ID_ORGANISMO]?.toString() ?? '0') ?? 0,
      activo: json[PARAM_ACTIVO] is int
          ? json[PARAM_ACTIVO]
          : int.tryParse(json[PARAM_ACTIVO]?.toString() ?? '1') ?? 1,
      verificationCode: json[PARAM_VERIFICATION_CODE],
      esHumano: json[PARAM_ES_HUMANO] is int
          ? json[PARAM_ES_HUMANO]
          : int.tryParse(json[PARAM_ES_HUMANO]?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      PARAM_USER: user,
      PARAM_NOMBRE: nombre,
      PARAM_APELLIDO: apellido,
      PARAM_DNI: dni,
      PARAM_IMAGEN: imagen,
      PARAM_MAIL: mail,
      PARAM_ID_ORGANISMO: idOrganismo,
      PARAM_ACTIVO: activo,
      PARAM_VERIFICATION_CODE: verificationCode,
      PARAM_ES_HUMANO: esHumano,
    };
  }
}

