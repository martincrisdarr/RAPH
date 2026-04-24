import 'package:flutter/material.dart';
import 'protocolo_heimlich.dart';
import 'protocolo_cincinnati.dart';
import 'protocolo_rcp.dart';
import 'protocolo_victimas.dart';

class ProtocolosSidePanel extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const ProtocolosSidePanel({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<ProtocolosSidePanel> createState() => _ProtocolosSidePanelState();
}

class _ProtocolosSidePanelState extends State<ProtocolosSidePanel> {
  String _selectedProtocol = 'rcp';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double panelWidth = 600;
    const double tabWidth = 32;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: widget.isOpen ? 0 : -panelWidth,
      width: panelWidth + tabWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pestaña (Arrow)
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onToggle,
                child: Container(
                  width: tabWidth,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: const Border(
                      left: BorderSide(color: Colors.white10),
                      top: BorderSide(color: Colors.white10),
                      bottom: BorderSide(color: Colors.white10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(-2, 0),
                      )
                    ],
                  ),
                  child: Icon(
                    widget.isOpen ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          // Contenedor principal del panel
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: const Border(
                  left: BorderSide(color: Colors.white10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(-4, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Área de contenido según el protocolo seleccionado
                  Expanded(
                    child: _buildContent(theme),
                  ),
                  // Botones inferiores de selección de protocolo
                  _buildBottomButtons(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_selectedProtocol == 'heimlich') {
      return const ProtocoloHeimlichView();
    } else if (_selectedProtocol == 'cincinnati') {
      return const ProtocoloCincinnatiView();
    } else if (_selectedProtocol == 'rcp') {
      return const ProtocoloRcpView();
    } else if (_selectedProtocol == 'victimas') {
      return const ProtocoloVictimasView();
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _buildProtocolButton(theme, 'rcp', 'RCP', '❤️', const Color(0xFF006064)),
          _buildProtocolButton(theme, 'heimlich', 'HEIMLICH', '🤜', const Color(0xFF4A148C)),
          _buildProtocolButton(theme, 'cincinnati', 'CINCINNATI', '🧠', const Color(0xFF0D47A1)),
          _buildProtocolButton(theme, 'victimas', 'VÍCTIMAS MÚLTIPLES', '🚨', Colors.orange.shade800),
        ],
      ),
    );
  }

  Widget _buildProtocolButton(ThemeData theme, String id, String label, String icon, Color color) {
    final isSelected = _selectedProtocol == id;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _selectedProtocol = id;
        });
      },
      icon: Text(icon, style: const TextStyle(fontSize: 18)),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.15),
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(isSelected ? 1.0 : 0.9), width: isSelected ? 2 : 1.5),
        ),
      ),
    );
  }
}
