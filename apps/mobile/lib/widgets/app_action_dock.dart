import 'package:flutter/material.dart';

/// A detached, inset-safe action surface shared by forms and detail pages.
class AppActionDock extends StatelessWidget {
  const AppActionDock({
    required this.actions,
    this.leading,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 0),
    super.key,
  });

  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = <Widget>[?leading, ...actions];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: margin,
        child: Material(
          elevation: 3,
          color: colors.surfaceContainer,
          shadowColor: colors.shadow.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack = items.length > 2 || constraints.maxWidth < 340;
                if (stack) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: items[index],
                        ),
                        if (index != items.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: items[index],
                        ),
                      ),
                      if (index != items.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
