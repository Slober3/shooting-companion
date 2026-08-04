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
        child: OverflowBar(
          alignment: leading == null
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          spacing: 8,
          overflowSpacing: 8,
          overflowAlignment: OverflowBarAlignment.end,
          children: [?leading, ...actions],
        ),
      ),
    );
  }
}
