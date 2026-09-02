import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../controllers/ingreso_controller.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/services/configuracion_service.dart';
import '../../../shared/services/socket_service.dart';
import 'victima_sintomas_section.dart';

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
  Timer? _unlockVictimaDebounce;

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
      // Sincronizar controladores con los datos del modelo
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

      // Limpiar controladores huérfanos
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
              // Mover cursor al final
              currentController.selection = TextSelection.fromPosition(
                TextPosition(offset: currentController.text.length),
              );
              // Sincronizar con el controller
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
    _unlockVictimaDebounce?.cancel();
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
                          final victima = e.value;
                          final nombre = victima.nombre.trim();
                          String tabLabel = 'Víctima ${e.key + 1}';

                          if (nombre.isNotEmpty) {
                            tabLabel = nombre.split(' ').first;
                            if (tabLabel.length > 10) tabLabel = '${tabLabel.substring(0, 8)}..';
                          }

                          final bool isTabLocked = locks.containsKey('victima_${e.key}');

                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tabLabel),
                                if (isTabLocked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock, size: 10, color: Colors.redAccent),
                                ],
                                if (victimas.length > 1 && !isTabLocked) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _ingresoController.removeVictima(e.key),
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
    final bool isLocked = isCollaborative && locks.containsKey('victima_$index');
    String lockedByName = "";

    if (isLocked) {
      lockedByName = locks['victima_$index']['nombre'] ?? 'Otro usuario';
    }

    return Focus(
      onFocusChange: (hasFocus) {
        if (!isCollaborative) return;
        if (isLocked) return;
        if (hasFocus) {
          _unlockVictimaDebounce?.cancel();
          SocketService().lockField('victima_$index');
        } else {
          _unlockVictimaDebounce?.cancel();
          _unlockVictimaDebounce = Timer(const Duration(milliseconds: 150), () {
            if (mounted) {
              SocketService().unlockField('victima_$index');
            }
          });
        }
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
                            enabled: !isLocked,
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
                    
                    // Triage section
                    _buildTriageBanner(theme, index, victima),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
 
                    // Symptoms & Suggested assistance section
                    VictimaSintomasSection(
                      key: ValueKey('sintomas_${victima.id}'),
                      index: index,
                      victima: victima,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
 
                    // Attachments section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
                          );
 
                          if (result != null) {
                            setState(() {
                              victima.archivosAdjuntos.addAll(result.files);
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 20),
                        label: const Text(
                          'Adjuntar documentación',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    if (victima.archivosAdjuntos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: victima.archivosAdjuntos.map((file) {
                            return Chip(
                              label: Text(
                                file.name,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  victima.archivosAdjuntos.remove(file);
                                });
                              },
                              backgroundColor: theme.colorScheme.surface,
                              side: const BorderSide(color: Colors.white24),
                            );
                          }).toList().cast<Widget>(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildTriageBanner(ThemeData theme, int index, VictimaData victima) {
    Color codeColor;
    String codeText;

    switch (victima.codigoTriage) {
      case 'Rojo':
        codeColor = Colors.red.shade600;
        codeText = 'ROJO - EMERGENCIA CRÍTICA';
        break;
      case 'Amarillo':
        codeColor = Colors.yellow.shade700;
        codeText = 'AMARILLO - URGENCIA';
        break;
      case 'Verde':
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
