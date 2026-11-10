import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../controllers/ingreso_controller.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/services/configuracion_service.dart';
import '../../../shared/services/socket_service.dart';
import '../../../config/auth_controller.dart';

class DatosVictimasSection extends StatefulWidget {
  final VoidCallback? onDespacho;
  const DatosVictimasSection({super.key, this.onDespacho});

  @override
  State<DatosVictimasSection> createState() => _DatosVictimasSectionState();
}

class _DatosVictimasSectionState extends State<DatosVictimasSection> with TickerProviderStateMixin {
  final _ingresoController = IngresoController();
  late TabController _victimasTabController;
  int _lastVictimasCount = 0;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  int? _listeningVictimaIndex;
  String _textBeforeListening = '';

  Map<String, TextEditingController>? _dniControllers;
  Map<String, TextEditingController>? _nombreControllers;
  Map<String, TextEditingController>? _edadControllers;
  Map<String, TextEditingController>? _observacionesControllers;

  TextEditingController _getDniController(VictimaData victima) {
    _dniControllers ??= {};
    return _dniControllers!.putIfAbsent(
      victima.id,
      () => TextEditingController(text: victima.dni),
    );
  }

  TextEditingController _getNombreController(VictimaData victima) {
    _nombreControllers ??= {};
    return _nombreControllers!.putIfAbsent(
      victima.id,
      () => TextEditingController(text: victima.nombre),
    );
  }

  TextEditingController _getEdadController(VictimaData victima) {
    _edadControllers ??= {};
    return _edadControllers!.putIfAbsent(
      victima.id,
      () => TextEditingController(text: victima.edad),
    );
  }

  TextEditingController _getObservacionesController(VictimaData victima) {
    _observacionesControllers ??= {};
    return _observacionesControllers!.putIfAbsent(
      victima.id,
      () => TextEditingController(text: victima.observaciones),
    );
  }

