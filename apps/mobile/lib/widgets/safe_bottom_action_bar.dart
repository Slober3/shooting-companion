import 'package:flutter/material.dart';

import 'app_action_dock.dart';

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
  Widget build(BuildContext context) => AppActionDock(
    leading: leading,
    actions: actions,
    margin: EdgeInsets.fromLTRB(
      padding.left == 0 ? 12 : padding.left,
      8,
      padding.right == 0 ? 12 : padding.right,
      padding.bottom < 12 ? 12 : padding.bottom,
    ),
  );
}
