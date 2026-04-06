import 'package:flutter/material.dart';
import '../../design_system/tokens/g_tokens.dart';

/// Standardised loading spinner — use instead of bare CircularProgressIndicator.
class AppLoadingSpinner extends StatelessWidget {
  const AppLoadingSpinner({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: GTokens.space4),
          Text(message!),
        ],
      ]),
    );
  }
}

/// Standardised error view with optional retry action.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GTokens.space6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: GTokens.space4),
          Text(error.toString(), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: GTokens.space4),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ]),
      ),
    );
  }
}
