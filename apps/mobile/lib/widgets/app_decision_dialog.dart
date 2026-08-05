import 'package:flutter/material.dart';

class AppDecisionAction<T> {
  const AppDecisionAction({
    required this.label,
    required this.value,
    this.kind = AppDecisionActionKind.secondary,
  });

  final String label;
  final T value;
  final AppDecisionActionKind kind;
}

enum AppDecisionActionKind { primary, secondary, destructive, text }

Future<T?> showAppDecisionDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<AppDecisionAction<T>> actions,
}) => showDialog<T>(
  context: context,
  builder: (dialogContext) {
    final media = MediaQuery.of(dialogContext);
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: (media.size.height - media.viewInsets.bottom) * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(dialogContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              content,
              const SizedBox(height: 24),
              for (var index = 0; index < actions.length; index++) ...[
                _DecisionButton(action: actions[index]),
                if (index != actions.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  },
);

class _DecisionButton<T> extends StatelessWidget {
  const _DecisionButton({required this.action});

  final AppDecisionAction<T> action;

  @override
  Widget build(BuildContext context) {
    void onPressed() => Navigator.pop(context, action.value);
    return switch (action.kind) {
      AppDecisionActionKind.primary => FilledButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
      AppDecisionActionKind.secondary => OutlinedButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
      AppDecisionActionKind.destructive => TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: onPressed,
        child: Text(action.label),
      ),
      AppDecisionActionKind.text => TextButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
    };
  }
}
