import 'package:flutter/material.dart';

class KanbanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final String priority;
  final Color priorityColor;
  final String movil;
  final Function(MouseCursor) onCursorChange;

  const KanbanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.movil,
    required this.onCursorChange,
    this.priority = 'Media',
    this.priorityColor = Colors.orange,
  });

  @override
  State<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<KanbanCard> {
  bool _isDragging = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final cardContent = Container(
      width: 280, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.priorityColor.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.priorityColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: widget.priorityColor.withOpacity(0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.priority,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.priorityColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.time,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      widget.movil,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, size: 18, color: Colors.white30),
            ],
          ),
        ],
      ),
    );

    return Listener(
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        widget.onCursorChange(SystemMouseCursors.grabbing);
      },
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        if (!_isDragging) {
          widget.onCursorChange(SystemMouseCursors.basic);
        }
      },
      child: Draggable<String>(
        data: widget.title,
        onDragStarted: () {
          setState(() => _isDragging = true);
          widget.onCursorChange(SystemMouseCursors.grabbing);
        },
        onDragEnd: (_) {
          setState(() {
            _isDragging = false;
            _isPressed = false;
          });
          widget.onCursorChange(SystemMouseCursors.basic);
        },
        onDraggableCanceled: (_, __) {
          setState(() {
            _isDragging = false;
            _isPressed = false;
          });
          widget.onCursorChange(SystemMouseCursors.basic);
        },
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: cardContent,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: cardContent,
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => widget.onCursorChange(SystemMouseCursors.grab),
          onExit: (_) {
            if (!_isPressed && !_isDragging) {
              widget.onCursorChange(SystemMouseCursors.basic);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
