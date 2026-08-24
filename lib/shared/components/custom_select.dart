import 'package:flutter/material.dart';
import 'skeleton_box.dart';

class CustomSelect<T> extends StatefulWidget {
  final String label;
  final List<T>? items;
  final Future<List<T>> Function()? fetchItems;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onSelected;
  final T? initialSelection;
  /// ID para restaurar la selección tras una carga asíncrona.
  /// Se compara con [matchById] para encontrar el item correcto.
  final dynamic initialSelectionId;
  /// Función que extrae el ID comparable del item. Requerida si [initialSelectionId] es usado.
  final dynamic Function(T)? matchById;
  final bool enabled;

  const CustomSelect({
    super.key,
    required this.label,
    required this.itemLabel,
    this.items,
    this.fetchItems,
    this.onSelected,
    this.initialSelection,
    this.initialSelectionId,
    this.matchById,
    this.enabled = true,
  }) : assert(items != null || fetchItems != null,
            'Debes proveer la lista de items estáticos o la función fetchItems.');

  @override
  State<CustomSelect<T>> createState() => _CustomSelectState<T>();
}

class _CustomSelectState<T> extends State<CustomSelect<T>> {
  List<T> _items = [];
  bool _isLoading = false;
  T? _resolvedInitialSelection;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant CustomSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectionId != oldWidget.initialSelectionId || 
        widget.initialSelection != oldWidget.initialSelection) {
      _resolveInitialSelection();
    }
  }

  void _initData() {
    if (widget.items != null) {
      _items = widget.items!;
      _resolveInitialSelection();
    } else if (widget.fetchItems != null) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.fetchItems!();
      if (mounted) {
        setState(() {
          _items = data;
        });
        _resolveInitialSelection();
      }
    } catch (e) {
      debugPrint('Error loading select options: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Busca en la lista el item cuyo ID coincide con [initialSelectionId].
  void _resolveInitialSelection() {
    if (widget.initialSelection != null) {
      _resolvedInitialSelection = widget.initialSelection;
      return;
    }
    if (widget.initialSelectionId != null && widget.matchById != null) {
      try {
        _resolvedInitialSelection = _items.firstWhere(
          (item) => widget.matchById!(item) == widget.initialSelectionId,
        );
      } catch (_) {
        _resolvedInitialSelection = null;
      }
    } else if (widget.initialSelectionId == null && _items.isNotEmpty) {
      try {
        _resolvedInitialSelection = _items.firstWhere(
          (item) => widget.itemLabel(item).toUpperCase().contains('NUEVO'),
          orElse: () => _items.first,
        );
        if (_resolvedInitialSelection != null && widget.onSelected != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onSelected!(_resolvedInitialSelection);
          });
        }
      } catch (_) {
        _resolvedInitialSelection = null;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return SkeletonField(labelWidth: widget.label.length * 7.5);
    }

    return DropdownMenu<T>(
      key: ValueKey(widget.initialSelectionId),
      enabled: widget.enabled,
      label: Text(widget.label),
      expandedInsets: EdgeInsets.zero,
      initialSelection: _resolvedInitialSelection,
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStatePropertyAll(theme.scaffoldBackgroundColor),
        elevation: const MaterialStatePropertyAll(8),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
        ),
      ),
      dropdownMenuEntries: _items.map((item) {
        return DropdownMenuEntry<T>(
          value: item,
          label: widget.itemLabel(item),
        );
      }).toList(),
      onSelected: widget.onSelected,
    );
  }
}
