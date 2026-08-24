import 'package:flutter/material.dart';
import '../../../shared/models/sintoma.dart';
import '../../../shared/models/sintoma_formulario.dart';
import '../../../shared/models/sintoma_pregunta.dart';
import 'pregunta_field.dart';

class SintomaFormPanel extends StatelessWidget {
  final Sintoma? sintomaSeleccionado;
  final SintomaFormulario? formulario;
  final bool isLoadingForm;
  final String? errorMessage;
  final Map<int, dynamic> respuestas;
  final Function(SintomaPregunta pregunta, dynamic valor) onRespuestaChanged;

  const SintomaFormPanel({
    super.key,
    this.sintomaSeleccionado,
    this.formulario,
    required this.isLoadingForm,
    this.errorMessage,
    required this.respuestas,
    required this.onRespuestaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (sintomaSeleccionado == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, size: 36, color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'Seleccione un síntoma o busque\npara ver el proceso de asistencia',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoadingForm) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(height: 12),
              Text(
                'Cargando preguntas de asistencia...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encabezado del síntoma seleccionado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.medical_services_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sintomaSeleccionado!.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (formulario?.descripcion != null && formulario!.descripcion!.isNotEmpty)
                      Text(
                        formulario!.descripcion!,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Cuerpo con la lista de preguntas
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: (formulario == null || formulario!.preguntas.isEmpty)
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No hay preguntas asociadas a este síntoma.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: formulario!.preguntas.map((preg) {
                    return PreguntaField(
                      pregunta: preg,
                      valorActual: respuestas[preg.id],
                      onChanged: (val) => onRespuestaChanged(preg, val),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
