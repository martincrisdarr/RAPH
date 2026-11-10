import 'dart:convert';
import 'package:flutter/material.dart';
import '../../shared/services/socket_service.dart';
import '../../shared/widgets/app_toast.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../config/auth_controller.dart';
import '../../shared/components/custom_stepper.dart';
import 'widgets/ingreso_section_card.dart';
import 'widgets/ingreso_form_section.dart';
import 'widgets/ubicacion_section.dart';
import 'widgets/incidente_section.dart';
import 'widgets/novedades_section.dart';
import 'widgets/protocolos_panel.dart';
import 'widgets/datos_victimas_section.dart';
import 'widgets/victima_sintomas_section.dart';
import 'widgets/resumen_victimas_section.dart';
import 'widgets/stepper_victimas_resumen.dart';
import 'widgets/llamadas_asociadas_section.dart';
import 'controllers/ingreso_controller.dart';
import '../despacho/controllers/despacho_controller.dart';
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
  bool _isActionPanelOpen = false;
  List<Configuracion> _tiposIngreso = [];
  void Function(String)? _despachoSocketListener;

  @override
  void initState() {
    super.initState();
    IngresoController().vistaFormulario = true;
    _cargarTiposIngreso();
    IngresoController().actualizarPasoIncidente();
    _despachoSocketListener = (String raw) {
      _handleDespachoSocketEvent(raw);
    };
    SocketService().registerFieldListener('despacho_actualizado', _despachoSocketListener!);
  }

  @override
  void dispose() {
    if (_despachoSocketListener != null) {
      SocketService().unregisterFieldListener('despacho_actualizado', _despachoSocketListener!);
    }
    super.dispose();
  }

  void _handleDespachoSocketEvent(String raw) {
    if (!mounted || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      final Map<String, dynamic>? data = decoded is Map<String, dynamic>
          ? decoded
          : (decoded is Map ? Map<String, dynamic>.from(decoded) : null);

      if (data == null) return;

      final idInc = int.tryParse((data['idincidente'] ?? data['id_incidente'])?.toString() ?? '');
      final currentInc = IngresoController().incidenteActual.idIncidente ??
          IngresoController().demandaActual.idIncidente;

      // Mostrar el toast ÚNICAMENTE si el cambio de estado pertenece al incidente abierto
      if (idInc != null && currentInc != null && idInc == currentInc) {
        final rawEst = (data['estado_operativo'] ?? data['estado'] ?? '').toString().trim().toLowerCase();
        final hospitalNombre = data['hospital_nombre']?.toString()?.trim();
        final movilNombre = (data['movil_nombre'] ?? data['movil'] ??
            (data['idmovil'] != null ? 'Móvil ${data['idmovil']}' : 'Móvil')).toString();

        String estadoTexto = 'ACTUALIZADO';
        ToastType toastType = ToastType.despacho;

        if (rawEst == 'en_sitio' || rawEst == 'en sitio') {
          estadoTexto = 'EN SITIO';
          toastType = ToastType.despacho;
        } else if (rawEst == 'traslado' || rawEst == 'en_traslado') {
          estadoTexto = (hospitalNombre != null && hospitalNombre.isNotEmpty)
              ? 'EN TRASLADO ($hospitalNombre)'
              : 'EN TRASLADO';
          toastType = ToastType.despacho;
        } else if (rawEst == 'finalizado' || rawEst == 'en_hospital') {
          estadoTexto = 'FINALIZADO';
          toastType = ToastType.success;
        } else if (rawEst == 'en_camino') {
          estadoTexto = 'EN CAMINO';
          toastType = ToastType.despacho;
        } else if (rawEst == 'despachado') {
          estadoTexto = 'DESPACHADO';
          toastType = ToastType.despacho;
        } else if (rawEst == 'cancelado') {
          estadoTexto = 'CANCELADO';
          toastType = ToastType.cancelado;
        }

        AppToast.show(
          context,
          title: '$movilNombre • $estadoTexto',
          message: 'El estado del móvil cambió en tiempo real.',
          type: toastType,
          duration: const Duration(milliseconds: 4000),
        );
      }
    } catch (e) {
      debugPrint('[IngresoPage] Error al procesar socket de despacho para toast: $e');
    }
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
    final controller = IngresoController();
    controller.setPasoIncidente(1);
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
              ListenableBuilder(
                listenable: IngresoController(),
                builder: (context, _) {
                  final controller = IngresoController();
                  final resumenList = controller.resumenDespachosVictimas;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomStepper(
                        steps: _steps,
                        currentStep: controller.pasoIncidente,
                      ),
                      if (resumenList.length > 1) ...[
                        const SizedBox(height: 12),
                        StepperVictimasResumen(items: resumenList),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListenableBuilder(
                  listenable: IngresoController(),
                  builder: (context, _) {
                    final controller = IngresoController();
                    final bool isFinalizado = controller.pasoIncidente >= 4;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          if (isFinalizado) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.pasoIncidente >= 5
                                              ? 'Incidente cerrado — Los datos se encuentran en modo de solo lectura. Solo la sección de Novedades permanece habilitada.'
                                              : 'Incidente finalizado — Todas las víctimas completaron su atención. Completá el cierre individual de cada víctima para habilitar el cierre del incidente.',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (controller.pasoIncidente >= 5 &&
                                            controller.incidenteActual.reporte != null &&
                                            controller.incidenteActual.reporte!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Informe de cierre del incidente: ${controller.incidenteActual.reporte}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          SizedBox(
                            height: 470,
                            child: IgnorePointer(
                              ignoring: isFinalizado,
                              child: Opacity(
                                opacity: isFinalizado ? 0.65 : 1.0,
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 1, child: IngresoSectionCard(title: 'INGRESO', child: IngresoFormSection())),
                                    SizedBox(width: 16),
                                    Expanded(flex: 1, child: IngresoSectionCard(title: 'UBICACIÓN', child: UbicacionSection())),
                                  ],
                                ),
                              ),
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
                                  child: IgnorePointer(
                                    ignoring: isFinalizado,
                                    child: Opacity(
                                      opacity: isFinalizado ? 0.65 : 1.0,
                                      child: const IngresoSectionCard(
                                        title: 'INCIDENTE',
                                        child: IncidenteSection(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: IngresoSectionCard(
                                    title: 'NOVEDADES',
                                    child: NovedadesSection(
                                      usuarioActual: RaphAuthController.instance.currentUsername,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 1. Fila Superior: Datos Personales de la Víctima + Resumen
                          const SizedBox(
                            height: 480,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: IngresoSectionCard(
                                    title: 'DATOS DE LA VÍCTIMA',
                                    child: DatosVictimasSection(),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
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

                          // 2. Fila Inferior: Síntomas, Asistencia y Triage de la Víctima Seleccionada
                          Builder(
                            builder: (context) {
                              final victimas = controller.victimas;
                              if (victimas.isEmpty) return const SizedBox.shrink();

                              final selectedIndex = controller.selectedVictimaIndex.clamp(0, victimas.length - 1);
                              final victimaActiva = victimas[selectedIndex];
                              final nombreDisplay = victimaActiva.nombre.trim().isNotEmpty
                                  ? ' (${victimaActiva.nombre.trim()})'
                                  : ' #${selectedIndex + 1}';

                              return SizedBox(
                                height: 640,
                                child: IgnorePointer(
                                  ignoring: isFinalizado,
                                  child: Opacity(
                                    opacity: isFinalizado ? 0.65 : 1.0,
                                    child: IngresoSectionCard(
                                      title: 'SÍNTOMAS Y ASISTENCIA DE VÍCTIMA$nombreDisplay',
                                      child: VictimaSintomasSection(
                                        key: ValueKey('sintomas_sec_${victimaActiva.id}'),
                                        index: selectedIndex,
                                        victima: victimaActiva,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (controller.incidenteActual.idIncidente == null)
                            const SizedBox(height: 24)
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 400,
                                  child: IgnorePointer(
                                    ignoring: isFinalizado,
                                    child: Opacity(
                                      opacity: isFinalizado ? 0.65 : 1.0,
                                      child: const IngresoSectionCard(
                                        title: 'LLAMADAS RECIBIDAS',
                                        child: LlamadasAsociadasSection(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (controller.pasoIncidente == 4)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!controller.todasLasVictimasCerradas) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.info_outline_rounded, size: 15, color: Colors.amberAccent),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Cerrá cada víctima individualmente en "Datos de la Víctima" (${controller.cantidadVictimasCerradas}/${controller.victimas.length} cerradas)',
                                                  style: const TextStyle(
                                                    color: Colors.amberAccent,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        ElevatedButton.icon(
                                          onPressed: controller.todasLasVictimasCerradas
                                              ? () => _mostrarDialogoCerrarIncidenteDesdeIngreso(context)
                                              : null,
                                          icon: const Icon(Icons.task_alt_rounded, size: 16),
                                          label: const Text(
                                            'SOLICITAR CIERRE DEL INCIDENTE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                                            foregroundColor: Colors.redAccent,
                                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
                                            disabledForegroundColor: Colors.white30,
                                            side: BorderSide(
                                              color: controller.todasLasVictimasCerradas
                                                  ? Colors.redAccent
                                                  : Colors.white12,
                                              width: 1,
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
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
        // Panel lateral de accesos rápidos (solo habilitado cuando no está finalizado)
        ListenableBuilder(
          listenable: IngresoController(),
          builder: (context, _) {
            if (IngresoController().pasoIncidente >= 4) {
              return const SizedBox.shrink();
            }
            return ProtocolosSidePanel(
              isOpen: _isActionPanelOpen,
              onToggle: () {
                setState(() {
                  _isActionPanelOpen = !_isActionPanelOpen;
                });
              },
            );
          },
        ),
      ],
    );
  }

  void _mostrarDialogoCerrarIncidenteDesdeIngreso(BuildContext context) {
    final controller = IngresoController();
    final demanda = controller.demandaActual;
    final inc = controller.incidenteActual;
    final victimas = controller.victimas;

    final reporteIncidenteController = TextEditingController(text: inc.reporte ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PointerInterceptor(
          child: AlertDialog(
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
                  'Cierre General del Incidente',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildResumenDatosCargados(context),
                    const SizedBox(height: 12),
                    const Text(
                      'Todas las víctimas cuentan con su cierre individual registrado. Ingresá el informe general para cerrar definitivamente el incidente:',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reporteIncidenteController,
                      maxLines: 4,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Informe / Reporte de Cierre del Incidente',
                        alignLabelWithHint: true,
                        hintText: 'Escribí el resumen final del operativo y cierre del incidente...',
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
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () {
                  reporteIncidenteController.dispose();
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
                  final reporteTexto = reporteIncidenteController.text.trim();
                  if (reporteTexto.isEmpty) {
                    _mostrarToastCierre(
                      context,
                      titulo: 'Informe requerido',
                      mensaje: 'Por favor ingresá el informe de cierre del incidente.',
                      tipo: _ToastCierreTipo.warning,
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => PointerInterceptor(
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  );

                  try {
                    var idDemanda = demanda.idDemandaRecibida;
                    var idInc = inc.idIncidente ?? demanda.idIncidente;

                    if (idInc == null) {
                      final creadoInc = await IncidenteService.crear(inc);
                      if (creadoInc != null && creadoInc.idIncidente != null) {
                        idInc = creadoInc.idIncidente;
                      }
                    }

                    if (idDemanda == null && idInc != null) {
                      final demandaConInc = demanda.copyWith(idIncidente: idInc);
                      final creadaDem = await DemandaRecibidaService.crear(demandaConInc);
                      if (creadaDem != null && creadaDem.idDemandaRecibida != null) {
                        idDemanda = creadaDem.idDemandaRecibida;
                      }
                    }

                    final Map<int, String> reportesVictimas = {};
                    for (var v in victimas) {
                      if (v.idVictima != null && v.reporte != null) {
                        reportesVictimas[v.idVictima!] = v.reporte!;
                      }
                    }

                    // 1. Cerrar incidente en backend (tabla ser_sien_dsp_incidente -> reporte_cierre, activo = 0)
                    if (idInc != null) {
                      await IncidenteService.cerrarIncidente(
                        idIncidente: idInc,
                        reporte: reporteTexto,
                        usuario: RaphAuthController.instance.currentUsername,
                      );
                    }

                    // 2. Actualizar estado en DespachoController y demanda
                    if (idDemanda != null) {
                      final despachoController = DespachoController();
                      await despachoController.cerrarIncidente(
                        idDemanda,
                        reporteTexto,
                        reportesVictimas,
                      );
                    }

                    // 3. Actualizar el estado del incidente en pantalla a Cierre (paso 5)
                    await controller.marcarIncidenteCerrado(
                      reporteTexto,
                      usuario: RaphAuthController.instance.currentUsername,
                    );
                    reporteIncidenteController.dispose();

                    if (context.mounted) {
                      Navigator.pop(context); // Cierra loading
                      Navigator.pop(context); // Cierra diálogo
                      _mostrarToastCierre(
                        context,
                        titulo: 'Incidente cerrado con éxito',
                        mensaje: 'El informe general fue guardado y el estado pasó a Cierre.',
                        tipo: _ToastCierreTipo.success,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Cierra loading
                      _mostrarToastCierre(
                        context,
                        titulo: 'Error al cerrar el incidente',
                        mensaje: '$e',
                        tipo: _ToastCierreTipo.error,
                      );
                    }
                  }
                },
                child: const Text('CONFIRMAR Y CERRAR INCIDENTE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarToastCierre(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required _ToastCierreTipo tipo,
  }) {
    final Color accentColor;
    final IconData iconData;
    switch (tipo) {
      case _ToastCierreTipo.success:
        accentColor = const Color(0xFF10B981);
        iconData = Icons.verified_rounded;
        break;
      case _ToastCierreTipo.warning:
        accentColor = const Color(0xFFF59E0B);
        iconData = Icons.warning_amber_rounded;
        break;
      case _ToastCierreTipo.error:
        accentColor = const Color(0xFFEF4444);
        iconData = Icons.error_outline_rounded;
        break;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        width: 480,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161D24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.55), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.16),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Icon(iconData, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
            ],
          ),
        ),
      ),
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
      if (v.isCerrada) {
        vFields.add('Cierre de víctima: ${v.reporte}');
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

enum _ToastCierreTipo {
  success,
  warning,
  error,
}
