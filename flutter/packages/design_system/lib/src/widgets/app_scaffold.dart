import 'package:flutter/material.dart';
import '../../design_system/tokens/g_tokens.dart';

/// Standard app scaffold with consistent AppBar styling.
/// Use instead of raw Scaffold + AppBar on all migrated screens.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.endDrawer,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      endDrawer: endDrawer,
    );
  }
}

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
