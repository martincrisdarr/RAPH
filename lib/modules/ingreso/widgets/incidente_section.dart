import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../controllers/ingreso_controller.dart';
import '../../../shared/components/collab_text_field.dart';
import '../../../shared/services/socket_service.dart';
import '../../../shared/services/configuracion_service.dart';

class IncidenteSection extends StatefulWidget {
  final VoidCallback? onDespacho;
  const IncidenteSection({super.key, this.onDespacho});

  @override
  State<IncidenteSection> createState() => _IncidenteSectionState();
}

class _IncidenteSectionState extends State<IncidenteSection> {
  final _ingresoController = IngresoController();
  late final TextEditingController _descripcionIncidenteController;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _textBeforeListening = '';

  final List<Map<String, dynamic>> _protocolosPredeterminados = [
    {'nombre': 'Accidente Vehicular', 'color': Colors.red.shade400},
    {'nombre': 'Derrumbe', 'color': Colors.red.shade400},
    {'nombre': 'Catástrofe', 'color': Colors.red.shade400},
    {'nombre': 'Gases Tóxicos', 'color': Colors.red.shade400},
    {'nombre': 'Incendio', 'color': Colors.red.shade400},
    {'nombre': 'Accidente Industrial', 'color': Colors.red.shade400},
  ];

  List<Map<String, dynamic>> _protocolosDinamicos = [];

  @override
  void initState() {
    super.initState();
    _descripcionIncidenteController = TextEditingController(text: _ingresoController.incidenteActual.descripcion ?? '');
    _ingresoController.addListener(_onControllerUpdate);
    _cargarProtocolos();
  }

  Future<void> _cargarProtocolos() async {
    try {
      final configTipos = await ConfiguracionService.obtenerTiposIncidente();
      final lista = <Map<String, dynamic>>[];
      for (var p in configTipos) {
        if (p.descripcion.isNotEmpty) {
          lista.add({'nombre': p.descripcion, 'color': Colors.red.shade400});
        }
      }

      if (mounted) {
        setState(() {
          _protocolosDinamicos = lista.isNotEmpty ? lista : _protocolosPredeterminados;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _protocolosDinamicos = _protocolosPredeterminados;
        });
      }
    }
  }

  int? _lastIncidenteId;

  void _onControllerUpdate() {
    if (mounted) {
      final incidente = _ingresoController.incidenteActual;
      
      if (incidente.idIncidente != _lastIncidenteId) {
        _lastIncidenteId = incidente.idIncidente;
        _descripcionIncidenteController.text = incidente.descripcion ?? '';
      } else {
        final nuevaDesc = incidente.descripcion ?? '';
        if (_descripcionIncidenteController.text != nuevaDesc) {
          _descripcionIncidenteController.text = nuevaDesc;
        }
      }

      setState(() {});
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      if (!_speechAvailable) {
        try {
          bool initialized = await _speech.initialize(
            onStatus: (status) {
              if (status == 'done' || status == 'notListening') {
                setState(() => _isListening = false);
              }
            },
            onError: (errorNotification) {
              setState(() => _isListening = false);
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El reconocimiento de voz no está disponible en este dispositivo')),
              );
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo iniciar el servicio de voz. Revisa los permisos de micrófono.')),
            );
          }
          return;
        }
      }

      _textBeforeListening = _descripcionIncidenteController.text;
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          setState(() {
            final recognized = result.recognizedWords;
            if (recognized.isNotEmpty) {
              if (_textBeforeListening.isEmpty) {
                _descripcionIncidenteController.text = recognized;
              } else {
                final lastChar = _textBeforeListening[_textBeforeListening.length - 1];
                final separator = (lastChar == ' ' || lastChar == '\n') ? '' : ' ';
                _descripcionIncidenteController.text = '$_textBeforeListening$separator$recognized';
              }
              _descripcionIncidenteController.selection = TextSelection.fromPosition(
                TextPosition(offset: _descripcionIncidenteController.text.length),
              );
              SocketService().updateField('descripcion', _descripcionIncidenteController.text);
              _ingresoController.updateIncidente(descripcion: _descripcionIncidenteController.text);
            }
          });
        },
        localeId: 'es_AR',
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _descripcionIncidenteController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final protocolosList = _protocolosDinamicos.isNotEmpty ? _protocolosDinamicos : _protocolosPredeterminados;
    final codigoTriage = _ingresoController.incidenteActual.codigoTriage;
    final tieneProtocolos = _ingresoController.protocolosSeleccionados.isNotEmpty;
    final esRojo = codigoTriage == 'Rojo' || tieneProtocolos;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: protocolosList.map((protoData) {
                final protocolo = protoData['nombre'] as String;
                final color = protoData['color'] as Color;
                final isSelected = _ingresoController.protocolosSeleccionados.contains(protocolo);
                
                return ActionChip(
                  label: Text(
                    protocolo, 
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isSelected 
                      ? color.withValues(alpha: 0.4) 
                      : color.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    final current = List<String>.from(_ingresoController.protocolosSeleccionados);
                    if (current.contains(protocolo)) {
                      current.remove(protocolo);
                    } else {
                      current.add(protocolo);
                    }
                    _ingresoController.protocolosSeleccionados = current;

                    if (current.isNotEmpty) {
                      _ingresoController.updateIncidente(codigoTriage: 'Rojo');
                      _ingresoController.updateTodasLasVictimas(codigoTriage: 'Rojo');
                    } else {
                      _ingresoController.updateIncidente(codigoTriage: '');
                      _ingresoController.updateTodasLasVictimas(codigoTriage: '');
                    }
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _buildTriageBanner(theme),
          const SizedBox(height: 16),
          
          Expanded(
            child: CollabTextField(
              fieldId: 'descripcion',
              label: 'Descripción del incidente',
              hintText: 'Ingresá los detalles del incidente...',
              controller: _descripcionIncidenteController,
              isCollaborative: _ingresoController.incidenteActual.idIncidente != null,
              maxLines: 12,
              onChanged: (val) => _ingresoController.updateIncidente(descripcion: val),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: Tooltip(
                    message: _isListening ? 'Detener dictado por voz' : 'Dictar por voz',
                    child: Material(
                      color: _isListening ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                      type: MaterialType.circle,
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : theme.colorScheme.primary,
                        ),
                        onPressed: _toggleListening,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageBanner(ThemeData theme) {
    final triage = _ingresoController.incidenteActual.codigoTriage;
    if (triage == null || triage.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    Color bannerColor = Colors.grey;
    String text = 'TRIAGE DEL INCIDENTE: NO ASIGNADO';

    if (triage == 'Rojo') {
      bannerColor = Colors.red.shade600;
      text = 'ROJO - EMERGENCIA CRÍTICA';
    } else if (triage == 'Amarillo') {
      bannerColor = Colors.yellow.shade700;
      text = 'AMARILLO - URGENCIA';
    } else if (triage == 'Verde') {
      bannerColor = Colors.green.shade600;
      text = 'VERDE - NO URGENTE';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(
                color: bannerColor == Colors.grey ? Colors.white70 : bannerColor, 
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