  @override
  void initState() {
    super.initState();
    _lastVictimasCount = _ingresoController.victimas.length;
    _victimasTabController = TabController(
      length: _lastVictimasCount,
      vsync: this,
      initialIndex: _ingresoController.selectedVictimaIndex.clamp(0, _lastVictimasCount - 1),
    );

    _victimasTabController.addListener(() {
      if (!_victimasTabController.indexIsChanging) {
        _ingresoController.selectedVictimaIndex = _victimasTabController.index;
        if (_isListening) {
          _speech.stop();
          setState(() {
            _isListening = false;
            _listeningVictimaIndex = null;
          });
        }
      }
    });

    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      for (var victima in _ingresoController.victimas) {
        if (_dniControllers != null) {
          final controller = _dniControllers![victima.id];
          if (controller != null && controller.text != victima.dni) {
            controller.text = victima.dni;
          }
        }
        if (_nombreControllers != null) {
          final controller = _nombreControllers![victima.id];
          if (controller != null && controller.text != victima.nombre) {
            controller.text = victima.nombre;
          }
        }
        if (_edadControllers != null) {
          final controller = _edadControllers![victima.id];
          if (controller != null && controller.text != victima.edad) {
            controller.text = victima.edad;
          }
        }
        if (_observacionesControllers != null) {
          final controller = _observacionesControllers![victima.id];
          if (controller != null && controller.text != victima.observaciones) {
            controller.text = victima.observaciones;
          }
        }
      }

      final activeIds = _ingresoController.victimas.map((v) => v.id).toSet();
      _dniControllers?.removeWhere((id, _) => !activeIds.contains(id));
      _nombreControllers?.removeWhere((id, _) => !activeIds.contains(id));
      _edadControllers?.removeWhere((id, _) => !activeIds.contains(id));
      _observacionesControllers?.removeWhere((id, _) => !activeIds.contains(id));

      if (_ingresoController.victimas.length != _lastVictimasCount) {
        _lastVictimasCount = _ingresoController.victimas.length;
        _victimasTabController.dispose();
        _victimasTabController = TabController(
          length: _lastVictimasCount,
          vsync: this,
          initialIndex: _ingresoController.selectedVictimaIndex.clamp(0, _lastVictimasCount - 1),
        );
        _victimasTabController.addListener(() {
          if (!_victimasTabController.indexIsChanging) {
            _ingresoController.selectedVictimaIndex = _victimasTabController.index;
            if (_isListening) {
              _speech.stop();
              setState(() {
                _isListening = false;
                _listeningVictimaIndex = null;
              });
            }
          }
        });
      }

      if (_victimasTabController.index != _ingresoController.selectedVictimaIndex) {
        _victimasTabController.animateTo(_ingresoController.selectedVictimaIndex);
      }

      setState(() {});
    }
  }

  Future<void> _toggleListening(int index, VictimaData victima) async {
    if (!_isListening) {
      if (!_speechAvailable) {
        try {
          bool initialized = await _speech.initialize(
            onStatus: (status) {
              debugPrint('Speech status: $status');
              if (status == 'done' || status == 'notListening') {
                setState(() {
                  _isListening = false;
                  _listeningVictimaIndex = null;
                });
              }
            },
            onError: (errorNotification) {
              debugPrint('Speech error: $errorNotification');
              setState(() {
                _isListening = false;
                _listeningVictimaIndex = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error de dictado: ${errorNotification.errorMsg}'),
                  backgroundColor: Colors.red.shade800,
                ),
              );
            },
          );
          if (initialized) {
            _speechAvailable = true;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El reconocimiento de voz no está disponible en este dispositivo')),
            );
            return;
          }
        } catch (e) {
          debugPrint('Speech initialization exception: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo iniciar el servicio de voz. Revisa los permisos de micrófono.')),
          );
          return;
        }
      }

      final controller = _getObservacionesController(victima);
      _textBeforeListening = controller.text;

      setState(() {
        _isListening = true;
        _listeningVictimaIndex = index;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            final recognized = result.recognizedWords;
            if (recognized.isNotEmpty) {
              final currentController = _getObservacionesController(victima);
              if (_textBeforeListening.isEmpty) {
                currentController.text = recognized;
              } else {
                final lastChar = _textBeforeListening[_textBeforeListening.length - 1];
                final separator = (lastChar == ' ' || lastChar == '\n') ? '' : ' ';
                currentController.text = '$_textBeforeListening$separator$recognized';
              }
              currentController.selection = TextSelection.fromPosition(
                TextPosition(offset: currentController.text.length),
              );
              _ingresoController.updateVictima(index, observaciones: currentController.text);
            }
          });
        },
        localeId: 'es_AR',
        cancelOnError: true,
      );
    } else {
      setState(() {
        _isListening = false;
        _listeningVictimaIndex = null;
      });
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _victimasTabController.dispose();
    if (_dniControllers != null) {
      for (var controller in _dniControllers!.values) {
        controller.dispose();
      }
    }
    if (_nombreControllers != null) {
      for (var controller in _nombreControllers!.values) {
        controller.dispose();
      }
    }
    if (_edadControllers != null) {
      for (var controller in _edadControllers!.values) {
        controller.dispose();
      }
    }
    if (_observacionesControllers != null) {
      for (var controller in _observacionesControllers!.values) {
        controller.dispose();
      }
    }
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final victimas = _ingresoController.victimas;
    final bool isFinalizado = _ingresoController.pasoIncidente >= 4;

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: SocketService().lockedFields,
      builder: (context, locks, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: IntrinsicWidth(
                      child: TabBar(
                        controller: _victimasTabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: theme.colorScheme.primary,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.white60,
                        dividerColor: Colors.transparent,
                        tabs: victimas.asMap().entries.map((e) {
                          final idx = e.key;
                          final victima = e.value;
                          final nombre = victima.nombre.trim();
                          String tabLabel = 'Víctima ${idx + 1}';

                          if (nombre.isNotEmpty) {
                            tabLabel = nombre.split(' ').first;
                            if (tabLabel.length > 10) tabLabel = '${tabLabel.substring(0, 8)}..';
                          }

                          final bool isTabLocked = SocketService().isFieldLockedByOther('victima_$idx');
                          final bool isVicFin = _ingresoController.isVictimaAtencionFinalizada(idx);

                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (victima.isCerrada) ...[
                                  const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                ] else if (isVicFin) ...[
                                  const Icon(Icons.pending_actions_rounded, size: 13, color: Colors.amberAccent),
                                  const SizedBox(width: 4),
                                ],
                                Text(tabLabel),
                                if (isTabLocked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock, size: 10, color: Colors.redAccent),
                                ],
                                if (!isFinalizado && !isVicFin && !victima.isCerrada && victimas.length > 1 && !isTabLocked) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _ingresoController.removeVictima(idx),
                                    child: const Icon(Icons.close, size: 14),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (!isFinalizado)
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => _ingresoController.addVictima(),
                      tooltip: 'Agregar víctima',
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _victimasTabController,
                children: victimas.asMap().entries.map((e) => _buildVictimaForm(theme, e.key, e.value, locks)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVictimaForm(ThemeData theme, int index, VictimaData victima, Map<String, dynamic> locks) {
    final bool isCollaborative = _ingresoController.incidenteActual.idIncidente != null;
    final bool isLocked = isCollaborative && SocketService().isFieldLockedByOther('victima_$index');
    final bool isIncidenteFinalizado = _ingresoController.pasoIncidente >= 4;
    final bool isIncidenteCerrado = _ingresoController.pasoIncidente >= 5 || _ingresoController.incidenteActual.activo == 0;
    final bool isVictimaFinalizada = _ingresoController.isVictimaAtencionFinalizada(index);
    final bool isReadOnly = isIncidenteFinalizado || isVictimaFinalizada || victima.isCerrada;

    String lockedByName = "";
    if (isLocked) {
      final lockInfo = locks['victima_$index'];
      lockedByName = lockInfo is Map ? (lockInfo['nombre'] ?? 'Otro usuario') : lockInfo.toString();
    }

    return Focus(
      onFocusChange: (hasFocus) {
        if (!isCollaborative || isLocked || isReadOnly) return;
        if (hasFocus) {
          _ingresoController.lockVictima(index);
        } else {
          _ingresoController.scheduleUnlockVictima(index);
        }
      },
      child: Listener(
        onPointerDown: (_) {
          if (!isCollaborative || isLocked || isReadOnly) return;
          _ingresoController.lockVictima(index);
        },
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: isLocked,
              child: Opacity(
                opacity: isLocked ? 0.6 : 1.0,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isLocked) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Víctima bloqueada. $lockedByName está editando a esta persona.',
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
                        // Sección de Cierre Individual de Víctima (interactiva aun cuando los campos están bloqueados)
                        if (isVictimaFinalizada || victima.isCerrada) ...[
                          _buildCierreVictimaCard(context, index, victima, isIncidenteCerrado),
                          const SizedBox(height: 14),
                        ],
                        IgnorePointer(
                          ignoring: isReadOnly,
                          child: Opacity(
                            opacity: isReadOnly ? 0.65 : 1.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: _getDniController(victima),
                                        decoration: const InputDecoration(labelText: 'DNI'),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onChanged: (val) => _ingresoController.updateVictima(index, dni: val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: _getNombreController(victima),
                                        decoration: const InputDecoration(labelText: 'Nombre y apellido'),
                                        onChanged: (val) => _ingresoController.updateVictima(index, nombre: val),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: _getEdadController(victima),
                                        decoration: const InputDecoration(labelText: 'Edad'),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onChanged: (val) => _ingresoController.updateVictima(index, edad: val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: CustomSelect<Configuracion>(
                                        key: ValueKey('victima_${victima.id}_genero'),
                                        enabled: !isLocked && !isReadOnly,
                                        label: 'Género',
                                        fetchItems: () => ConfiguracionService.obtenerGeneros(),
                                        itemLabel: (item) => item.descripcion,
                                        initialSelectionId: victima.idConfGenero,
                                        matchById: (item) => item.idconfiguracion,
                                        onSelected: (val) {
                                          if (val != null) {
                                            _ingresoController.updateVictima(index, idConfGenero: val.idconfiguracion);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _getObservacionesController(victima),
                                  decoration: InputDecoration(
                                    labelText: 'Observaciones',
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        widthFactor: 1.0,
                                        heightFactor: 1.0,
                                        child: Tooltip(
                                          message: (_isListening && _listeningVictimaIndex == index)
                                              ? 'Detener dictado por voz'
                                              : 'Dictar por voz',
                                          child: Material(
                                            color: (_isListening && _listeningVictimaIndex == index)
                                                ? Colors.red.withOpacity(0.2)
                                                : Colors.transparent,
                                            type: MaterialType.circle,
                                            clipBehavior: Clip.antiAlias,
                                            child: IconButton(
                                              icon: Icon(
                                                (_isListening && _listeningVictimaIndex == index)
                                                    ? Icons.mic
                                                    : Icons.mic_none,
                                                color: (_isListening && _listeningVictimaIndex == index)
                                                    ? Colors.redAccent
                                                    : Colors.white70,
                                              ),
                                              onPressed: () => _toggleListening(index, victima),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  maxLines: 2,
                                  onChanged: (val) => _ingresoController.updateVictima(index, observaciones: val),
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 12),
                                _buildTriageBanner(theme, index, victima),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCierreVictimaCard(BuildContext context, int index, VictimaData victima, bool isIncidenteCerrado) {
    final bool cerrada = victima.isCerrada;

    if (cerrada) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                SizedBox(width: 6),
                Text(
                  'CIERRE DE VÍCTIMA REGISTRADO',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              victima.reporte ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
            if (victima.usuarioCierre != null || victima.fechaHoraCierre != null) ...[
              const SizedBox(height: 4),
              Text(
                'Cerrado por ${victima.usuarioCierre ?? "operador"}'
                '${victima.fechaHoraCierre != null ? " • ${victima.fechaHoraCierre!.day.toString().padLeft(2, '0')}/${victima.fechaHoraCierre!.month.toString().padLeft(2, '0')} ${victima.fechaHoraCierre!.hour.toString().padLeft(2, '0')}:${victima.fechaHoraCierre!.minute.toString().padLeft(2, '0')}" : ""}',
                style: const TextStyle(color: Colors.white54, fontSize: 10.5),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_outlined, color: Colors.amberAccent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATENCIÓN OPERATIVA FINALIZADA',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Completá el cierre individual de esta víctima para habilitar el cierre del incidente.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _mostrarModalCerrarVictima(context, index, victima),
            icon: const Icon(Icons.task_alt_rounded, size: 15),
            label: const Text(
              'CERRAR VÍCTIMA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalCerrarVictima(BuildContext context, int index, VictimaData victima) {
    final reporteCtrl = TextEditingController(text: victima.reporte ?? '');
    final nombreDisplay = victima.nombre.trim().isNotEmpty
        ? victima.nombre.trim()
        : 'Víctima ${index + 1}';

    // Buscar datos del despacho de esta víctima en el resumen
    String? movilInfo;
    String? hospitalInfo;
    for (final r in _ingresoController.resumenDespachosVictimas) {
      if ((victima.idVictima != null && r.idVictima == victima.idVictima) || r.index == index + 1) {
        movilInfo = r.movilNombre;
        hospitalInfo = r.hospitalNombre;
        break;
      }
    }

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return PointerInterceptor(
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E2429),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white12, width: 1),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cierre de Víctima: $nombreDisplay',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DNI: ${victima.dni.isNotEmpty ? victima.dni : "No informado"} • Edad: ${victima.edad.isNotEmpty ? "${victima.edad} años" : "No informada"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                            if (movilInfo != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Unidad interviniente: $movilInfo',
                                style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (hospitalInfo != null && hospitalInfo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Hospital de destino: $hospitalInfo',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ingresá el informe / observación final de cierre para esta víctima:',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: reporteCtrl,
                        maxLines: 4,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Reporte de cierre de la víctima',
                          alignLabelWithHint: true,
                          hintText: 'Ej: Paciente trasladado y entregado en guardia del Hospital Heller estable...',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white12, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            reporteCtrl.dispose();
                            Navigator.pop(dialogCtx);
                          },
                    child: const Text('CANCELAR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final texto = reporteCtrl.text.trim();
                            if (texto.isEmpty) {
                              _mostrarToastCierreVictima(
                                context,
                                titulo: 'Reporte requerido',
                                mensaje: 'Por favor ingresá un reporte de cierre para la víctima.',
                                accentColor: const Color(0xFFF59E0B),
                                iconData: Icons.warning_amber_rounded,
                              );
                              return;
                            }
                            setStateModal(() => isSaving = true);
                            final ok = await _ingresoController.cerrarVictimaIndividual(
                              index,
                              texto,
                              usuario: RaphAuthController.instance.currentUsername,
                            );
                            if (dialogCtx.mounted) {
                              reporteCtrl.dispose();
                              Navigator.pop(dialogCtx);
                              _mostrarToastCierreVictima(
                                context,
                                titulo: ok ? 'Cierre de víctima registrado' : 'Error al guardar cierre',
                                mensaje: ok
                                    ? 'El informe de cierre de $nombreDisplay se guardó correctamente.'
                                    : 'No se pudo guardar el cierre de la víctima.',
                                accentColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                iconData: ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                              );
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      isSaving ? 'GUARDANDO...' : 'GUARDAR CIERRE DE VÍCTIMA',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarToastCierreVictima(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required Color accentColor,
    required IconData iconData,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        width: 460,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161D24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.55), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withOpacity(0.16),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withOpacity(0.4)),
                ),
                child: Icon(iconData, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriageBanner(ThemeData theme, int index, VictimaData victima) {
    final triageVictima = victima.codigoTriage?.trim();
    final triageIncidente = _ingresoController.incidenteActual.codigoTriage?.trim();
    final idConfCodigoIncidente = _ingresoController.incidenteActual.idConfCodigo;
    final tieneProtocolos = _ingresoController.protocolosSeleccionados.isNotEmpty;

    String? effectiveTriage = (triageVictima != null && triageVictima.isNotEmpty) ? triageVictima : null;
    if (effectiveTriage == null) {
      if (tieneProtocolos || idConfCodigoIncidente == 29 || idConfCodigoIncidente == 135 || triageIncidente?.toLowerCase() == 'rojo') {
        effectiveTriage = 'Rojo';
      } else if (idConfCodigoIncidente == 30 || triageIncidente?.toLowerCase() == 'amarillo') {
        effectiveTriage = 'Amarillo';
      } else if (idConfCodigoIncidente == 31 || triageIncidente?.toLowerCase() == 'verde') {
        effectiveTriage = 'Verde';
      } else if (idConfCodigoIncidente == 63 || (triageIncidente != null && triageIncidente.toLowerCase().contains('sin'))) {
        effectiveTriage = 'Sin código';
      }
    }

    Color codeColor;
    String codeText;

    switch (effectiveTriage?.toLowerCase()) {
      case 'rojo':
        codeColor = Colors.red.shade600;
        codeText = 'ROJO - EMERGENCIA CRÍTICA';
        break;
      case 'amarillo':
        codeColor = Colors.yellow.shade700;
        codeText = 'AMARILLO - URGENCIA';
        break;
      case 'verde':
        codeColor = Colors.green.shade600;
        codeText = 'VERDE - NO URGENTE';
        break;
      default:
        codeColor = Colors.white24;
        codeText = 'SIN CÓDIGO';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: codeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: codeColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: codeColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'CÓDIGO ACTUAL: $codeText',
              style: theme.textTheme.titleMedium?.copyWith(
                color: codeColor == Colors.white24 ? Colors.white : codeColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
