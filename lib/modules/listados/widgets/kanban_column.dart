import 'package:flutter/material.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final int count;
  final Function(String) onAccept;
  final bool isGrid;
  final Color? accentColor;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.children,
    required this.onAccept,
    this.count = 0,
    this.isGrid = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: isHovering
                ? effectiveAccent.withOpacity(0.1)
                : (theme.brightness == Brightness.dark
                    ? const Color(0xFF1B202E)
                    : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering
                  ? effectiveAccent
                  : (theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.15)
                      : theme.colorScheme.outline.withOpacity(0.3)),
              width: isHovering ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado de la columna con separador inferior
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: effectiveAccent.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.12)
                          : theme.colorScheme.outline.withOpacity(0.2),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: effectiveAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: effectiveAccent.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: effectiveAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: effectiveAccent.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        count.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: effectiveAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Área del contenido de tarjetas
              Expanded(
                child: isGrid
                    ? Builder(
                        builder: (context) {
                          final List<Widget> leftChildren = [];
                          final List<Widget> rightChildren = [];
                          for (int i = 0; i < children.length; i++) {
                            if (i % 2 == 0) {
                              leftChildren.add(children[i]);
                            } else {
                              rightChildren.add(children[i]);
                            }
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: leftChildren,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    children: rightChildren,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: children,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
