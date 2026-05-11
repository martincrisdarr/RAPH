import 'package:flutter/material.dart';

class ProtocoloCincinnatiView extends StatelessWidget {
  const ProtocoloCincinnatiView({super.key});

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
                'E S C A L A   D E',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    'CINCINNATI',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'DETECCIÓN PREHOSPITALARIA DE ACV',
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
              // Intro Box
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.blue.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                 ),
                 child: RichText(
                   text: const TextSpan(
                     style: TextStyle(color: Colors.white, height: 1.5),
                     children: [
                       TextSpan(text: 'Evaluá los '),
                       TextSpan(text: '3 signos ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                       TextSpan(text: 'en el paciente. Si '),
                       TextSpan(text: 'uno o más son ANORMALES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                       TextSpan(text: ', hay alta sospecha de ACV. Activar protocolo 105/106 y notificar.'),
                     ],
                   ),
                 ),
              ),
              const SizedBox(height: 16),
              
              _buildSignoCard(theme, 1, '😶', 'PARÁLISIS FACIAL', '"Muestre los dientes o sonría"', 'Ambos lados de la cara se mueven igual', 'Un lado no se mueve igual que el otro'),
              const SizedBox(height: 16),
              
              _buildSignoCard(theme, 2, '💪', 'CAÍDA DEL BRAZO', '"Cierre los ojos y extienda ambos brazos hacia adelante durante 10 segundos"', 'Ambos brazos se mantienen igual o no se mueven', 'Un brazo no se mueve o cae respecto al otro'),
              const SizedBox(height: 16),
              
              _buildSignoCard(theme, 3, '🗣️', 'ALTERACIÓN DEL HABLA', '"Repita esta frase: El cielo está azul en Cincinnati"', 'Usa las palabras correctas sin arrastrar', 'Arrastra palabras, usa palabras incorrectas o no puede hablar'),
              const SizedBox(height: 16),
              
              // Interpretation Box
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
                          Icon(Icons.bolt, color: Colors.orange.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'I N T E R P R E T A C I Ó N',
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                         text: const TextSpan(
                           style: TextStyle(color: Colors.white, height: 1.5),
                           children: [
                             TextSpan(text: '1 o más signos ANORMALES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                             TextSpan(text: ' → Alta sospecha de ACV. Activar protocolo '),
                             TextSpan(text: '105', style: TextStyle(fontWeight: FontWeight.bold)),
                             TextSpan(text: ' (pérdida de fuerzas) o '),
                             TextSpan(text: '106', style: TextStyle(fontWeight: FontWeight.bold)),
                             TextSpan(text: ' (dificultad para hablar).\nRegistrar hora de inicio de síntomas. '),
                             TextSpan(text: 'Tiempo es cerebro — no demorar el traslado.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                           ]
                         )
                      ),
                   ]
                 ),
              ),
              const SizedBox(height: 24),

              // Button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('IR AL PROTOCOLO ACV →', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ]
          ),
        ),
      ],
    );
  }

  Widget _buildSignoCard(ThemeData theme, int number, String icon, String title, String instruction, String normal, String abnormal) {
    return Container(
      decoration: BoxDecoration(
         color: theme.colorScheme.surface,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.2),
             blurRadius: 4,
             offset: const Offset(0, 2),
           )
         ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               color: Colors.blue.shade600.withOpacity(0.3),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
             ),
             child: Row(
               children: [
                 Text(icon, style: const TextStyle(fontSize: 24)),
                 const SizedBox(width: 12),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'S I G N O   $number',
                       style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                     ),
                     Text(
                       title,
                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                     )
                   ],
                 )
               ]
             )
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INSTRUCCIÓN AL PACIENTE:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    instruction,
                    style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // NORMAL
                      Expanded(
                        child: Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.green.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.green.withOpacity(0.4)),
                           ),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.start,
                             children: [
                               Icon(Icons.check_box, color: Colors.green.shade400),
                               const SizedBox(height: 4),
                               Text('NORMAL', style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                               const SizedBox(height: 6),
                               Text(normal, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                             ],
                           )
                        )
                      ),
                      const SizedBox(width: 12),
                      // ANORMAL
                      Expanded(
                        child: Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.red.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.red.withOpacity(0.4)),
                           ),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.start,
                             children: [
                               Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400),
                               const SizedBox(height: 4),
                               Text('ANORMAL', style: TextStyle(color: Colors.orange.shade400, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                               const SizedBox(height: 6),
                               Text(abnormal, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                             ],
                           )
                        )
                      ),
                    ]
                  ),
                )
              ],
            )
          )
        ]
      )
    );
  }
}
