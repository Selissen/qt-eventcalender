import 'package:flutter/material.dart';
import '../../design_system/tokens/g_tokens.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
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

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48,
            color: Theme.of(context).colorScheme.error),
        const SizedBox(height: GTokens.space4),
        Text(error.toString()),
        if (onRetry != null) ...[
          const SizedBox(height: GTokens.space4),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ]),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon ?? Icons.inbox_outlined, size: 48,
            color: onSurface.withValues(alpha: 0.38)),
        const SizedBox(height: GTokens.space4),
        Text(message,
            style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
      ]),
    );
  }
}
