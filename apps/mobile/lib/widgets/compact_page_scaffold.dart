import 'package:flutter/material.dart';

/// A consistently compact page shell for secondary and tab-level screens.
///
/// The body is protected from top system insets by the app bar. Bottom insets
/// are deliberately left to scroll views or [SafeBottomActionBar], so pages do
/// not end up with duplicate padding.
class CompactPageScaffold extends StatelessWidget {
  const CompactPageScaffold({
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.automaticallyImplyLeading = true,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool automaticallyImplyLeading;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(top: false, bottom: false, child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
