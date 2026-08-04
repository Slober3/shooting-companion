import 'package:flutter/material.dart';

import 'safe_bottom_action_bar.dart';

enum SafeSheetPresentation { compact, adaptive, fullScreen }

/// Opens an input sheet with the app's standard safe, keyboard-aware layout.
Future<T?> showSafeModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  SafeSheetPresentation presentation = SafeSheetPresentation.adaptive,
}) {
  final media = MediaQuery.of(context);
  final useFullScreen = switch (presentation) {
    SafeSheetPresentation.compact => false,
    SafeSheetPresentation.fullScreen => true,
    SafeSheetPresentation.adaptive =>
      media.size.height - media.viewPadding.vertical < 600 ||
          media.textScaler.scale(1) >= 1.5,
  };
  if (useFullScreen) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (routeContext) => Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(child: builder(routeContext)),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      child: builder(sheetContext),
    ),
  );
}

/// Keyboard-aware sheet chrome with a scrollable body and fixed safe actions.
///
/// Flutter's modal `useSafeArea` deliberately excludes the bottom edge. The
/// fixed [SafeBottomActionBar] owns that edge while [AnimatedPadding] moves the
/// complete sheet above an on-screen keyboard.
class SafeSheetScaffold extends StatelessWidget {
  const SafeSheetScaffold({
    required this.title,
    required this.body,
    required this.actions,
    this.onClose,
    this.bodyPadding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.maxContentWidth = 640,
    this.scrollController,
    this.contentSized = false,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final EdgeInsets bodyPadding;
  final double maxContentWidth;
  final ScrollController? scrollController;
  final bool contentSized;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final compactHeader =
        media.size.height - keyboardInset - media.viewPadding.vertical < 320;
    final colors = Theme.of(context).colorScheme;
    final titleWidget = Text(
      title,
      maxLines: compactHeader ? 1 : null,
      overflow: compactHeader ? TextOverflow.ellipsis : null,
      style: compactHeader
          ? Theme.of(context).textTheme.titleMedium
          : Theme.of(context).textTheme.titleLarge,
    );
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        key: const ValueKey('safe-sheet-surface'),
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: compactHeader
                      ? const EdgeInsets.fromLTRB(16, 4, 8, 0)
                      : const EdgeInsets.fromLTRB(16, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: compactHeader
                            ? MediaQuery.withClampedTextScaling(
                                maxScaleFactor: 1.3,
                                child: titleWidget,
                              )
                            : titleWidget,
                      ),
                      IconButton(
                        onPressed: onClose ?? () => Navigator.pop(context),
                        tooltip: 'Sluiten',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: contentSized ? 1 : null,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: bodyPadding,
                    child: body,
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty) SafeBottomActionBar(actions: actions),
            if (actions.isEmpty)
              const SafeArea(top: false, child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }
}

/// Places related fields beside each other only when both width and text size
/// leave enough room. Otherwise fields are stacked with predictable spacing.
class AdaptiveFormRow extends StatelessWidget {
  const AdaptiveFormRow({
    required this.children,
    this.spacing = 12,
    this.minimumChildWidth = 180,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final double minimumChildWidth;

  @override
  Widget build(BuildContext context) {
    if (children.length < 2) return children.single;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final requiredWidth =
            minimumChildWidth * children.length +
            spacing * (children.length - 1);
        final stack = constraints.maxWidth < requiredWidth || textScale >= 1.5;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}
