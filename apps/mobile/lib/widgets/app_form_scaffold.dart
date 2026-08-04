import 'dart:async';

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
  final _scrollController = ScrollController();
  var _focusGeneration = 0;
  Timer? _focusRevealTimer;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handlePrimaryFocusChanged);
  }

  @override
  void dispose() {
    _focusRevealTimer?.cancel();
    FocusManager.instance.removeListener(_handlePrimaryFocusChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePrimaryFocusChanged() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    final generation = ++_focusGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealFocusedField(focus, generation);
    });
    _focusRevealTimer?.cancel();
    _focusRevealTimer = Timer(const Duration(milliseconds: 260), () {
      _revealFocusedField(focus, generation);
    });
  }

  void _revealFocusedField(FocusNode focus, int generation) {
    if (!mounted || generation != _focusGeneration || !focus.hasFocus) return;
    final fieldContext = focus.context;
    if (fieldContext == null || !_scrollController.hasClients) return;
    final scrollable = Scrollable.maybeOf(fieldContext);
    if (scrollable == null ||
        scrollable.position != _scrollController.position) {
      return;
    }
    Scrollable.ensureVisible(
      fieldContext,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: .12,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: widget.body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppActionDock(actions: widget.actions),
    ),
  );
}
