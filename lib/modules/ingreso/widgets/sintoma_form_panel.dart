import 'package:flutter/material.dart';
import '../../../shared/models/sintoma.dart';
import '../../../shared/models/sintoma_formulario.dart';
import '../../../shared/models/sintoma_pregunta.dart';
import 'pregunta_field.dart';

class SintomaFormPanel extends StatefulWidget {
  final Sintoma? sintomaSeleccionado;
  final SintomaFormulario? formulario;
  final bool isLoadingForm;
  final String? errorMessage;
  final Map<int, dynamic> respuestas;
  final Function(SintomaPregunta pregunta, dynamic valor) onRespuestaChanged;
  final ValueChanged<String>? onTriageSelected;
  final String? triageActual;

  const SintomaFormPanel({
    super.key,
    this.sintomaSeleccionado,
    this.formulario,
    required this.isLoadingForm,
    this.errorMessage,
    required this.respuestas,
    required this.onRespuestaChanged,
    this.onTriageSelected,
    this.triageActual,
  });

  @override
  State<SintomaFormPanel> createState() => _SintomaFormPanelState();
}

class _SintomaFormPanelState extends State<SintomaFormPanel> {
  // Paso 0: Preguntas Clave al llamante
  // Paso 1: Categorización (Triage) y Medios de Despacho
  int _currentStep = 0;
  int? _lastSintomaId;

  @override
  void didUpdateWidget(covariant SintomaFormPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el síntoma seleccionado, reiniciar el wizard al Paso 0 (Preguntas)
    if (widget.sintomaSeleccionado?.id != _lastSintomaId) {
      _lastSintomaId = widget.sintomaSeleccionado?.id;
      _currentStep = 0;
    }
  }

