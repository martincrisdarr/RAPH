import 'package:flutter/material.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/models/sintoma.dart';
import '../../../shared/models/sintoma_formulario.dart';
import '../../../shared/models/sintoma_pregunta.dart';
import '../../../shared/services/victima_sintomas_service.dart';
import '../../ingreso/controllers/ingreso_controller.dart';
import 'sintoma_search_panel.dart';
import 'sintoma_form_panel.dart';

class VictimaSintomasSection extends StatefulWidget {
  final int index;
  final VictimaData victima;

  const VictimaSintomasSection({
    super.key,
    required this.index,
    required this.victima,
  });

  @override
  State<VictimaSintomasSection> createState() => _VictimaSintomasSectionState();
}

class _VictimaSintomasSectionState extends State<VictimaSintomasSection> {
  final IngresoController _ingresoController = IngresoController();
  List<Sintoma> _sintomas = [];
  bool _isLoadingSymptoms = true;

  Sintoma? _sintomaSeleccionado;
  SintomaFormulario? _formulario;
  bool _isLoadingForm = false;
  String? _errorMessage;

  // Respuestas locales asociadas a preguntas: Map<idPregunta, valor>
  final Map<int, dynamic> _respuestas = {};

  @override
  void initState() {
    super.initState();
    _cargarCatalogoSintomas();
  }

  Future<void> _cargarCatalogoSintomas() async {
    setState(() {
      _isLoadingSymptoms = true;
    });
    final list = await VictimaSintomasService.obtenerSintomas();
    if (mounted) {
      setState(() {
        _sintomas = list;
        _isLoadingSymptoms = false;
      });

      if (widget.victima.sintomasSeleccionados.isNotEmpty && _sintomaSeleccionado == null) {
        final selectedName = widget.victima.sintomasSeleccionados.first;
        Sintoma? found;
        for (var s in list) {
          if ((widget.victima.idSintomaSeleccionadoId != null && s.id == widget.victima.idSintomaSeleccionadoId) ||
              s.nombre == selectedName) {
            found = s;
            break;
          }
        }
        if (found != null) {
          _restablecerSintomaSeleccionadoSinSync(found);
        }
      }
    }
  }

  Future<void> _restablecerSintomaSeleccionadoSinSync(Sintoma sintoma) async {
    setState(() {
      _sintomaSeleccionado = sintoma;
      _formulario = null;
      _isLoadingForm = true;
      _errorMessage = null;
      widget.victima.idSintomaSeleccionadoId = sintoma.id;
    });

    final form = await VictimaSintomasService.obtenerFormularioSintoma(sintoma.id);
    if (mounted) {
      setState(() {
        _formulario = form;
        _isLoadingForm = false;
      });
    }
  }

  Future<void> _onSintomaSelected(Sintoma sintoma) async {
    // Si ya está seleccionado, permitir deseleccionar
    if (_sintomaSeleccionado?.id == sintoma.id) {
      setState(() {
        _sintomaSeleccionado = null;
        _formulario = null;
        _isLoadingForm = false;
        _errorMessage = null;
        _respuestas.clear();
        widget.victima.idSintomaSeleccionadoId = null;
        widget.victima.idVictimaSintomaActivo = null;
      });
      _ingresoController.updateVictima(widget.index, sintomas: []);
      return;
    }

    setState(() {
      _sintomaSeleccionado = sintoma;
      _formulario = null;
      _isLoadingForm = true;
      _errorMessage = null;
      _respuestas.clear();
      widget.victima.idSintomaSeleccionadoId = sintoma.id;
    });

    // 1. Actualizar lista de nombres de síntomas seleccionados en VictimaData para triage/resumen (solo 1 síntoma)
    _ingresoController.updateVictima(widget.index, sintomas: [sintoma.nombre]);

    // 2. Persistir o recuperar la evaluación activa si ya hay un idVictima asignado
    const userHandle = 'mdarroux';

    if (widget.victima.idVictima != null) {
      if (widget.victima.idVictimaEvaluacion == null) {
        final idEval = await VictimaSintomasService.crearEvaluacion(
          widget.victima.idVictima!,
          userHandle,
        );
        if (idEval != null) {
          widget.victima.idVictimaEvaluacion = idEval;
        }
      }

      // 3. Agregar el síntoma a la evaluación
      if (widget.victima.idVictimaEvaluacion != null) {
        final vsId = await VictimaSintomasService.agregarSintoma(
          idEvaluacion: widget.victima.idVictimaEvaluacion!,
          idSintoma: sintoma.id,
          origen: 'OPERADOR',
          usuario: userHandle,
        );
        widget.victima.idVictimaSintomaActivo = vsId;
      }
    }

    // 4. Cargar la estructura del formulario dinámico
    final form = await VictimaSintomasService.obtenerFormularioSintoma(sintoma.id);

    if (mounted) {
      setState(() {
        _formulario = form;
        _isLoadingForm = false;
        if (form == null) {
          _errorMessage = 'No se pudo cargar la asistencia para este síntoma.';
        }
      });
    }
  }

  Future<void> _handleRespuestaChanged(SintomaPregunta pregunta, dynamic valor) async {
    setState(() {
      _respuestas[pregunta.id] = valor;
    });

    const userHandle = 'mdarroux';

    // Persistir incrementalmente en backend si la evaluación y el síntoma están registrados
    if (widget.victima.idVictimaEvaluacion != null &&
        widget.victima.idVictimaSintomaActivo != null) {
      
      int? opcionId;
      if (pregunta.tipo == 'SINGLE_OPTION' && valor is int) {
        opcionId = valor;
      }

      await VictimaSintomasService.guardarRespuesta(
        idEvaluacion: widget.victima.idVictimaEvaluacion!,
        idVictimaSintoma: widget.victima.idVictimaSintomaActivo!,
        idSintomaPregunta: pregunta.id,
        idSintomaPreguntaOpcion: opcionId,
        valor: valor,
        usuario: userHandle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna Izquierda: Buscador + Chips de Síntomas (50%)
              Expanded(
                flex: 1,
                child: SintomaSearchPanel(
                  sintomas: _sintomas,
                  sintomaSeleccionado: _sintomaSeleccionado,
                  isLoading: _isLoadingSymptoms,
                  onSintomaSelected: _onSintomaSelected,
                ),
              ),
              const SizedBox(width: 16),
              // Columna Derecha: Formulario Dinámico de Asistencia (50%)
              Expanded(
                flex: 1,
                child: SintomaFormPanel(
                  sintomaSeleccionado: _sintomaSeleccionado,
                  formulario: _formulario,
                  isLoadingForm: _isLoadingForm,
                  errorMessage: _errorMessage,
                  respuestas: _respuestas,
                  onRespuestaChanged: _handleRespuestaChanged,
                ),
              ),
            ],
          );
        } else {
          // Diseño apilado para pantallas reducidas
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SintomaSearchPanel(
                sintomas: _sintomas,
                sintomaSeleccionado: _sintomaSeleccionado,
                isLoading: _isLoadingSymptoms,
                onSintomaSelected: _onSintomaSelected,
              ),
              const SizedBox(height: 16),
              SintomaFormPanel(
                sintomaSeleccionado: _sintomaSeleccionado,
                formulario: _formulario,
                isLoadingForm: _isLoadingForm,
                errorMessage: _errorMessage,
                respuestas: _respuestas,
                onRespuestaChanged: _handleRespuestaChanged,
              ),
            ],
          );
        }
      },
    );
  }
}
