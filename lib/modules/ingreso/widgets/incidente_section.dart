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
  final List<String> _protocolosSeleccionados = [];

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
                final isSelected = _protocolosSeleccionados.contains(protocolo);
                
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
                    setState(() {
                      if (isSelected) {
                        _protocolosSeleccionados.remove(protocolo);
                      } else {
                        _protocolosSeleccionados.add(protocolo);
                      }
                    });
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
          if (widget.onDespacho != null) ...[
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
    Color codeColor;
    String codeText;

    final codigoTriage = _ingresoController.incidenteActual.codigoTriage;

    switch (codigoTriage) {
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
                color: codeColor == Colors.white24 ? Colors.white : codeColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          _buildTriageSelector(codigoTriage),
        ],
      ),
    );
  }

  Widget _buildTriageSelector(String? currentCode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTriageOptionButton(currentCode, 'Verde', Colors.green),
        const SizedBox(width: 8),
        _buildTriageOptionButton(currentCode, 'Amarillo', Colors.yellow),
        const SizedBox(width: 8),
        _buildTriageOptionButton(currentCode, 'Rojo', Colors.red),
      ],
    );
  }

  Widget _buildTriageOptionButton(String? currentCode, String code, Color color) {
    final isSelected = currentCode == code;
    return GestureDetector(
      onTap: () {
        _ingresoController.updateIncidente(codigoTriage: code);
        setState(() {});
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
      ),
    );
  }
}
