import 'package:flutter/material.dart';

import 'app_action_dock.dart';

class AppFormScaffold extends StatefulWidget {
  const AppFormScaffold({
    required this.title,
    required this.body,
    required this.actions,
    this.dirty = false,
    this.busy = false,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool dirty;
  final bool busy;

  @override
  State<AppFormScaffold> createState() => _AppFormScaffoldState();
}

class _AppFormScaffoldState extends State<AppFormScaffold> {
  var _allowPop = false;

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!widget.dirty || widget.busy) return !widget.busy;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wijzigingen niet bewaren?'),
        content: const Text('Je hebt wijzigingen die nog niet bewaard zijn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Verder bewerken'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Niet bewaren'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop || (!widget.dirty && !widget.busy),
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (await _confirmDiscard(context) && context.mounted) {
        setState(() => _allowPop = true);
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: widget.body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppActionDock(actions: widget.actions),
    ),
  );
}
