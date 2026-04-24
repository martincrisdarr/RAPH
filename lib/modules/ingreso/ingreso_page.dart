import 'package:flutter/material.dart';
import '../../shared/components/custom_stepper.dart';
import 'widgets/ingreso_section_card.dart';
import 'widgets/ingreso_form_section.dart';
import 'widgets/ubicacion_section.dart';
import 'widgets/incidente_section.dart';
import 'widgets/novedades_section.dart';
import 'widgets/protocolos_panel.dart';
import 'widgets/victimas_section.dart';

class IngresoPage extends StatefulWidget {
  const IngresoPage({super.key});

  @override
  State<IngresoPage> createState() => _IngresoPageState();
}

class _IngresoPageState extends State<IngresoPage> {
  int _currentStep = 0;
  bool _isActionPanelOpen = false;

  final List<String> _steps = [
    'Incidente',
    'Despacho',
    'En sitio',
    'Traslado',
    'Fin',
    'Cierre',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomStepper(
                steps: _steps,
                currentStep: _currentStep,
                onStepTapped: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 380,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(flex: 1, child: IngresoSectionCard(title: 'INGRESO', child: IngresoFormSection())),
                            const SizedBox(width: 16),
                            const Expanded(flex: 1, child: IngresoSectionCard(title: 'UBICACIÓN', child: UbicacionSection())),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 1000,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  const Expanded(flex: 1, child: IngresoSectionCard(title: 'INCIDENTE', child: IncidenteSection())),
                                  const SizedBox(height: 16),
                                  const Expanded(flex: 3, child: IngresoSectionCard(title: 'VÍCTIMAS', child: VictimasSection())),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              flex: 1,
                              child: IngresoSectionCard(title: 'NOVEDADES', child: NovedadesSection())),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        // Backdrop invisible para cerrar el panel al tocar afuera
        if (_isActionPanelOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isActionPanelOpen = false;
                });
              },
              child: const SizedBox.expand(),
            ),
          ),
        // Panel lateral de accesos rápidos
        ProtocolosSidePanel(
          isOpen: _isActionPanelOpen,
          onToggle: () {
            setState(() {
              _isActionPanelOpen = !_isActionPanelOpen;
            });
          },
        ),
      ],
    );
  }
}
