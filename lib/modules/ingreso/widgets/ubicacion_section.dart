import 'package:flutter/material.dart';
import '../../../shared/models/localidad.dart';
import '../../../shared/services/localidad_service.dart';
import '../../../shared/components/autocomplete_select.dart';

class UbicacionSection extends StatefulWidget {
  const UbicacionSection({super.key});

  @override
  State<UbicacionSection> createState() => _UbicacionSectionState();
}

class _UbicacionSectionState extends State<UbicacionSection> {
  bool _isLinkMode = false;
  final TextEditingController _domicilioController = TextEditingController();

  @override
  void dispose() {
    _domicilioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Campo Domicilio con modo toggle ---
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _domicilioController,
                decoration: InputDecoration(
                  labelText: _isLinkMode ? 'Pegá el link de WhatsApp...' : 'Domicilio *',
                  labelStyle: TextStyle(
                    color: _isLinkMode ? primary : Colors.white54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isLinkMode ? primary : Colors.white24,
                      width: _isLinkMode ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: primary,
                      width: 2,
                    ),
                  ),
                  fillColor: _isLinkMode
                      ? primary.withValues(alpha: 0.06)
                      : Theme.of(context).inputDecorationTheme.fillColor,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLinkMode)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'LINK',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.link_rounded,
                          color: _isLinkMode ? primary : Colors.white38,
                          size: 20,
                        ),
                        tooltip: _isLinkMode ? 'Volver a modo manual' : 'Pegar link de WhatsApp',
                        onPressed: () {
                          setState(() {
                            _isLinkMode = !_isLinkMode;
                            _domicilioController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AutocompleteSelect<Localidad>(
                label: 'Buscar localidad...',
                fetchSuggestions: (query) => LocalidadService.buscar(query),
                itemLabel: (item) => item.descripcion,
                onSelected: (item) {
                  if (item != null) {
                    debugPrint('Localidad seleccionada: ${item.id} - ${item.nombreCompleto}');
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver en el mapa'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: BorderSide(color: theme.colorScheme.primary),
                  foregroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: Colors.white24, size: 40),
                  SizedBox(height: 8),
                  Text('Google Maps', style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
