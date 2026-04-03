import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_button.dart';

/// Consistent dialog — use instead of raw showDialog + AlertDialog.
///
/// Usage:
///   final confirmed = await AppDialog.confirm(
///     context,
///     title: 'Delete plan?',
///     message: 'This cannot be undone.',
///   );
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  /// Shows a confirmation dialog. Returns true if the user confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows an informational dialog.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        content: Text(message),
        actions: [
          AppButton(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: content,
      ),
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
    );
  }
}
