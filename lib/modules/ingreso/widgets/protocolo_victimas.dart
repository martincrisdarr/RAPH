import 'package:flutter/material.dart';

class ProtocoloVictimasView extends StatelessWidget {
  const ProtocoloVictimasView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    'VÍCTIMAS MÚLTIPLES',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'SELECCIONÁ EL TIPO DE EMERGENCIA',
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
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Expanded(child: _buildCard(theme, '🚗', 'ACCIDENTE VEHICULAR', 'Cód. 116 — 🚓 Policia + 🚒 Bomberos', 'Víctimas, atrapados, sangrado, lesiones evidentes')),
                     const SizedBox(width: 16),
                     Expanded(child: _buildCard(theme, '🏚️', 'DERRUMBE', 'Cód. 120 — 🚓 Policia + 🚒 Bomberos', 'Atrapados, escombros, riesgo de más derrumbe')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Expanded(child: _buildCard(theme, '⚡', 'CATÁSTROFE', 'Cód. 125 — 🚓 Policia + 🚒 Bomberos', 'Múltiples víctimas, origen masivo o natural')),
                     const SizedBox(width: 16),
                     Expanded(child: _buildCard(theme, '☠️', 'GASES TÓXICOS', 'Cód. 121 — 🚓 Policia + 🚒 Bomberos + 🛡️ Defensa Civil', 'Inhalación, cianosis, quemaduras en rostro')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(theme, '🏭', 'ACCIDENTE INDUSTRIAL', 'Cód. 119 — 🚓 Policia + 🚒 Bomberos', 'Atrapados en maquinaria, amputaciones, electrocución, gases tóxicos, múltiples víctimas'),
              
              const SizedBox(height: 24),
              // Bottom Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade700, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400),
                        const SizedBox(width: 8),
                        Text('EN TODOS LOS CASOS', style: TextStyle(color: Colors.orange.shade300, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ]
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No permitas más víctimas · Víctimas en el piso, no las muevas · Facilitá el acceso de los auxilios · Dar aviso a Policia y Bomberos',
                      style: TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
                    )
                  ]
                )
              ),
            ]
          )
        ),
      ]
    );
  }

  Widget _buildCard(ThemeData theme, String icon, String title, String codeString, String desc) {
     return Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
           onTap: () {},
           hoverColor: Colors.orange.withOpacity(0.05),
           splashColor: Colors.orange.withOpacity(0.1),
           highlightColor: Colors.orange.withOpacity(0.05),
           child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(icon, style: const TextStyle(fontSize: 28)),
                   const SizedBox(height: 12),
                   Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                   const SizedBox(height: 8),
                   Text(codeString, style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 13, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                ]
              )
           )
        )
     );
  }
}
