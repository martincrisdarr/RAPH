import 'package:flutter/material.dart';
import '../../../shared/models/sintoma.dart';
import '../../../shared/services/sintoma_scoring_service.dart';

class AsistenteSintomasPanel extends StatefulWidget {
  final List<Sintoma> catalogoSintomas;
  final Function(Sintoma sintoma, String triage) onAsignarFicha;
  final Sintoma? sintomaActual;

  const AsistenteSintomasPanel({
    super.key,
    required this.catalogoSintomas,
    required this.onAsignarFicha,
    this.sintomaActual,
  });

  @override
  State<AsistenteSintomasPanel> createState() => _AsistenteSintomasPanelState();
}

class _AsistenteSintomasPanelState extends State<AsistenteSintomasPanel> {
  ConcienciaOption? _conciencia;
  RespiracionOption? _respiracion;
  HemorragiaOption? _hemorragia;
  CausaOption? _causa;
  String? _focoPrincipal;

  void _limpiarFiltros() {
    setState(() {
      _conciencia = null;
      _respiracion = null;
      _hemorragia = null;
      _causa = null;
      _focoPrincipal = null;
    });
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
    final sugerencias = SintomaScoringService.evaluarSugerencias(
      catalogo: widget.catalogoSintomas,
      conciencia: _conciencia,
      respiracion: _respiracion,
      hemorragia: _hemorragia,
      causa: _causa,
      focoPrincipal: _focoPrincipal,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Columna izquierda: Preguntas y Screening Guiado (55%)
              Expanded(
                flex: 11,
                child: _buildFormularioScreening(hasBoundedHeight: true),
              ),
              const SizedBox(width: 16),
              // Columna derecha: Sugerencias en Vivo (45%)
              Expanded(
                flex: 9,
                child: _buildPanelResultados(sugerencias, hasBoundedHeight: true),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormularioScreening(hasBoundedHeight: false),
                const SizedBox(height: 16),
                _buildPanelResultados(sugerencias, hasBoundedHeight: false),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildFormularioScreening({bool hasBoundedHeight = true}) {
    final formContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Colors.tealAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SCREENING CLÍNICO TELEFÓNICO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (_conciencia != null ||
                  _respiracion != null ||
                  _hemorragia != null ||
                  _causa != null ||
                  _focoPrincipal != null)
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reiniciar', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. SIGNOS VITALES: CONCIENCIA
          _buildSeccionHeader('1. ESTADO DE CONCIENCIA', Icons.psychology_outlined),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Alerta / Responde',
                selected: _conciencia == ConcienciaOption.alerta,
                onSelected: () {
                  setState(() {
                    _conciencia = _conciencia == ConcienciaOption.alerta ? null : ConcienciaOption.alerta;
                  });
                },
              ),
              _buildChoiceChip(
                label: 'Confuso / Desorientado',
                selected: _conciencia == ConcienciaOption.confuso,
                colorActivo: Colors.amber.shade400,
                onSelected: () {
                  setState(() {
                    _conciencia = _conciencia == ConcienciaOption.confuso ? null : ConcienciaOption.confuso;
                  });
                },
              ),
              _buildChoiceChip(
                label: 'Inconsciente / No responde',
                selected: _conciencia == ConcienciaOption.inconsciente,
                colorActivo: Colors.redAccent.shade400,
                onSelected: () {
                  setState(() {
                    _conciencia = _conciencia == ConcienciaOption.inconsciente ? null : ConcienciaOption.inconsciente;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. SIGNOS VITALES: RESPIRACIÓN
          _buildSeccionHeader('2. RESPIRACIÓN', Icons.air_rounded),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Respira normal',
                selected: _respiracion == RespiracionOption.normal,
                onSelected: () {
                  setState(() {
                    _respiracion = _respiracion == RespiracionOption.normal ? null : RespiracionOption.normal;
                  });
                },
              ),
              _buildChoiceChip(
                label: 'Con dificultad / Agitado / Disnea',
                selected: _respiracion == RespiracionOption.dificultosa,
                colorActivo: Colors.amber.shade400,
                onSelected: () {
                  setState(() {
                    _respiracion = _respiracion == RespiracionOption.dificultosa ? null : RespiracionOption.dificultosa;
                  });
                },
              ),
              _buildChoiceChip(
                label: 'NO RESPIRA / APNEA',
                selected: _respiracion == RespiracionOption.noRespira,
                colorActivo: Colors.redAccent.shade400,
                onSelected: () {
                  setState(() {
                    _respiracion = _respiracion == RespiracionOption.noRespira ? null : RespiracionOption.noRespira;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. HEMORRAGIA
          _buildSeccionHeader('3. HEMORRAGIA / SANGRADO', Icons.water_drop_outlined),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Sin sangrado',
                selected: _hemorragia == HemorragiaOption.ninguna,
                onSelected: () {
                  setState(() {
                    _hemorragia = _hemorragia == HemorragiaOption.ninguna ? null : HemorragiaOption.ninguna;
                  });
                },
              ),
              _buildChoiceChip(
                label: 'Sangrado moderado / Corte',
                selected: _hemorragia == HemorragiaOption.moderada,
                colorActivo: Colors.amber.shade400,
                onSelected: () {
                  setState(() {
                    _hemorragia = _hemorragia == HemorragiaOption.moderada ? null : HemorragiaOption.moderada;
                  });
                },
              ),
              _buildChoiceChip(
                label: 'Hemorragia severa / A chorros',
                selected: _hemorragia == HemorragiaOption.severa,
                colorActivo: Colors.redAccent.shade400,
                onSelected: () {
                  setState(() {
                    _hemorragia = _hemorragia == HemorragiaOption.severa ? null : HemorragiaOption.severa;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. NATURALEZA DEL HECHO
          _buildSeccionHeader('4. NATURALEZA DEL EVENTO', Icons.category_outlined),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: '🩺 Clínico / Enfermedad',
                selected: _causa == CausaOption.clinico,
                onSelected: () {
                  setState(() {
                    _causa = _causa == CausaOption.clinico ? null : CausaOption.clinico;
                    _focoPrincipal = null;
                  });
                },
              ),
              _buildChoiceChip(
                label: '💥 Accidente / Golpe (Trauma)',
                selected: _causa == CausaOption.trauma,
                onSelected: () {
                  setState(() {
                    _causa = _causa == CausaOption.trauma ? null : CausaOption.trauma;
                    _focoPrincipal = null;
                  });
                },
              ),
              _buildChoiceChip(
                label: '☣️ Intoxicación / Veneno',
                selected: _causa == CausaOption.intoxicacion,
                onSelected: () {
                  setState(() {
                    _causa = _causa == CausaOption.intoxicacion ? null : CausaOption.intoxicacion;
                    _focoPrincipal = null;
                  });
                },
              ),
              _buildChoiceChip(
                label: '⚠️ Violencia / Agresión',
                selected: _causa == CausaOption.violencia,
                onSelected: () {
                  setState(() {
                    _causa = _causa == CausaOption.violencia ? null : CausaOption.violencia;
                    _focoPrincipal = null;
                  });
                },
              ),
              _buildChoiceChip(
                label: '🤰 Trabajo de Parto',
                selected: _causa == CausaOption.obstetrico,
                onSelected: () {
                  setState(() {
                    _causa = _causa == CausaOption.obstetrico ? null : CausaOption.obstetrico;
                    _focoPrincipal = 'parto';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. FOCO O MOTIVO PRINCIPAL
          _buildSeccionHeader('5. FOCO O MOTIVO PRINCIPAL', Icons.my_location_rounded),
          const SizedBox(height: 6),
          _buildOpcionesFocoSegunCausa(),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasBoundedHeight
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: formContent,
              )
            : formContent,
      ),
    );
  }

  Widget _buildOpcionesFocoSegunCausa() {
    List<Map<String, String>> opciones = [];

    if (_causa == CausaOption.trauma) {
      opciones = [
        {'id': 'accidente_vehicular', 'label': 'Accidente de Tránsito / Vehicular'},
        {'id': 'caida_altura', 'label': 'Caída de Altura / Escalera'},
        {'id': 'trauma_craneo', 'label': 'Golpe en Cabeza / Cráneo'},
        {'id': 'trauma_miembros', 'label': 'Fractura / Golpe en Extremidades'},
        {'id': 'herida_cortante', 'label': 'Corte / Herida Cortante'},
        {'id': 'quemaduras', 'label': 'Quemaduras'},
        {'id': 'electrocucion', 'label': 'Descarga Eléctrica'},
      ];
    } else if (_causa == CausaOption.intoxicacion) {
      opciones = [
        {'id': 'intoxicacion_ingesta', 'label': 'Ingesta de Fármacos / Veneno'},
        {'id': 'gases_toxicos', 'label': 'Inhalación de Gases / Monóxido'},
      ];
    } else if (_causa == CausaOption.violencia) {
      opciones = [
        {'id': 'arma_fuego', 'label': 'Herida de Arma de Fuego'},
        {'id': 'arma_blanca', 'label': 'Herida de Arma Blanca'},
        {'id': 'suicidio', 'label': 'Intento de Suicidio'},
      ];
    } else if (_causa == CausaOption.obstetrico) {
      opciones = [
        {'id': 'parto', 'label': 'Trabajo de Parto Inminente'},
      ];
    } else {
      // Clínico o General
      opciones = [
        {'id': 'pecho', 'label': 'Dolor de Pecho / Opresión / Tórax'},
        {'id': 'neurologico_acv', 'label': 'Dificultad p/ Hablar o Mover Brazo (ACV)'},
        {'id': 'convulsiones', 'label': 'Convulsiones / Ataque'},
        {'id': 'abdomen', 'label': 'Dolor Abdominal / Cólico / Vómitos'},
        {'id': 'fiebre', 'label': 'Fiebre / Cuadro Infeccioso'},
        {'id': 'cefalea_mareos', 'label': 'Dolor de Cabeza Intenso / Mareos'},
        {'id': 'diabetes', 'label': 'Descompensación Diabetes / Hipoglucemia'},
        {'id': 'sincope_recuperado', 'label': 'Se desmayó pero ya se despertó'},
        {'id': 'lumbalgia_dorso', 'label': 'Dolor de Espalda / Lumbar'},
        {'id': 'urinario', 'label': 'Dificultad o Dolor al Orinar'},
        {'id': 'alergia_piel', 'label': 'Reacción Alérgica / Ronchas'},
      ];
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opciones.map((opt) {
        final isSelected = _focoPrincipal == opt['id'];
        return _buildChoiceChip(
          label: opt['label']!,
          selected: isSelected,
          colorActivo: Colors.tealAccent,
          onSelected: () {
            setState(() {
              _focoPrincipal = isSelected ? null : opt['id'];
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSeccionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Color? colorActivo,
  }) {
    final activeColor = colorActivo ?? Colors.tealAccent;

    return Material(
      color: selected ? activeColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? activeColor : Colors.white12,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 13, color: activeColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelResultados(List<SintomaScoreResult> sugerencias, {bool hasBoundedHeight = true}) {
    final resultsContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'FICHAS OFICIALES SUGERIDAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (sugerencias.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sugerencias.length} Coincidencias',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (sugerencias.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.touch_app_outlined, size: 36, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    'Seleccione las respuestas del llamante en el panel de screening.\nEl sistema calculará las fichas más probables en tiempo real.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sugerencias.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = sugerencias[index];
                final s = item.sintoma;
                final seriesColor = _getColorForSeries(s.codigoColor);
                final isCurrent = widget.sintomaActual?.id == s.id;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: seriesColor.withValues(alpha: isCurrent ? 0.22 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? seriesColor : seriesColor.withValues(alpha: 0.35),
                      width: isCurrent ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: seriesColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.codigo,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.porcentajeMatch.toStringAsFixed(0)}% MATCH',
                              style: TextStyle(
                                color: seriesColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.razones.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Criterio: ${item.razones.join(" • ")}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          final colorTriage = s.codigoColor?.toUpperCase() == 'ROJO'
                              ? 'Rojo'
                              : (s.codigoColor?.toUpperCase() == 'AMARILLO' ? 'Amarillo' : 'Verde');
                          widget.onAsignarFicha(s, colorTriage);
                        },
                        icon: Icon(
                          isCurrent ? Icons.check_circle_rounded : Icons.add_task_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isCurrent ? 'FICHA ASIGNADA ACTUALMENTE' : 'ASIGNAR ESTA FICHA A LA VÍCTIMA',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent ? Colors.green.shade800 : seriesColor,
                          foregroundColor: isCurrent ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasBoundedHeight
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: resultsContent,
              )
            : resultsContent,
      ),
    );
  }
}
