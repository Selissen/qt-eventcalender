import 'package:design_system/design_system.dart'
    show
        GButton,
        GButtonVariant,
        GTextField,
        GTokens,
        LoadingView,
        ErrorView,
        EmptyView,
        AppSidebar,
        AppSidebarItem;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart' show backChannel;

/// Dev-only screen that renders all design system components.
/// Accessible via Qt: navBridge->navigateTo("/widget-catalog")
/// or in-app: context.go('/widget-catalog').
class WidgetCatalogScreen extends StatefulWidget {
  const WidgetCatalogScreen({super.key});

  @override
  State<WidgetCatalogScreen> createState() => _WidgetCatalogScreenState();
}

class _WidgetCatalogScreenState extends State<WidgetCatalogScreen> {
  final _textController = TextEditingController();
  bool _buttonLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Catalog'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          TextButton.icon(
            onPressed: () => backChannel.send('back'),
            icon: const Icon(Icons.close),
            label: const Text('Back to Qt'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(GTokens.space6),
        children: [
          _Section(title: 'GButton', children: [
            GButton(label: 'Primary', onPressed: () {}),
            const SizedBox(height: GTokens.space2),
            GButton(
                label: 'With icon',
                leading: const Icon(Icons.add),
                onPressed: () {}),
            const SizedBox(height: GTokens.space2),
            GButton(
                label: 'Loading',
                loading: _buttonLoading,
                onPressed: () =>
                    setState(() => _buttonLoading = !_buttonLoading)),
            const SizedBox(height: GTokens.space2),
            const GButton(label: 'Disabled', onPressed: null),
            const SizedBox(height: GTokens.space2),
            GButton(
                label: 'Danger',
                variant: GButtonVariant.danger,
                onPressed: () {}),
          ]),
          const SizedBox(height: GTokens.space6),
          _Section(title: 'GTextField', children: [
            GTextField(
              controller: _textController,
              label: 'Text field',
              hint: 'Type something…',
            ),
            const SizedBox(height: GTokens.space2),
            const GTextField(
              label: 'With error',
              errorText: 'This field is required',
            ),
            const SizedBox(height: GTokens.space2),
            const GTextField(
              label: 'Disabled',
              enabled: false,
            ),
          ]),
          const SizedBox(height: GTokens.space6),
          _Section(title: 'States', children: [
            const SizedBox(height: 120, child: LoadingView(message: 'Loading…')),
            const SizedBox(height: GTokens.space2),
            SizedBox(
              height: 120,
              child: ErrorView(
                  error: 'Something went wrong', onRetry: () {}),
            ),
            const SizedBox(height: GTokens.space2),
            const SizedBox(
              height: 120,
              child: EmptyView(
                  message: 'No items yet', icon: Icons.inbox_outlined),
            ),
          ]),
          const SizedBox(height: GTokens.space6),
          _Section(title: 'AppSidebar', children: [
            SizedBox(
              height: 300,
              child: Row(children: [
                AppSidebar(
                  items: const [
                    AppSidebarItem(icon: Icons.calendar_month, label: 'Calendar'),
                    AppSidebarItem(icon: Icons.list_alt, label: 'Plans'),
                    AppSidebarItem(icon: Icons.settings, label: 'Settings'),
                  ],
                  selectedIndex: 0,
                  onItemSelected: (_) {},
                ),
                const Expanded(
                  child: Center(child: Text('Main content area')),
                ),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: GTokens.space2),
        ...children,
      ],
    );
  }
}