  Color _getColorForSeries(String? colorStr) {
    switch (colorStr?.toUpperCase()) {
      case 'ROJO':
        return Colors.redAccent.shade400;
      case 'AMARILLO':
        return Colors.amber.shade600;
      case 'VERDE':
        return Colors.greenAccent.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
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
    if (widget.sintomaSeleccionado == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 44, color: Colors.white24),
              SizedBox(height: 14),
              Text(
                'Seleccione un síntoma de la lista para iniciar\nel interrogatorio clínico y posterior categorización',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isLoadingForm) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando preguntas de la ficha oficial...',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            widget.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      );
    }

    final seriesColor = _getColorForSeries(
      widget.formulario?.codigoColor ?? widget.sintomaSeleccionado!.codigoColor,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera con Ficha Activa y Mini Stepper del Wizard
          _buildWizardHeader(theme, seriesColor),

          // 2. Contenido dinámico según el paso actual
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _currentStep == 0
                ? _buildStep1Preguntas(theme, seriesColor)
                : _buildStep2CategorizacionYMedios(theme, seriesColor),
          ),
        ],
      ),
    );
  }

  /// Encabezado con información del síntoma y el Stepper interactivo
  Widget _buildWizardHeader(ThemeData theme, Color seriesColor) {
    final form = widget.formulario;
    final sintoma = widget.sintomaSeleccionado!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: seriesColor.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: seriesColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila del Motivo Activo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: seriesColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: seriesColor.withValues(alpha: 0.8)),
                ),
                child: Text(
                  form?.codigo ?? sintoma.codigo,
                  style: TextStyle(
                    color: seriesColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form?.nombre ?? sintoma.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ficha Oficial • Serie ${form?.codigoColor ?? sintoma.codigoColor ?? ""}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pestañas del Stepper (Paso 1 vs Paso 2)
          Row(
            children: [
              Expanded(
                child: _buildStepTab(
                  stepIndex: 0,
                  icon: Icons.contact_support_rounded,
                  title: '1. PREGUNTAS',
                  subtitle: 'Screening al llamante',
                  isActive: _currentStep == 0,
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStepTab(
                  stepIndex: 1,
                  icon: Icons.local_shipping_rounded,
                  title: '2. CATEGORIZACIÓN Y MEDIOS',
                  subtitle: 'Triage y soporte vital',
                  isActive: _currentStep == 1,
                  activeColor: seriesColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTab({
    required int stepIndex,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentStep = stepIndex;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : Colors.white12,
            width: isActive ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : Colors.white54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? activeColor : Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================================================
  /// PASO 1: PREGUNTAS CLAVE AL LLAMANTE (Screening Telefónico)
  /// =========================================================================
  Widget _buildStep1Preguntas(ThemeData theme, Color seriesColor) {
    final preguntas = widget.formulario?.preguntas ?? [];
    final int totalPreguntas = preguntas.length;
    final int respondidas = widget.respuestas.keys.where((k) => preguntas.any((p) => p.id == k)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicador de avance del interrogatorio
        Row(
          children: [
            const Icon(Icons.playlist_add_check_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Interrogatorio telefónico ($respondidas de $totalPreguntas preguntas completadas)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: totalPreguntas > 0 ? (respondidas / totalPreguntas) : 0,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              respondidas == totalPreguntas && totalPreguntas > 0
                  ? Colors.greenAccent
                  : theme.colorScheme.primary,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 16),

        // Lista de preguntas
        if (preguntas.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'Esta ficha no requiere preguntas de screening adicionales.\nPuede continuar directamente a la categorización y medios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
          )
        else
          ...preguntas.map((preg) {
            return PreguntaField(
              pregunta: preg,
              valorActual: widget.respuestas[preg.id],
              onChanged: (val) => widget.onRespuestaChanged(preg, val),
            );
          }),

        const SizedBox(height: 16),

        // Botón destacado para avanzar al Paso 2
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _currentStep = 1;
            });
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text(
            'CONTINUAR A CATEGORIZACIÓN Y MEDIOS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  /// =========================================================================
  /// PASO 2: CATEGORIZACIÓN (TRIAGE) Y MEDIOS / INSTRUCCIONES DE PRE-ARRIBO
  /// =========================================================================
  Widget _buildStep2CategorizacionYMedios(ThemeData theme, Color seriesColor) {
    final form = widget.formulario;
    final instrucciones = form?.instrucciones ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón superior para volver al interrogatorio
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 0;
              });
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Volver a Preguntas de Screening'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 1. BLOQUE DE CATEGORIZACIÓN DE TRIAGE
        _buildCategorizacionCard(theme, form),
        const SizedBox(height: 18),

        // 2. BLOQUE DE MEDIOS E INSTRUCCIONES DE PRE-ARRIBO
        _buildMediosEInstruccionesCard(theme, instrucciones),
      ],
    );
  }

  /// Tarjeta de Asignación y Criterios de Triage
  Widget _buildCategorizacionCard(ThemeData theme, SintomaFormulario? form) {
    final triageVictima = widget.triageActual?.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.traffic_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CATEGORIZACIÓN Y TRIAGE DE LA VÍCTIMA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (triageVictima != null && triageVictima.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getColorForSeries(triageVictima).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getColorForSeries(triageVictima)),
                  ),
                  child: Text(
                    'ACTUAL: ${triageVictima.toUpperCase()}',
                    style: TextStyle(
                      color: _getColorForSeries(triageVictima),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Criterios extraídos de la Ficha
          if (form != null) ...[
            if (form.criterioRojo != null && form.criterioRojo!.isNotEmpty) ...[
              _buildCriterionRow(
                color: Colors.redAccent.shade400,
                label: 'Criterio para Código Rojo (Emergencia crítica):',
                text: form.criterioRojo!,
              ),
              const SizedBox(height: 8),
            ],
            if (form.criterioAmarillo != null && form.criterioAmarillo!.isNotEmpty) ...[
              _buildCriterionRow(
                color: Colors.amber.shade600,
                label: 'Criterio para Código Amarillo (Urgencia):',
                text: form.criterioAmarillo!,
              ),
              const SizedBox(height: 8),
            ],
            if (form.criterioVerde != null && form.criterioVerde!.isNotEmpty) ...[
              _buildCriterionRow(
                color: Colors.greenAccent.shade700,
                label: 'Criterio para Código Verde (No urgente):',
                text: form.criterioVerde!,
              ),
              const SizedBox(height: 8),
            ],
          ],

          const SizedBox(height: 6),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),

          // Selector directo de Triage
          const Text(
            'Seleccione el Triage determinado para esta víctima:',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildLargeTriageOption(
                  colorName: 'Rojo',
                  label: 'ROJO',
                  sublabel: 'Emergencia',
                  color: Colors.redAccent.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLargeTriageOption(
                  colorName: 'Amarillo',
                  label: 'AMARILLO',
                  sublabel: 'Urgencia',
                  color: Colors.amber.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLargeTriageOption(
                  colorName: 'Verde',
                  label: 'VERDE',
                  sublabel: 'No urgente',
                  color: Colors.greenAccent.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTriageOption({
    required String colorName,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    final isSelected = widget.triageActual?.toLowerCase() == colorName.toLowerCase();

    return Material(
      color: isSelected ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: widget.onTriageSelected != null ? () => widget.onTriageSelected!(colorName) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de Medios e Instrucciones de Pre-Arribo
  Widget _buildMediosEInstruccionesCard(ThemeData theme, List<dynamic> instrucciones) {
    final triage = widget.triageActual?.toLowerCase();

    String mediosTexto;
    Color mediosColor;
    IconData mediosIcon;

    if (triage == 'rojo') {
      mediosTexto = 'DESPACHO INMEDIATO: Móvil de Alta Complejidad (USI) en Código Rojo con balizas y sirenas.';
      mediosColor = Colors.redAccent.shade400;
      mediosIcon = Icons.emergency_rounded;
    } else if (triage == 'amarillo') {
      mediosTexto = 'DESPACHO PRIORITARIO: Unidad de Traslado / Soporte de Urgencia (UTE).';
      mediosColor = Colors.amber.shade600;
      mediosIcon = Icons.warning_amber_rounded;
    } else if (triage == 'verde') {
      mediosTexto = 'DEMORA DIFERIBLE: Móvil de Baja Complejidad o Consulta médica programada.';
      mediosColor = Colors.greenAccent.shade700;
      mediosIcon = Icons.check_circle_outline_rounded;
    } else {
      mediosTexto = 'Asigne el triage arriba para obtener la recomendación de medios móviles.';
      mediosColor = Colors.white54;
      mediosIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Medios de Despacho
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mediosColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: mediosColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(mediosIcon, color: mediosColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mediosTexto,
                    style: TextStyle(
                      color: mediosColor == Colors.white54 ? Colors.white70 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Instrucciones de Pre-Arribo
          Row(
            children: [
              Icon(Icons.record_voice_over_rounded, color: Colors.amber.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                'INSTRUCCIONES DE PRE-ARRIBO (DICTAR AL LLAMANTE)',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (instrucciones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No hay instrucciones de soporte vital específicas para este motivo.\nMantenga la calma del llamante y confirme domicilio.',
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
              ),
            )
          else
            ...instrucciones.map((inst) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade400, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${inst.orden}',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        inst.instruccion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCriterionRow({required Color color, required String label, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
