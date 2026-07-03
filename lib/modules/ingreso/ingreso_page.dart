import 'package:flutter/material.dart';
import '../../config/auth_controller.dart';
import '../../shared/components/custom_stepper.dart';
import 'widgets/ingreso_section_card.dart';
import 'widgets/ingreso_form_section.dart';
import 'widgets/ubicacion_section.dart';
import 'widgets/incidente_section.dart';
import 'widgets/novedades_section.dart';
import 'widgets/protocolos_panel.dart';
import 'widgets/datos_victimas_section.dart';
import 'widgets/resumen_victimas_section.dart';
import 'widgets/llamadas_asociadas_section.dart';
import 'controllers/ingreso_controller.dart';
import '../despacho/controllers/despacho_controller.dart';
import '../../shared/models/demanda_recibida.dart';
import '../../shared/services/incidente_service.dart';
import '../../shared/services/demanda_recibida_service.dart';
import '../../shared/services/victima_service.dart';
import '../../shared/services/configuracion_service.dart';
import '../../shared/models/configuracion.dart';

class IngresoPage extends StatefulWidget {
  const IngresoPage({super.key});

  @override
  State<IngresoPage> createState() => _IngresoPageState();
}

class _IngresoPageState extends State<IngresoPage> {
  int _currentStep = 0;
  bool _isActionPanelOpen = false;
  List<Configuracion> _tiposIngreso = [];

  @override
  void initState() {
    super.initState();
    _cargarTiposIngreso();
  }

