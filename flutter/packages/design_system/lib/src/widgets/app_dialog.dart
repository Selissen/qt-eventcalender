import 'package:flutter/material.dart';
import '../../design_system/tokens/g_tokens.dart';

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
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
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
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
        padding: const EdgeInsets.only(top: GTokens.space2),
        child: content,
      ),
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(
          GTokens.space4, 0, GTokens.space4, GTokens.space4),
    );
  }
}
