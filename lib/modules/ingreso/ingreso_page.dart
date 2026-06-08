import 'package:flutter/material.dart';
import '../../config/auth_controller.dart';
import '../../shared/components/custom_stepper.dart';
import 'widgets/ingreso_section_card.dart';
import 'widgets/ingreso_form_section.dart';
import 'widgets/ubicacion_section.dart';
import 'widgets/incidente_section.dart';
import 'widgets/novedades_section.dart';
import 'widgets/protocolos_panel.dart';
import 'widgets/victimas_section.dart';
import 'widgets/datos_victimas_section.dart';
import 'widgets/resumen_victimas_section.dart';
import 'widgets/llamadas_asociadas_section.dart';
import 'controllers/ingreso_controller.dart';

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

  void _iniciarDespachoRapido() {
    setState(() {
      _currentStep = 1; // Paso Despacho
    });
    
    final controller = IngresoController();
    controller.updateDemanda(idCfgEstado: 6);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Despacho de ambulancia iniciado rápidamente.'),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        height: 470,
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
                        height: 500,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: IngresoSectionCard(
                                title: 'INCIDENTE',
                                child: IncidenteSection(
                                  onDespacho: _iniciarDespachoRapido,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              flex: 1,
                              child: IngresoSectionCard(
                                title: 'RESUMEN DE VÍCTIMAS',
                                child: ResumenVictimasSection(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 500,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: IngresoSectionCard(
                                title: 'VÍCTIMAS',
                                child: DatosVictimasSection(
                                  onDespacho: _iniciarDespachoRapido,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: IngresoSectionCard(
                                title: 'NOVEDADES',
                                child: NovedadesSection(
                                  usuarioActual: () {
                                    final u = RaphAuthController.instance.currentUser;
                                    if (u == null) return 'Sistema';
                                    final nombre = '${u.nombre ?? ''} ${u.apellido ?? ''}'.trim();
                                    return nombre.isNotEmpty ? nombre : (u.email ?? 'Sistema');
                                  }(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        height: 500,
                        child: IngresoSectionCard(title: 'SÍNTOMAS Y ASISTENCIA', child: VictimasSection()),
                      ),
                      ListenableBuilder(
                        listenable: IngresoController(),
                        builder: (context, child) {
                          final controller = IngresoController();
                          if (controller.incidenteActual.idIncidente == null) {
                            return const SizedBox.shrink();
                          }
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 16),
                              SizedBox(
                                height: 400,
                                child: IngresoSectionCard(
                                  title: 'LLAMADAS RECIBIDAS',
                                  child: LlamadasAsociadasSection(),
                                ),
                              ),
                            ],
                          );
                        },
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
