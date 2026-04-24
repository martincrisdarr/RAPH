import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ProtocoloRcpView extends StatefulWidget {
  const ProtocoloRcpView({super.key});

  @override
  State<ProtocoloRcpView> createState() => _ProtocoloRcpViewState();
}

class _ProtocoloRcpViewState extends State<ProtocoloRcpView> {
  String _selectedAge = 'adulto';
  
  Timer? _secondsTimer;
  Timer? _compressionTimer;
  int _elapsedSeconds = 0;
  int _totalCompressions = 0;
  bool _isRunning = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late Uint8List _beepBytes;

  @override
  void initState() {
    super.initState();
    _beepBytes = _generateBeep();
  }

  Uint8List _generateBeep() {
    final sampleRate = 44100;
    final duration = 0.05; // 50 milisegundos
    final numSamples = (sampleRate * duration).toInt();
    final frequency = 1000.0;
    
    final bytes = <int>[];
    
    // RIFF header
    bytes.addAll("RIFF".codeUnits);
    final chunkSize = 36 + numSamples * 2;
    bytes.add(chunkSize & 0xff);
    bytes.add((chunkSize >> 8) & 0xff);
    bytes.add((chunkSize >> 16) & 0xff);
    bytes.add((chunkSize >> 24) & 0xff);
    
    bytes.addAll("WAVE".codeUnits);
    bytes.addAll("fmt ".codeUnits);
    
    // Subchunk1Size
    bytes.addAll([16, 0, 0, 0]);
    // AudioFormat (PCM)
    bytes.addAll([1, 0]);
    // NumChannels (Mono)
    bytes.addAll([1, 0]);
    // SampleRate
    bytes.addAll([68, 172, 0, 0]);
    // ByteRate
    bytes.addAll([136, 88, 1, 0]);
    // BlockAlign
    bytes.addAll([2, 0]);
    // BitsPerSample
    bytes.addAll([16, 0]);
    
    // data subchunk
    bytes.addAll("data".codeUnits);
    final subchunk2Size = numSamples * 2;
    bytes.add(subchunk2Size & 0xff);
    bytes.add((subchunk2Size >> 8) & 0xff);
    bytes.add((subchunk2Size >> 16) & 0xff);
    bytes.add((subchunk2Size >> 24) & 0xff);
    
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sample = ((sin(2 * pi * frequency * t) * 32767) * 0.5).toInt();
      bytes.add(sample & 0xff);
      bytes.add((sample >> 8) & 0xff);
    }
    
    return Uint8List.fromList(bytes);
  }

  void _playPip() async {
    await _audioPlayer.play(BytesSource(_beepBytes), volume: 0.5);
  }

  final Map<String, Map<String, dynamic>> _ageData = {
    'adulto': {
      'icon': '👱‍♂️',
      'title': 'ADULTO',
      'subtitle': '+8 años',
      'steps': [
        '📍 Posición: Talón de la mano en el centro del pecho (sobre el esternón), mano encima entrelazada.',
        '💪 Profundidad: 5–6 cm. Brazos rectos, peso del cuerpo hacia abajo.',
        '🔁 Ritmo: 100 compresiones/min. Compresiones continuas sin pausas para ventilación.',
        '🔄 Rotar al compresero cada 2 minutos — el sistema lo avisará automáticamente.',
        '⚡ No interrumpir más de 10 segundos. Continuar hasta llegada del móvil.'
      ],
    },
    'nino': {
      'icon': '👦',
      'title': 'NIÑO',
      'subtitle': '1-8 años',
      'steps': [
        '📍 Posición: 1 o 2 dedos sobre el esternón, debajo de la línea intermamaria. O talón de 1 mano.',
        '💪 Profundidad: 1/3 del diámetro antero-posterior del tórax (~4–5 cm).',
        '🔁 Ritmo: 100–120 compresiones/min. Compresiones continuas.',
        '🔄 Rotar al compresero cada 2 minutos — el sistema lo avisará.'
      ],
    },
    'bebe': {
      'icon': '👶',
      'title': 'BEBÉ',
      'subtitle': '<1 año',
      'steps': [
        '📍 Posición: 2 dedos (índice y medio) en el centro del pecho, debajo de la línea intermamaria.',
        '💪 Profundidad: 4 cm aprox. (1/3 del tórax). MUY SUAVE.',
        '🔁 Ritmo: 100–120 compresiones/min. Compresiones continuas.',
        '🔄 Rotar al compresero cada 2 minutos — el sistema lo avisará.'
      ],
    }
  };

  void _toggleTimer() {
    if (_isRunning) {
      _secondsTimer?.cancel();
      _compressionTimer?.cancel();
    } else {
      _secondsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });

        if (_elapsedSeconds > 0 && _elapsedSeconds % 120 == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Rotar al rescatador (2 minutos cumplidos)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 8),
            ),
          );
        }
      });

      // 100 compresiones por minuto -> 1 cada 600 ms
      _compressionTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
        setState(() {
          _totalCompressions++;
        });
        _playPip();
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    _secondsTimer?.cancel();
    _compressionTimer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
      _totalCompressions = 0;
    });
  }

  @override
  void dispose() {
    _secondsTimer?.cancel();
    _compressionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentData = _ageData[_selectedAge]!;
    
    // Cálculos para las métricas de RCP
    int cycles = (_totalCompressions / 30).floor();
    int currentCompressionInCycle = _totalCompressions % 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header titles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Text(
                'P R O T O C O L O',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    'RCP — COMPRESIONES',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === COLUMNA IZQUIERDA ===
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDAD DEL PACIENTE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildAgeButton(theme, 'adulto')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildAgeButton(theme, 'nino')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildAgeButton(theme, 'bebe')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tarjeta de pasos
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                          ),
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: (currentData['steps'] as List).length,
                              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 24),
                              itemBuilder: (context, index) {
                                final text = (currentData['steps'] as List)[index];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('▸', style: TextStyle(color: Colors.redAccent, fontSize: 18, height: 1.2)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // === COLUMNA DERECHA ===
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Text(
                        '100 COMPRESIONES POR MINUTO — CONTINUO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Círculo grande de compresiones
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 6,
                            )
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('❤️', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              '$_totalCompressions',
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'COMPRESIONES',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tarjeta de Tiempo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TIEMPO TRANSCURRIDO',
                              style: TextStyle(
                                color: Colors.white54,
                                letterSpacing: 2,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(_elapsedSeconds),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                children: [
                                  const TextSpan(text: 'CICLOS DE 30: '),
                                  TextSpan(text: '$cycles', style: const TextStyle(color: Colors.blueAccent)),
                                  const TextSpan(text: '  |  COMPRESIÓN: '),
                                  TextSpan(text: '$currentCompressionInCycle', style: const TextStyle(color: Colors.redAccent)),
                                ]
                              )
                            )
                          ],
                        )
                      ),
                      const SizedBox(height: 24),
                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _toggleTimer,
                            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                            label: Text(_isRunning ? 'PAUSAR' : 'INICIAR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRunning ? Colors.orange.shade700 : Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh),
                            label: const Text('RESET'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeButton(ThemeData theme, String id) {
    final isSelected = _selectedAge == id;
    final data = _ageData[id]!;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAge = id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (isSelected)
              const Positioned(
                top: -8,
                right: -4,
                child: Icon(Icons.check_circle, color: Colors.redAccent, size: 16),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data['icon'], style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(
                    data['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.redAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data['subtitle'],
                        style: TextStyle(
                          color: isSelected ? Colors.redAccent.shade100 : Colors.white54,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                      ),
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
}
