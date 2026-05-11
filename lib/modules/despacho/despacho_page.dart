import 'package:flutter/material.dart';

class DespachoPage extends StatelessWidget {
  const DespachoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Despacho de Ambulancias',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Gestiona y asigna unidades a los incidentes activos.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('Mapa y Asignación', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
