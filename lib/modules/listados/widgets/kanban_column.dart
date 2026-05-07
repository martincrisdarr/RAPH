import 'package:flutter/material.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final int count;
  final Function(String) onAccept;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.children,
    required this.onAccept,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isHovering 
                ? theme.colorScheme.primary.withOpacity(0.05)
                : theme.colorScheme.background.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: isHovering 
                ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
