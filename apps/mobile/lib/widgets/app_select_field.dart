import 'package:flutter/material.dart';

import 'safe_sheet_scaffold.dart';

class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

class AppSelectField<T> extends FormField<T> {
  AppSelectField({
    required String label,
    required List<AppSelectOption<T>> options,
    required T initialValue,
    required ValueChanged<T> onChanged,
    String? helperText,
    bool isEnabled = true,
    String? Function(T?)? validation,
    super.key,
  }) : super(
         initialValue: initialValue,
         enabled: isEnabled,
         validator: (value) {
           final available = options.any((option) => option.value == value);
           if (!available) return 'Kies een geldige optie';
           return validation?.call(value);
         },
         builder: (state) {
           final selected = options.cast<AppSelectOption<T>?>().firstWhere(
             (option) => option?.value == state.value,
             orElse: () => null,
           );
           return InkWell(
             borderRadius: BorderRadius.circular(12),
             onTap: isEnabled && options.isNotEmpty
                 ? () async {
                     final result =
                         await showSafeModalSheet<AppSelectOption<T>>(
                           context: state.context,
                           builder: (sheetContext) => _AppSelectSheet<T>(
                             title: label,
                             options: options,
                             selectedValue: state.value,
                           ),
                         );
                     if (result == null) return;
                     state.didChange(result.value);
                     onChanged(result.value);
                   }
                 : null,
             child: InputDecorator(
               // A visible fallback is still content. Marking this decorator as
               // empty would leave the label inline and paint both strings on
               // top of each other.
               isEmpty: false,
               decoration: InputDecoration(
                 labelText: label,
                 helperText: helperText,
                 errorText:
                     state.errorText ??
                     (selected == null ? 'Kies een geldige optie' : null),
                 enabled: isEnabled,
                 suffixIcon: const Icon(Icons.arrow_drop_down),
               ),
               child: Text(
                 selected?.label ?? 'Keuze niet beschikbaar',
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           );
         },
       );

  @override
  FormFieldState<T> createState() => _AppSelectFieldState<T>();
}

class _AppSelectFieldState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(covariant AppSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      // FormField only applies initialValue when its state is first created.
      // Keep this reusable field synchronized with its owning form when a
      // dependent selection changes.
      setValue(widget.initialValue);
    }
  }
}

class _AppSelectSheet<T> extends StatefulWidget {
  const _AppSelectSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<AppSelectOption<T>> options;
  final T? selectedValue;

  @override
  State<_AppSelectSheet<T>> createState() => _AppSelectSheetState<T>();
}

class _AppSelectSheetState<T> extends State<_AppSelectSheet<T>> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = widget.options.where((option) {
      if (query.isEmpty) return true;
      return option.label.toLowerCase().contains(query) ||
          (option.subtitle?.toLowerCase().contains(query) ?? false);
    }).toList();
    return SafeSheetScaffold(
      title: widget.title,
      actions: const [],
      bodyPadding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.options.length >= 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Zoeken',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          for (final option in visible)
            _SelectRow<T>(
              option: option,
              selected: option.value == widget.selectedValue,
            ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Geen resultaten'),
            ),
        ],
      ),
    );
  }
}

class _SelectRow<T> extends StatelessWidget {
  const _SelectRow({required this.option, required this.selected});

  final AppSelectOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: option.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: selected ? colors.secondaryContainer : null,
          textColor: selected ? colors.onSecondaryContainer : null,
          iconColor: selected ? colors.onSecondaryContainer : null,
          title: Text(
            option.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: selected
                ? const TextStyle(fontWeight: FontWeight.w700)
                : null,
          ),
          subtitle: option.subtitle == null ? null : Text(option.subtitle!),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(context, option),
        ),
      ),
    );
  }
}
