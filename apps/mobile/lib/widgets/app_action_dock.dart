import 'package:flutter/material.dart';

/// A detached, inset-safe action surface shared by forms and detail pages.
class AppActionDock extends StatelessWidget {
  const AppActionDock({
    required this.actions,
    this.leading,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 12),
    super.key,
  });

  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Material(
          key: const ValueKey('app-action-dock-surface'),
          elevation: 3,
          color: colors.surfaceContainer,
          shadowColor: colors.shadow.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[leading!, const SizedBox(height: 10)],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stack =
                        actions.length > 2 || constraints.maxWidth < 260;
                    if (stack) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < actions.length;
                            index++
                          ) ...[
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: actions[index],
                            ),
                            if (index != actions.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (
                          var index = 0;
                          index < actions.length;
                          index++
                        ) ...[
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: actions[index],
                            ),
                          ),
                          if (index != actions.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