  Future<void> _cargarTiposIngreso() async {
    try {
      final tipos = await ConfiguracionService.obtenerTiposIngreso();
      if (mounted) {
        setState(() {
          _tiposIngreso = tipos;
        });
      }
    } catch (_) {}
  }

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
                      SizedBox(
                        height: 780,
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
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarDialogoCerrarIncidenteDesdeIngreso(context),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text(
                              'SOLICITAR CIERRE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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

  void _mostrarDialogoCerrarIncidenteDesdeIngreso(BuildContext context) {
    final controller = IngresoController();
    final demanda = controller.demandaActual;
    final inc = controller.incidenteActual;
    
    // Si hay víctimas cargadas en el controlador local, las listamos en el diálogo
    final victimas = controller.victimas;

    final reporteIncidenteController = TextEditingController();
    final Map<String, TextEditingController> victimasControllers = {};
    for (var v in victimas) {
      victimasControllers[v.id] = TextEditingController();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2429),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12, width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent.shade700, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Cerrar Incidente y Generar Reportes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildResumenDatosCargados(context),
                  const SizedBox(height: 12),
                  const Text(
                    'Ingresá los detalles del cierre para finalizar este incidente.',
                    style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reporteIncidenteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Reporte del Incidente',
                      alignLabelWithHint: true,
                      hintText: 'Escribe el reporte de lo sucedido...',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.greenAccent.shade700, width: 1.5),
                      ),
                    ),
                  ),
                  if (victimas.isNotEmpty && victimas.any((v) => v.nombre.isNotEmpty || v.dni.isNotEmpty)) ...[
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      'Reporte de las Víctimas:',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ...victimas.where((v) => v.nombre.isNotEmpty || v.dni.isNotEmpty).map((v) {
                      final controller = victimasControllers[v.id];
                      if (controller == null) return const SizedBox.shrink();
                      final nombre = v.nombre.isNotEmpty ? v.nombre : 'Víctima sin nombre';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextFormField(
                          controller: controller,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reporte para: $nombre',
                            alignLabelWithHint: true,
                            hintText: 'Detalles del estado/atención...',
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.02),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white12, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.greenAccent.shade700, width: 1.5),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                reporteIncidenteController.dispose();
                for (var c in victimasControllers.values) {
                  c.dispose();
                }
                Navigator.pop(context);
              },
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  var idDemanda = demanda.idDemandaRecibida;
                  var idInc = inc.idIncidente;

                  // 1. Guardar Incidente si es nuevo
                  if (idInc == null) {
                    final creadoInc = await IncidenteService.crear(inc);
                    if (creadoInc != null && creadoInc.idIncidente != null) {
                      idInc = creadoInc.idIncidente;
                    }
                  }

                  // 2. Guardar Demanda si es nueva
                  if (idDemanda == null) {
                    final demandaConInc = demanda.copyWith(idIncidente: idInc);
                    final creadaDem = await DemandaRecibidaService.crear(demandaConInc);
                    if (creadaDem != null && creadaDem.idDemandaRecibida != null) {
                      idDemanda = creadaDem.idDemandaRecibida;
                    }
                  }

                  // 3. Guardar Víctimas y mapear reportes por idVictima
                  final Map<int, String> reportesVictimas = {};
                  for (var v in victimas) {
                    if (v.nombre.isNotEmpty || v.dni.isNotEmpty || v.idConfGenero != null) {
                      final payload = v.toVictima(idInc);
                      if (v.idVictima == null) {
                        final creadaV = await VictimaService.crear(payload);
                        if (creadaV != null && creadaV.idVictima != null) {
                          v.idVictima = creadaV.idVictima;
                        }
                      } else {
                        await VictimaService.actualizar(payload);
                      }
                      
                      if (v.idVictima != null) {
                        final repText = victimasControllers[v.id]?.text.trim() ?? '';
                        reportesVictimas[v.idVictima!] = repText;
                      }
                    }
                  }

                  // 4. Cerrar incidente usando DespachoController
                  if (idDemanda != null) {
                    final despachoController = DespachoController();
                    await despachoController.cerrarIncidente(
                      idDemanda,
                      reporteIncidenteController.text.trim(),
                      reportesVictimas,
                    );
                  }

                  // Desvincular e iniciar nuevo borrador limpio en ingreso
                  await controller.prepararNuevoIncidente();

                  reporteIncidenteController.dispose();
                  for (var c in victimasControllers.values) {
                    c.dispose();
                  }

                  if (context.mounted) {
                    Navigator.pop(context); // Cierra loading
                    Navigator.pop(context); // Cierra diálogo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incidente cerrado y guardado con éxito.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Cierra loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar incidente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('CONFIRMAR Y CERRAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumenDatosCargados(BuildContext context) {
    final controller = IngresoController();
    final demanda = controller.demandaActual;
    final inc = controller.incidenteActual;
    final victimas = controller.victimas;

    final List<Widget> summaryItems = [];

    // --- SECCIÓN LLAMADA ---
    final List<String> llamadaFields = [];
    String? tipoIngresoNombre;
    if (demanda.tipoIngreso?.descripcion != null) {
      tipoIngresoNombre = demanda.tipoIngreso!.descripcion;
    } else if (demanda.idCfgTipoIngreso != null) {
      final match = _tiposIngreso.firstWhere(
        (t) => t.idconfiguracion == demanda.idCfgTipoIngreso,
        orElse: () => Configuracion(
          idconfiguracion: demanda.idCfgTipoIngreso!,
          idconfiguraciontipo: 3,
          nombre: 'ID: ${demanda.idCfgTipoIngreso}',
          descripcion: 'ID: ${demanda.idCfgTipoIngreso}',
          activo: 1,
          tipoActivo: 1,
          orden: 0,
        ),
      );
      tipoIngresoNombre = match.descripcion;
    }
    
    if (tipoIngresoNombre != null) {
      llamadaFields.add('Tipo de Ingreso: $tipoIngresoNombre');
    }
    if (demanda.nroLlamadaEntrante != null) {
      llamadaFields.add('Teléfono: ${demanda.nroLlamadaEntrante}');
    }
    if (demanda.apellidoNombre != null && demanda.apellidoNombre!.isNotEmpty) {
      llamadaFields.add('Llamante: ${demanda.apellidoNombre}');
    }

    if (llamadaFields.isNotEmpty) {
      summaryItems.add(
        _buildResumenGrupo(
          icon: Icons.phone_callback_rounded,
          title: 'DATOS DE LLAMADA',
          fields: llamadaFields,
          color: Colors.blueAccent,
        ),
      );
    }

    // --- SECCIÓN UBICACIÓN ---
    final List<String> ubicacionFields = [];
    if (inc.direccion != null && inc.direccion!.isNotEmpty) {
      ubicacionFields.add('Dirección: ${inc.direccion}');
    }
    if (inc.latitud != null && inc.longitud != null) {
      ubicacionFields.add('Coordenadas: ${inc.latitud!.toStringAsFixed(5)}, ${inc.longitud!.toStringAsFixed(5)}');
    }

    if (ubicacionFields.isNotEmpty) {
      summaryItems.add(
        _buildResumenGrupo(
          icon: Icons.location_on_rounded,
          title: 'UBICACIÓN',
          fields: ubicacionFields,
          color: Colors.orangeAccent,
        ),
      );
    }

    // --- SECCIÓN INCIDENTE ---
    final List<String> incidenteFields = [];
    if (inc.codigoTriage != null && inc.codigoTriage!.isNotEmpty) {
      incidenteFields.add('Triage: ${inc.codigoTriage}');
    }
    if (inc.descripcion != null && inc.descripcion!.isNotEmpty) {
      incidenteFields.add('Detalles: ${inc.descripcion}');
    }

    if (incidenteFields.isNotEmpty) {
      summaryItems.add(
        _buildResumenGrupo(
          icon: Icons.warning_rounded,
          title: 'INCIDENTE',
          fields: incidenteFields,
          color: Colors.redAccent,
        ),
      );
    }

    // --- SECCIÓN VÍCTIMAS ---
    final List<Widget> victimasWidgets = [];
    for (int i = 0; i < victimas.length; i++) {
      final v = victimas[i];
      final List<String> vFields = [];
      
      final String nombreCompStr = v.nombre.isNotEmpty ? v.nombre : 'Víctima ${i + 1}';
      
      if (v.dni.isNotEmpty) vFields.add('DNI: ${v.dni}');
      if (v.edad.isNotEmpty) vFields.add('Edad: ${v.edad} años');
      if (v.idConfGenero != null) {
        final genStr = v.idConfGenero == 1 ? 'Masculino' : (v.idConfGenero == 2 ? 'Femenino' : 'Otro');
        vFields.add('Género: $genStr');
      }
      if (v.codigoTriage != null && v.codigoTriage!.isNotEmpty) {
        vFields.add('Triage: ${v.codigoTriage}');
      }
      if (v.sintomasSeleccionados.isNotEmpty) {
        vFields.add('Síntomas: ${v.sintomasSeleccionados.join(", ")}');
      }
      if (v.observaciones.isNotEmpty) {
        vFields.add('Observaciones: ${v.observaciones}');
      }

      if (vFields.isNotEmpty) {
        victimasWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreCompStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                ...vFields.map((f) => Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.white30, fontSize: 12)),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      }
    }

    if (victimasWidgets.isNotEmpty) {
      summaryItems.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_rounded, color: Colors.tealAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'VÍCTIMAS REGISTRADAS (${victimasWidgets.length})',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...victimasWidgets,
            ],
          ),
        ),
      );
    }

    if (summaryItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RESUMEN DE DATOS COMPLETOS:',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ...summaryItems,
        ],
      ),
    );
  }

  Widget _buildResumenGrupo({
    required IconData icon,
    required String title,
    required List<String> fields,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.white30, fontSize: 12)),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
