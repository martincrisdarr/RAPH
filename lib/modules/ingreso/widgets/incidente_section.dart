import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../controllers/ingreso_controller.dart';
import '../../../shared/components/collab_text_field.dart';
import '../../../shared/services/socket_service.dart';

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
  
  final List<Map<String, dynamic>> _protocolosSugeridos = [
    {'nombre': 'Accidente Vehicular', 'color': Colors.red.shade400},
    {'nombre': 'Derrumbe', 'color': Colors.red.shade400},
    {'nombre': 'Catástrofe', 'color': Colors.red.shade400},
    {'nombre': 'Gases Tóxicos', 'color': Colors.red.shade400},
    {'nombre': 'Incendio', 'color': Colors.red.shade400},
    {'nombre': 'Accidente Industrial', 'color': Colors.red.shade400},
  ];


  @override
  void initState() {
    super.initState();
    _descripcionIncidenteController = TextEditingController(text: _ingresoController.incidenteActual.descripcion ?? '');
    _ingresoController.addListener(_onControllerUpdate);
  }

  int? _lastIncidenteId;

  void _onControllerUpdate() {
    if (mounted) {
      final incidente = _ingresoController.incidenteActual;
      
      // Sincronización de descripción
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
              debugPrint('Speech status: $status');
              if (status == 'done' || status == 'notListening') {
                setState(() => _isListening = false);
              }
            },
            onError: (errorNotification) {
              debugPrint('Speech error: $errorNotification');
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
              // Mover cursor al final
              _descripcionIncidenteController.selection = TextSelection.fromPosition(
                TextPosition(offset: _descripcionIncidenteController.text.length),
              );
              // Sincronizar con el socket en tiempo real
              SocketService().updateField('descripcion', _descripcionIncidenteController.text);
              // Sincronizar con el controller
              _ingresoController.updateIncidente(descripcion: _descripcionIncidenteController.text);
            }
          });
        },
        localeId: 'es_AR',
        cancelOnError: true,
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
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Protocolos rápidos:', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _protocolosSugeridos.map((protoData) {
                final protocolo = protoData['nombre'] as String;
                final color = protoData['color'] as Color;
                final isSelected = _ingresoController.protocolosSeleccionados.contains(protocolo);
                
                return ActionChip(
                  label: Text(
                    protocolo, 
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : color.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isSelected 
                      ? color.withOpacity(0.4) 
                      : color.withOpacity(0.1),
                  side: BorderSide(
                    color: isSelected ? color : color.withOpacity(0.3),
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
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
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
                          color: _isListening ? Colors.redAccent : Colors.white70,
                        ),
                        onPressed: _toggleListening,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onDespacho != null && (_ingresoController.incidenteActual.codigoTriage == 'Rojo' || _ingresoController.protocolosSeleccionados.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: widget.onDespacho,
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('DESPACHO RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary, width: 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTriageBanner(ThemeData theme) {
    final codigoTriage = _ingresoController.incidenteActual.codigoTriage;
    final esRojo = codigoTriage == 'Rojo' || _ingresoController.protocolosSeleccionados.isNotEmpty;

    if (!esRojo) {
      return const SizedBox.shrink();
    }

    final codeColor = Colors.red.shade600;
    const codeText = 'ROJO - EMERGENCIA CRÍTICA';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: codeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: codeColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: codeColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'CÓDIGO INCIDENTE: $codeText',
              style: theme.textTheme.titleMedium?.copyWith(
                color: codeColor,
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
