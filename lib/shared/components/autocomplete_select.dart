import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Componente de búsqueda typeahead/autocomplete genérico.
/// Llama a [fetchSuggestions] cada vez que el usuario escribe (con debounce),
/// y muestra los resultados en un menú desplegable superpuesto.
class AutocompleteSelect<T extends Object> extends StatefulWidget {
  final String label;
  final String Function(T) itemLabel;
  final Future<List<T>> Function(String query) fetchSuggestions;
  final ValueChanged<T?>? onSelected;
  final T? initialSelection;
  /// Milisegundos a esperar entre keystroke y petición. Default 350ms.
  final int debounceMs;

  const AutocompleteSelect({
    super.key,
    required this.label,
    required this.itemLabel,
    required this.fetchSuggestions,
    this.onSelected,
    this.initialSelection,
    this.debounceMs = 350,
  });

  @override
  State<AutocompleteSelect<T>> createState() => _AutocompleteSelectState<T>();
}

class _AutocompleteSelectState<T extends Object> extends State<AutocompleteSelect<T>> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<T> _suggestions = [];
  bool _isLoading = false;
  T? _selectedItem;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedItem = widget.initialSelection;
      _textController.text = widget.itemLabel(widget.initialSelection as T);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    // Si el usuario está borrando/modificando después de haber seleccionado, resetear selección
    if (_selectedItem != null && widget.itemLabel(_selectedItem as T) != query) {
      _selectedItem = null;
      widget.onSelected?.call(null);
    }

    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.fetchSuggestions(query);
      if (mounted) {
        setState(() => _suggestions = results);
      }
    } catch (e) {
      debugPrint('AutocompleteSelect error: $e');
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSuggestionSelected(T item) {
    setState(() {
      _selectedItem = item;
      _textController.text = widget.itemLabel(item);
      _suggestions = [];
    });
    widget.onSelected?.call(item);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Autocomplete<T>(
      initialValue: TextEditingValue(
        text: widget.initialSelection != null ? widget.itemLabel(widget.initialSelection as T) : '',
      ),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2) return const [];

        // Debounce: cancelar el timer anterior y esperar que el usuario deje de escribir
        _debounce?.cancel();
        final completer = Completer<List<T>>();
        _debounce = Timer(Duration(milliseconds: widget.debounceMs), () async {
          try {
            final results = await widget.fetchSuggestions(textEditingValue.text);
            if (!completer.isCompleted) completer.complete(results);
          } catch (_) {
            if (!completer.isCompleted) completer.complete([]);
          }
        });
        return completer.future;
      },
      displayStringForOption: widget.itemLabel,
      onSelected: (T item) {
        widget.onSelected?.call(item);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: PointerInterceptor(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: theme.scaffoldBackgroundColor,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                constraints: const BoxConstraints(maxHeight: 220),
                child: options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Sin resultados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final item = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                widget.itemLabel(item),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
