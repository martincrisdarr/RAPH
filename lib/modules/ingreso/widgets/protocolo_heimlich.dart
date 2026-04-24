import 'package:flutter/material.dart';

class ProtocoloHeimlichView extends StatefulWidget {
  const ProtocoloHeimlichView({super.key});

  @override
  State<ProtocoloHeimlichView> createState() => _ProtocoloHeimlichViewState();
}

class _ProtocoloHeimlichViewState extends State<ProtocoloHeimlichView> {
  String _selectedAge = 'adulto';

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'adulto',
      'title': 'ADULTO',
      'subtitle': '+8 años',
      'icon': '👤',
      'cardTitle': 'Adulto consciente (+8 años)',
      'steps': [
        'Ponete detrás de la persona, con un pie adelante para estabilidad.',
        'Inclinala levemente hacia adelante.',
        'Pasá tus brazos alrededor de su cintura.',
        'Cerrá el puño y colocalo entre el ombligo y el esternón (zona epigástrica).',
        'Con la otra mano cubrí el puño.',
        'Realizá compresiones bruscas hacia ADENTRO y ARRIBA. Repetí hasta desalojar el objeto o que la persona quede inconsciente.',
        'Si pierde el conocimiento: recostala y realizá RCP. En cada apertura de la boca verificá si el objeto es visible antes de ventilar.'
      ],
    },
    {
      'id': 'nino',
      'title': 'NIÑO',
      'subtitle': '1-8 años',
      'icon': '🧒',
      'cardTitle': 'Niño consciente (1–8 años)',
      'steps': [
        'Arrodillate o agachate al nivel del niño.',
        'Ponete detrás del niño y abrazalo.',
        'Localizá el punto entre el ombligo y el esternón.',
        'Usá una mano con el puño cerrado y cubrila con la otra mano.',
        'Realizá compresiones hacia ADENTRO y ARRIBA. Más suaves que en adulto.',
        'Si el niño se desmaya: recostalo y realizá RCP pediátrico.',
        'Revisar la boca antes de cada ventilación en busca del objeto.'
      ],
    },
    {
      'id': 'bebe',
      'title': 'BEBÉ',
      'subtitle': '<1 año',
      'icon': '👶',
      'cardTitle': 'Bebé menor de 1 año',
      'steps': [
        '⚠️ En bebés NO se realiza Heimlich clásico. Usar la siguiente secuencia:',
        'Sostené al bebé boca abajo sobre tu antebrazo, cabeza más baja que el tronco.',
        'Dá 5 PALMADAS firmes en la espalda (entre los omóplatos) con el talón de la mano.',
        'Girá al bebé boca arriba, sobre tu antebrazo.',
        'Realizá 5 COMPRESIONES TORÁCICAS con 2 dedos en el centro del pecho.',
        'Alternár: 5 palmadas dorsales + 5 compresiones. Repetir hasta desalojar o el bebé pierda el conocimiento.',
        'Si queda inconsciente: RCP neonatal. Verificar boca antes de ventilar.'
      ],
    },
    {
      'id': 'embarazada',
      'title': 'EMBARAZADA',
      'subtitle': 'o muy obeso',
      'icon': '🤰',
      'cardTitle': 'Embarazada o persona obesa',
      'steps': [
        'Ponete detrás de la persona.',
        'En lugar de la cintura, rodeá el TÓRAX (por debajo de los brazos).',
        'Colocá el puño en el centro del esternón (NO en el epigastrio).',
        'Realizá compresiones bruscas hacia ADENTRO. No hacia arriba.',
        'Repetí hasta desalojar el objeto o que la persona quede inconsciente.',
        'Si pierde el conocimiento: recostala y realizá RCP. Llamar ayuda de inmediato.'
      ],
    },
    {
      'id': 'inconsciente',
      'title': 'INCONSCIENTE',
      'subtitle': 'cualquier edad',
      'icon': '😵',
      'cardTitle': 'Paciente inconsciente (cualquier edad)',
      'steps': [
        'Recostá al paciente en el suelo en decúbito supino (boca arriba).',
        'Iniciá RCP estándar (30 compresiones + 2 ventilaciones).',
        'ANTES de cada ventilación: abrí la boca y mirá si el objeto es visible.',
        'Si ves el objeto: retiralo con el dedo (barrido con el dedo meñique en adultos, nunca a ciegas en niños).',
        'NO intentés extraer el objeto si no es visible — podés empujarlo más adentro.',
        'Las compresiones torácicas de RCP pueden desalojar el objeto por presión.',
        'Continuá hasta arribo del móvil o resolución del cuadro.'
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedData = _categories.firstWhere((cat) => cat['id'] == _selectedAge);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header titles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Text(
                'M A N I O B R A   D E',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🤜', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    'HEIMLICH',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'DESOBSTRUCCIÓN DE VÍA AÉREA',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        
        // Age selection
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECCIONÁ LA EDAD DEL PACIENTE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildAgeToggle(theme, _categories[0])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAgeToggle(theme, _categories[1])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAgeToggle(theme, _categories[2])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAgeToggle(theme, _categories[3])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAgeToggle(theme, _categories[4])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Steps Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    selectedData['cardTitle'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.deepPurpleAccent.shade100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    itemCount: (selectedData['steps'] as List).length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final steps = selectedData['steps'] as List<String>;
                      final stepText = steps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                stepText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAgeToggle(ThemeData theme, Map<String, dynamic> data) {
    final isSelected = _selectedAge == data['id'];
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAge = data['id'];
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data['icon'], style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    data['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data['subtitle'],
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.white54,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
