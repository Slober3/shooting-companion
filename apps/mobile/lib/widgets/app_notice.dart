import 'package:flutter/material.dart';

import '../app/theme.dart';

enum AppNoticeKind { success, info, warning, error }

class AppNoticeAction {
  const AppNoticeAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

abstract final class AppMessenger {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required AppNoticeKind kind,
    required String message,
    AppNoticeAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = AppContrastTokens.of(context);
    final (background, foreground, icon, duration) = switch (kind) {
      AppNoticeKind.success => (
        tokens.positive,
        tokens.onPositive,
        Icons.check_circle_outline,
        const Duration(seconds: 3),
      ),
      AppNoticeKind.info => (
        colors.inverseSurface,
        colors.onInverseSurface,
        Icons.info_outline,
        const Duration(seconds: 4),
      ),
      AppNoticeKind.warning => (
        tokens.caution,
        tokens.onCaution,
        Icons.warning_amber_rounded,
        const Duration(seconds: 6),
      ),
      AppNoticeKind.error => (
        tokens.critical,
        tokens.onCritical,
        Icons.error_outline,
        const Duration(seconds: 8),
      ),
    };
    final screenWidth = MediaQuery.sizeOf(context).width;
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
    return messenger.showSnackBar(
      SnackBar(
        key: ValueKey('app-notice-${kind.name}-$message'),
        behavior: SnackBarBehavior.floating,
        width: screenWidth >= 600 ? 560 : null,
        margin: screenWidth >= 600
            ? null
            : const EdgeInsets.fromLTRB(12, 0, 12, 12),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: background,
        closeIconColor: foreground,
        showCloseIcon: true,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        action: action == null
            ? null
            : SnackBarAction(
                label: action.label,
                textColor: foreground,
                onPressed: action.onPressed,
              ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, kind: AppNoticeKind.success, message: message);

  static void info(BuildContext context, String message) =>
      show(context, kind: AppNoticeKind.info, message: message);

  static void warning(BuildContext context, String message) =>
      show(context, kind: AppNoticeKind.warning, message: message);

  static void error(BuildContext context, String message) =>
      show(context, kind: AppNoticeKind.error, message: message);
}
