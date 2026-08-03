import 'package:flutter/material.dart';

/// A bottom action surface that stays clear of gesture and three-button
/// navigation areas and adapts to large system text.
class SafeBottomActionBar extends StatelessWidget {
  const SafeBottomActionBar({
    required this.actions,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 10),
    super.key,
  });

  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        minimum: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stackActions = constraints.maxWidth < 380 || textScale >= 1.5;
            if (stackActions) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading case final leading?) ...[
                    leading,
                    const SizedBox(height: 10),
                  ],
                  for (var index = 0; index < actions.length; index++) ...[
                    actions[index],
                    if (index != actions.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }

            return Row(
              children: [
                if (leading case final leading?) ...[
                  Expanded(child: leading),
                  const SizedBox(width: 12),
                ] else
                  const Spacer(),
                for (var index = 0; index < actions.length; index++) ...[
                  Flexible(child: actions[index]),
                  if (index != actions.length - 1) const SizedBox(width: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
