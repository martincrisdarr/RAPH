import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/models/sintoma.dart';
import '../../../shared/models/sintoma_formulario.dart';
import '../../../shared/models/sintoma_pregunta.dart';
import '../../../shared/services/victima_sintomas_service.dart';
import '../../../shared/services/socket_service.dart';
import '../../ingreso/controllers/ingreso_controller.dart';
import 'sintoma_search_panel.dart';
import 'sintoma_form_panel.dart';
import 'asistente_sintomas_panel.dart';

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

  // 0 = Asignación Rápida (Directa), 1 = Asistente Guiado (Por Preguntas)
  int _modoSeleccion = 0;

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

  @override
  void dispose() {
    super.dispose();
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

  bool get _isCurrentVictimaLocked {
    final bool isCollaborative = _ingresoController.incidenteActual.idIncidente != null;
    final lockKey = 'victima_${widget.index}';
    return isCollaborative && SocketService().lockedFields.value.containsKey(lockKey);
  }

  Future<void> _onSintomaSelected(Sintoma sintoma) async {
    if (_isCurrentVictimaLocked) return;
    _ingresoController.lockVictima(widget.index);

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

    // 1. Actualizar lista de nombres de síntomas seleccionados en VictimaData para triage/resumen
    final nombreCompleto = '${sintoma.codigo} - ${sintoma.nombre}';
    _ingresoController.updateVictima(widget.index, sintomas: [nombreCompleto]);

    // Asignar automáticamente el triage por defecto de la ficha seleccionada
    final colorTriageBase = sintoma.codigoColor?.toUpperCase() == 'ROJO'
        ? 'Rojo'
        : (sintoma.codigoColor?.toUpperCase() == 'AMARILLO' ? 'Amarillo' : 'Verde');
    _handleTriageSelected(colorTriageBase, mostrarNotificacion: true);

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

  void _handleAsignarFichaDesdeAsistente(Sintoma sintoma, String triage) {
    if (_isCurrentVictimaLocked) return;
    _ingresoController.lockVictima(widget.index);
    _onSintomaSelected(sintoma);
    _handleTriageSelected(triage, mostrarNotificacion: true);
    setState(() {
      _modoSeleccion = 0; // Conmutar automáticamente a la ficha directa asignada
    });
  }

  void _handleTriageSelected(String color, {bool mostrarNotificacion = true}) {
    if (_isCurrentVictimaLocked) return;
    _ingresoController.lockVictima(widget.index);
    setState(() {
      widget.victima.codigoTriage = color;
    });
    _ingresoController.updateVictima(widget.index, codigoTriage: color);

    final incTriage = _ingresoController.incidenteActual.codigoTriage?.toLowerCase();
    if (color.toLowerCase() == 'rojo') {
      _ingresoController.updateIncidente(codigoTriage: 'Rojo', idConfCodigo: 29);
    } else if (color.toLowerCase() == 'amarillo' && incTriage != 'rojo') {
      _ingresoController.updateIncidente(codigoTriage: 'Amarillo', idConfCodigo: 30);
    } else if (color.toLowerCase() == 'verde' && incTriage != 'rojo' && incTriage != 'amarillo') {
      _ingresoController.updateIncidente(codigoTriage: 'Verde', idConfCodigo: 31);
    }

    if (mostrarNotificacion && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color.toLowerCase() == 'rojo'
                    ? Icons.emergency
                    : (color.toLowerCase() == 'amarillo' ? Icons.warning_amber_rounded : Icons.check_circle_rounded),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text('Triage asignado a Víctima #${widget.index + 1}: $color'),
            ],
          ),
          backgroundColor: color.toLowerCase() == 'rojo'
              ? Colors.red.shade700
              : (color.toLowerCase() == 'amarillo' ? Colors.amber.shade900 : Colors.green.shade700),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRespuestaChanged(SintomaPregunta pregunta, dynamic valor) async {
    if (_isCurrentVictimaLocked) return;
    _ingresoController.lockVictima(widget.index);
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

  Widget _buildModoSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModoTab(
              index: 0,
              icon: Icons.bolt_rounded,
              title: 'ASIGNACIÓN DIRECTA',
              subtitle: 'Asignar síntoma en 1 clic',
              isActive: _modoSeleccion == 0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildModoTab(
              index: 1,
              icon: Icons.psychology_alt_rounded,
              title: 'ASISTENTE DE SCREENING',
              subtitle: 'Derivar ficha a partir de preguntas',
              isActive: _modoSeleccion == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModoTab({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final activeColor = index == 0 ? theme.colorScheme.primary : Colors.tealAccent;

    return Material(
      color: isActive ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _isCurrentVictimaLocked
            ? null
            : () {
                setState(() {
                  _modoSeleccion = index;
                });
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : Colors.white54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCollaborative = _ingresoController.incidenteActual.idIncidente != null;
    final lockKey = 'victima_${widget.index}';

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: SocketService().lockedFields,
      builder: (context, locks, _) {
        final bool isLocked = isCollaborative && locks.containsKey(lockKey);
        String lockedByName = '';
        if (isLocked) {
          lockedByName = locks[lockKey]['nombre'] ?? 'Otro usuario';
        }

        return Focus(
          onFocusChange: (hasFocus) {
            if (!isCollaborative || isLocked) return;
            if (hasFocus) {
              _ingresoController.lockVictima(widget.index);
            } else {
              _ingresoController.scheduleUnlockVictima(widget.index);
            }
          },
          child: Listener(
            onPointerDown: (_) {
              if (!isCollaborative || isLocked) return;
              _ingresoController.lockVictima(widget.index);
            },
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: isLocked,
                  child: Opacity(
                    opacity: isLocked ? 0.35 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isLocked) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sección de síntomas bloqueada. $lockedByName está editando a esta persona.',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // 1. Selector Superior de Modalidad (Directa vs Asistente)
                        _buildModoSelector(),

                        // 2. Contenido según la modalidad activa con altura acotada y scroll interno
                        Expanded(
                          child: _modoSeleccion == 1
                              ? AsistenteSintomasPanel(
                                  catalogoSintomas: _sintomas,
                                  sintomaActual: _sintomaSeleccionado,
                                  onAsignarFicha: _handleAsignarFichaDesdeAsistente,
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 600;

                                    if (isWide) {
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Columna Izquierda: Buscador + Fichas de Despacho (50%)
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
                                              onTriageSelected: (c) => _handleTriageSelected(c),
                                              triageActual: widget.victima.codigoTriage,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Diseño apilado para pantallas reducidas
                                      return SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            SizedBox(
                                              height: 380,
                                              child: SintomaSearchPanel(
                                                sintomas: _sintomas,
                                                sintomaSeleccionado: _sintomaSeleccionado,
                                                isLoading: _isLoadingSymptoms,
                                                onSintomaSelected: _onSintomaSelected,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            SintomaFormPanel(
                                              sintomaSeleccionado: _sintomaSeleccionado,
                                              formulario: _formulario,
                                              isLoadingForm: _isLoadingForm,
                                              errorMessage: _errorMessage,
                                              respuestas: _respuestas,
                                              onRespuestaChanged: _handleRespuestaChanged,
                                              onTriageSelected: (c) => _handleTriageSelected(c),
                                              triageActual: widget.victima.codigoTriage,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SECCIÓN DE SÍNTOMAS BLOQUEADA',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$lockedByName está editando a esta persona en tiempo real.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

