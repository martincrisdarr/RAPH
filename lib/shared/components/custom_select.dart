import 'package:flutter/material.dart';
import 'skeleton_box.dart';

class CustomSelect<T> extends StatefulWidget {
  final String label;
  final List<T>? items;
  final Future<List<T>> Function()? fetchItems;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onSelected;
  final T? initialSelection;

  const CustomSelect({
    super.key,
    required this.label,
    required this.itemLabel,
    this.items,
    this.fetchItems,
    this.onSelected,
    this.initialSelection,
  }) : assert(items != null || fetchItems != null,
            'Debes proveer la lista de items estáticos o la función fetchItems.');

  @override
  State<CustomSelect<T>> createState() => _CustomSelectState<T>();
}

class _CustomSelectState<T> extends State<CustomSelect<T>> {
  List<T> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (widget.items != null) {
      _items = widget.items!;
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
      }
    } catch (e) {
      // Manejar error en la implementación real si es necesario
      debugPrint('Error loading select options: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Estado de carga: usamos SkeletonField para consistencia visual
    if (_isLoading) {
      return SkeletonField(labelWidth: widget.label.length * 7.5);
    }

    return DropdownMenu<T>(
      label: Text(widget.label),
      expandedInsets: EdgeInsets.zero,
      initialSelection: widget.initialSelection,
      inputDecorationTheme: theme.inputDecorationTheme,
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
