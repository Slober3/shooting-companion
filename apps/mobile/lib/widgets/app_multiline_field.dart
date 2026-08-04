import 'package:flutter/material.dart';

class AppMultilineField extends StatelessWidget {
  const AppMultilineField({
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
    textAlignVertical: TextAlignVertical.top,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      counterText: maxLength == null ? null : '',
    ),
    validator: validator,
  );
}
