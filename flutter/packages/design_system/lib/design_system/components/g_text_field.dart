import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/g_tokens.dart';
import '../theme/g_theme_extension.dart';

enum GTextFieldSize { sm, md, lg }

// ── Sizing helper ─────────────────────────────────────────────────────────────

class _TFSizing {
  const _TFSizing({
    required this.height,
    required this.hPad,
    required this.fontSize,
    required this.iconSize,
  });

  final double height;
  final double hPad;
  final double fontSize;
  final double iconSize;

  factory _TFSizing.fromSize(GTextFieldSize size) {
    switch (size) {
      case GTextFieldSize.sm: return const _TFSizing(height: GTokens.componentHeightSm, hPad: GTokens.componentPaddingSmH, fontSize: 12, iconSize: GTokens.componentIconSm);
      case GTextFieldSize.md: return const _TFSizing(height: GTokens.componentHeightMd, hPad: GTokens.componentPaddingMdH, fontSize: 13, iconSize: GTokens.componentIconMd);
      case GTextFieldSize.lg: return const _TFSizing(height: GTokens.componentHeightLg, hPad: GTokens.componentPaddingLgH, fontSize: 14, iconSize: GTokens.componentIconLg);
    }
  }

  /// Inputs always have a border (borderPx = 2).
  EdgeInsets get contentPadding {
    const borderPx = 2.0;
    final vPad = (height - fontSize - borderPx) / 2;
    return EdgeInsets.symmetric(horizontal: hPad, vertical: vPad);
  }

  TextStyle get inputStyle => TextStyle(
    fontSize:   fontSize,
    fontFamily: GTokens.fontFamily,
    fontWeight: FontWeight.w400,
    height:     1.0,
  );
}

// ── Adornment wrapper ─────────────────────────────────────────────────────────

class _FieldAdornment extends StatelessWidget {
  const _FieldAdornment({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Center(child: child),
  );
}

// ── Password toggle ───────────────────────────────────────────────────────────

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({
    required this.obscure,
    required this.onToggle,
    required this.iconSize,
    required this.fieldHeight,
  });

  final bool     obscure;
  final VoidCallback onToggle;
  final double   iconSize;
  final double   fieldHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: _FieldAdornment(
        height: fieldHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GTokens.space3),
          child: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

// ── GTextField ────────────────────────────────────────────────────────────────

class GTextField extends StatefulWidget {
  const GTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.size        = GTextFieldSize.md,
    this.enabled     = true,
    this.readOnly    = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.maxLength,
    this.maxLines    = 1,
    this.autofocus   = false,
  }) : _isPassword = false;

  const GTextField.password({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.size     = GTextFieldSize.md,
    this.enabled  = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.maxLength,
    this.autofocus = false,
  })  : _isPassword  = true,
        obscureText  = true,
        maxLines     = 1;

  final String?                  label;
  final String?                  hint;
  final String?                  helperText;
  final String?                  errorText;
  final TextEditingController?   controller;
  final FocusNode?               focusNode;
  final GTextFieldSize           size;
  final bool                     enabled;
  final bool                     readOnly;
  final bool                     obscureText;
  final TextInputType?           keyboardType;
  final TextInputAction?         textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>?    onChanged;
  final ValueChanged<String>?    onSubmitted;
  final Widget?                  prefix;
  final Widget?                  suffix;
  final int?                     maxLength;
  final int                      maxLines;
  final bool                     autofocus;
  final bool                     _isPassword;

  @override
  State<GTextField> createState() => _GTextFieldState();
}

class _GTextFieldState extends State<GTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final ext    = GThemeExtension.of(context);
    final sizing = _TFSizing.fromSize(widget.size);

    Color? fillColor;
    if (!widget.enabled) {
      fillColor = cs.onSurface.withValues(alpha: 0.04);
    } else if (widget.readOnly) {
      fillColor = ext.surfaceSubtle;
    }

    Widget? suffixWidget = widget.suffix;
    if (widget._isPassword) {
      suffixWidget = _PasswordToggle(
        obscure:     _obscure,
        onToggle:    () => setState(() => _obscure = !_obscure),
        iconSize:    sizing.iconSize,
        fieldHeight: sizing.height,
      );
    }

    BoxConstraints? adornmentConstraints = BoxConstraints(
      minWidth:  sizing.height,
      minHeight: sizing.height,
    );

    final field = TextField(
      controller:          widget.controller,
      focusNode:           widget.focusNode,
      enabled:             widget.enabled,
      readOnly:            widget.readOnly,
      obscureText:         _obscure,
      keyboardType:        widget.keyboardType,
      textInputAction:     widget.textInputAction,
      inputFormatters:     widget.inputFormatters,
      onChanged:           widget.onChanged,
      onSubmitted:         widget.onSubmitted,
      maxLength:           widget.maxLength,
      maxLines:            widget.maxLines,
      autofocus:           widget.autofocus,
      cursorHeight:        sizing.fontSize,
      style:               sizing.inputStyle,
      decoration: InputDecoration(
        hintText:        widget.hint,
        isDense:         true,
        contentPadding:  sizing.contentPadding,
        filled:          true,
        fillColor:       fillColor,
        errorText:       widget.errorText,
        helperText:      widget.helperText,
        helperMaxLines:  3,
        errorMaxLines:   3,
        counterText:     '',
        prefixIcon:      widget.prefix != null
            ? _FieldAdornment(height: sizing.height, child: widget.prefix!)
            : null,
        suffixIcon:      suffixWidget != null
            ? _FieldAdornment(height: sizing.height, child: suffixWidget)
            : null,
        prefixIconConstraints: widget.prefix != null ? adornmentConstraints : null,
        suffixIconConstraints: suffixWidget  != null ? adornmentConstraints : null,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: GTokens.space1),
        ],
        SizedBox(
          height: sizing.height,
          child:  field,
        ),
        if (widget.errorText != null || widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: GTokens.space1),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: widget.errorText != null
                  ? Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error)
                  : Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
