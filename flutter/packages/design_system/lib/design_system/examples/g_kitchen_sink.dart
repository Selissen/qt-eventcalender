import 'dart:async';
import 'package:flutter/material.dart';
import '../tokens/g_tokens.dart';
import '../components/g_button.dart';
import '../components/g_text_field.dart';

class GKitchenSink extends StatefulWidget {
  const GKitchenSink({super.key});

  @override
  State<GKitchenSink> createState() => _GKitchenSinkState();
}

class _GKitchenSinkState extends State<GKitchenSink> {
  bool _loading = false;
  Timer? _loadingTimer;

  void _startLoading() {
    setState(() => _loading = true);
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('G Design System')),
      body: ListView(
        padding: const EdgeInsets.all(GTokens.space4),
        children: [
          _section('Button variants — md', _buttonVariantsSection(GButtonSize.md)),
          _section('Button variants — sm', _buttonVariantsSection(GButtonSize.sm)),
          _section('Button variants — lg', _buttonVariantsSection(GButtonSize.lg)),
          _section('With icons', _withIconsSection()),
          _section('States', _statesSection()),
          _section('Icon buttons', _iconButtonsSection()),
          _section('Vertical alignment', _verticalAlignmentSection()),
          _section('Inputs', _inputsSection()),
          _section('Input sizes', _inputSizesSection()),
        ],
      ),
    );
  }

  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: GTokens.space3),
          content,
        ],
      ),
    );
  }

  Widget _buttonVariantsSection(GButtonSize size) {
    return Wrap(
      spacing: GTokens.space2,
      runSpacing: GTokens.space2,
      children: GButtonVariant.values.map((v) => GButton(
        label:   v.name,
        size:    size,
        variant: v,
        onPressed: () {},
      )).toList(),
    );
  }

  Widget _withIconsSection() {
    return Wrap(
      spacing: GTokens.space2,
      runSpacing: GTokens.space2,
      children: [
        GButton(label: 'Leading', onPressed: () {}, leading: const Icon(Icons.add)),
        GButton(label: 'Trailing', onPressed: () {}, trailing: const Icon(Icons.arrow_forward)),
        GButton(label: 'Both', onPressed: () {}, leading: const Icon(Icons.upload), trailing: const Icon(Icons.check)),
        GButton(label: 'Danger', variant: GButtonVariant.danger, onPressed: () {}, leading: const Icon(Icons.delete_outline)),
      ],
    );
  }

  Widget _statesSection() {
    return Wrap(
      spacing: GTokens.space2,
      runSpacing: GTokens.space2,
      children: [
        GButton(label: 'Enabled',          onPressed: () {}),
        const GButton(label: 'Disabled',   onPressed: null),
        GButton(label: 'Loading', loading: _loading, onPressed: _startLoading),
        const GButton(label: 'Disabled outlined', variant: GButtonVariant.neutral, onPressed: null),
      ],
    );
  }

  Widget _iconButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All variants
        Wrap(
          spacing: GTokens.space2,
          runSpacing: GTokens.space2,
          children: GButtonVariant.values.map((v) => GIconButton(
            icon:    const Icon(Icons.star_outline),
            variant: v,
            onPressed: () {},
            tooltip: v.name,
          )).toList(),
        ),
        const SizedBox(height: GTokens.space2),
        // All sizes
        Wrap(
          spacing: GTokens.space2,
          runSpacing: GTokens.space2,
          children: GButtonSize.values.map((s) => GIconButton(
            icon:    const Icon(Icons.settings_outlined),
            size:    s,
            onPressed: () {},
            tooltip: s.name,
          )).toList(),
        ),
      ],
    );
  }

  Widget _verticalAlignmentSection() {
    Widget row(GButtonSize size, GTextFieldSize tfSize) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: GTextField(hint: size.name, size: tfSize)),
        const SizedBox(width: GTokens.space2),
        GButton(label: 'Go', size: size, onPressed: () {}),
        const SizedBox(width: GTokens.space2),
        GIconButton(icon: const Icon(Icons.search), size: size, onPressed: () {}),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(GButtonSize.md, GTextFieldSize.md),
        const SizedBox(height: GTokens.space2),
        row(GButtonSize.sm, GTextFieldSize.sm),
      ],
    );
  }

  Widget _inputsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTextField(label: 'Email', hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: GTokens.space4),
        const GTextField(label: 'Username', hint: 'Choose a username', helperText: 'Letters and numbers only'),
        const SizedBox(height: GTokens.space4),
        const GTextField(label: 'Username', hint: 'Choose a username', errorText: 'Username already taken'),
        const SizedBox(height: GTokens.space4),
        const GTextField.password(label: 'Password', hint: '••••••••'),
        const SizedBox(height: GTokens.space4),
        const GTextField(label: 'Read only', hint: 'Cannot edit', readOnly: true),
        const SizedBox(height: GTokens.space4),
        const GTextField(label: 'Disabled', hint: 'Disabled field', enabled: false),
      ],
    );
  }

  Widget _inputSizesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTextField(label: 'Small (sm)', hint: '28px', size: GTextFieldSize.sm),
        const SizedBox(height: GTokens.space4),
        const GTextField(label: 'Medium (md)', hint: '32px', size: GTextFieldSize.md),
        const SizedBox(height: GTokens.space4),
        const GTextField(label: 'Large (lg)', hint: '40px', size: GTextFieldSize.lg),
      ],
    );
  }
}
