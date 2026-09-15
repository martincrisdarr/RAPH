import 'package:raph/shared/models/movil.dart';

class Jornada {
  final int? idjornada;
  final String user;
  final int idmovil;
  final String fechaInicio;
  final String? fechaFin;
  final int estado; // 1 = Activa, 0 = Finalizada
  final int? kmInicio;
  final int? kmFin;
  final String? rol;
  final String? observaciones;
  final Movil? movil;

  Jornada({
    this.idjornada,
    required this.user,
    required this.idmovil,
    required this.fechaInicio,
    this.fechaFin,
    this.estado = 1,
    this.kmInicio,
    this.kmFin,
    this.rol,
    this.observaciones,
    this.movil,
  });

  bool get estaActiva => estado == 1 && (fechaFin == null || fechaFin!.isEmpty);

  factory Jornada.fromJson(Map<String, dynamic> json) {
    return Jornada(
      idjornada: json['idjornada'] != null ? int.tryParse(json['idjornada'].toString()) : null,
      user: json['user']?.toString() ?? '',
      idmovil: json['idmovil'] != null ? int.parse(json['idmovil'].toString()) : 0,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString(),
      estado: json['estado'] != null ? int.tryParse(json['estado'].toString()) ?? 1 : 1,
      kmInicio: json['km_inicio'] != null ? int.tryParse(json['km_inicio'].toString()) : null,
      kmFin: json['km_fin'] != null ? int.tryParse(json['km_fin'].toString()) : null,
      rol: json['rol']?.toString(),
      observaciones: json['observaciones']?.toString(),
      movil: json['movil'] != null && json['movil'] is Map<String, dynamic>
          ? Movil.fromJson(json['movil'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idjornada != null) 'idjornada': idjornada,
      'user': user,
      'idmovil': idmovil,
      'fecha_inicio': fechaInicio,
      if (fechaFin != null) 'fecha_fin': fechaFin,
      'estado': estado,
      if (kmInicio != null) 'km_inicio': kmInicio,
      if (kmFin != null) 'km_fin': kmFin,
      if (rol != null) 'rol': rol,
      if (observaciones != null) 'observaciones': observaciones,
    };
  }
}
