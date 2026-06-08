import 'package:flutter/material.dart';
import '../controllers/ingreso_controller.dart';
import '../../../shared/models/demanda_recibida.dart';

class LlamadasAsociadasSection extends StatefulWidget {
  const LlamadasAsociadasSection({super.key});

  @override
  State<LlamadasAsociadasSection> createState() => _LlamadasAsociadasSectionState();
}

class _LlamadasAsociadasSectionState extends State<LlamadasAsociadasSection> {
  final _ingresoController = IngresoController();

  @override
  void initState() {
    super.initState();
    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final llamadas = _ingresoController.llamadasDelIncidente;

    if (llamadas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_callback_rounded, size: 36, color: Colors.white24),
              SizedBox(height: 8),
              Text(
                'No hay llamadas asociadas a este incidente',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: llamadas.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 16),
      itemBuilder: (context, index) {
        final llamada = llamadas[index];
        return _buildLlamadaTile(theme, llamada);
      },
    );
  }

  Widget _buildLlamadaTile(ThemeData theme, DemandaRecibida llamada) {
    String fechaStr = '--/-- --:--';
    if (llamada.fechaHora != null) {
      final f = llamada.fechaHora!;
      fechaStr = '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
    }

    final String telefono = llamada.nroLlamadaEntrante?.toString() ?? 'Sin número';
    final String nombre = llamada.apellidoNombre?.trim() ?? 'Anónimo';
    final String usuario = llamada.usuario?.trim() ?? 'Operador';
    final String tipo = llamada.tipoIngreso?.descripcion ?? 'Llamada';
    final String estado = llamada.estado?.descripcion ?? 'Recibida';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_in_talk_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Call details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$nombre ($telefono)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      fechaStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tipo.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Registró: $usuario',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        estado,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
