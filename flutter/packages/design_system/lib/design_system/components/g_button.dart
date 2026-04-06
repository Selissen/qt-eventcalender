import 'package:flutter/material.dart';
import '../tokens/g_tokens.dart';

enum GButtonVariant { primary, secondary, neutral, ghost, danger, dangerGhost }
enum GButtonSize    { sm, md, lg }

// ── Sizing helper ─────────────────────────────────────────────────────────────

class _GSizing {
  const _GSizing({
    required this.height,
    required this.hPad,
    required this.iconSize,
    required this.fontSize,
  });

  final double height;
  final double hPad;
  final double iconSize;
  final double fontSize;

  factory _GSizing.fromSize(GButtonSize size) {
    switch (size) {
      case GButtonSize.sm: return const _GSizing(height: GTokens.componentHeightSm, hPad: GTokens.componentPaddingSmH, iconSize: GTokens.componentIconSm, fontSize: 12);
      case GButtonSize.md: return const _GSizing(height: GTokens.componentHeightMd, hPad: GTokens.componentPaddingMdH, iconSize: GTokens.componentIconMd, fontSize: 13);
      case GButtonSize.lg: return const _GSizing(height: GTokens.componentHeightLg, hPad: GTokens.componentPaddingLgH, iconSize: GTokens.componentIconLg, fontSize: 14);
    }
  }

  /// Vertical padding computed from the height formula:
  ///   vPad = (targetHeight - fontSize - borderPx) / 2
  EdgeInsets padding({required bool hasBorder}) {
    final borderPx = hasBorder ? 2.0 : 0.0;
    final vPad = (height - fontSize - borderPx) / 2;
    return EdgeInsets.symmetric(horizontal: hPad, vertical: vPad);
  }

  TextStyle get textStyle => TextStyle(
    fontSize:   fontSize,
    fontFamily: GTokens.fontFamily,
    fontWeight: FontWeight.w600,
    height:     1.0,
  );
}

// ── Variant colours ───────────────────────────────────────────────────────────

class _VariantStyle {
  const _VariantStyle({
    required this.bg,
    required this.fg,
    this.border,
  });

  final Color  bg;
  final Color  fg;
  final Color? border;

  bool get hasBorder => border != null;
}

_VariantStyle _resolveStyle(GButtonVariant variant, ColorScheme cs) {
  switch (variant) {
    case GButtonVariant.primary:
      return _VariantStyle(bg: cs.primary,    fg: cs.onPrimary);
    case GButtonVariant.secondary:
      return _VariantStyle(bg: Colors.transparent, fg: cs.primary,   border: cs.primary);
    case GButtonVariant.neutral:
      return _VariantStyle(bg: Colors.transparent, fg: cs.onSurface, border: cs.outline);
    case GButtonVariant.ghost:
      return _VariantStyle(bg: Colors.transparent, fg: cs.onSurface);
    case GButtonVariant.danger:
      return _VariantStyle(bg: cs.error,       fg: cs.onError);
    case GButtonVariant.dangerGhost:
      return _VariantStyle(bg: Colors.transparent, fg: cs.error);
  }
}

// ── GButton ───────────────────────────────────────────────────────────────────

class GButton extends StatelessWidget {
  const GButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant  = GButtonVariant.primary,
    this.size     = GButtonSize.md,
    this.leading,
    this.trailing,
    this.loading  = false,
    this.expand   = false,
  });

  final String         label;
  final VoidCallback?  onPressed;
  final GButtonVariant variant;
  final GButtonSize    size;
  final Widget?        leading;
  final Widget?        trailing;
  final bool           loading;
  final bool           expand;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final sizing  = _GSizing.fromSize(size);
    final vs      = _resolveStyle(variant, cs);
    final enabled = onPressed != null && !loading;

    final isFilled = vs.bg != Colors.transparent;

    final disabledBg     = isFilled ? cs.onSurface.withValues(alpha: 0.12) : Colors.transparent;
    final disabledFg     = cs.onSurface.withValues(alpha: 0.38);
    final disabledBorder = vs.hasBorder ? cs.onSurface.withValues(alpha: 0.12) : null;

    final overlayColor = isFilled
        ? cs.onPrimary.withValues(alpha: 0.08)
        : vs.fg.withValues(alpha: 0.06);

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.disabled) ? disabledBg : vs.bg),
      foregroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.disabled) ? disabledFg : vs.fg),
      overlayColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)
              ? overlayColor
              : Colors.transparent),
      side: vs.hasBorder
          ? WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? disabledBorder!
                  : vs.border!,
            ))
          : null,
      shape:           WidgetStatePropertyAll(GTokens.squareBorder),
      padding:         WidgetStatePropertyAll(sizing.padding(hasBorder: vs.hasBorder)),
      textStyle:       WidgetStatePropertyAll(sizing.textStyle),
      fixedSize:       WidgetStatePropertyAll(Size.fromHeight(sizing.height)),
      tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
      visualDensity:   VisualDensity.compact,
      elevation:       const WidgetStatePropertyAll(0),
      shadowColor:     const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    Widget child;
    if (loading) {
      child = SizedBox(
        width:  sizing.iconSize,
        height: sizing.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: vs.fg,
        ),
      );
    } else if (leading != null || trailing != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            IconTheme(data: IconThemeData(size: sizing.iconSize, color: vs.fg), child: leading!),
            const SizedBox(width: GTokens.componentIconGap),
          ],
          Text(label),
          if (trailing != null) ...[
            const SizedBox(width: GTokens.componentIconGap),
            IconTheme(data: IconThemeData(size: sizing.iconSize, color: vs.fg), child: trailing!),
          ],
        ],
      );
    } else {
      child = Text(label);
    }

    Widget button = TextButton(
      onPressed: enabled ? onPressed : null,
      style:     style,
      child:     child,
    );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

// ── GIconButton ───────────────────────────────────────────────────────────────

class GIconButton extends StatelessWidget {
  const GIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant  = GButtonVariant.neutral,
    this.size     = GButtonSize.md,
    this.tooltip,
  });

  final Widget         icon;
  final VoidCallback?  onPressed;
  final GButtonVariant variant;
  final GButtonSize    size;
  final String?        tooltip;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final sizing = _GSizing.fromSize(size);
    final vs     = _resolveStyle(variant, cs);
    final enabled = onPressed != null;

    final isFilled = vs.bg != Colors.transparent;
    final disabledBg = isFilled ? cs.onSurface.withValues(alpha: 0.12) : Colors.transparent;
    final disabledFg = cs.onSurface.withValues(alpha: 0.38);
    final overlayColor = isFilled
        ? cs.onPrimary.withValues(alpha: 0.08)
        : vs.fg.withValues(alpha: 0.06);

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.disabled) ? disabledBg : vs.bg),
      foregroundColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.disabled) ? disabledFg : vs.fg),
      overlayColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)
              ? overlayColor
              : Colors.transparent),
      side: vs.hasBorder
          ? WidgetStateProperty.all(BorderSide(color: vs.border!))
          : null,
      shape:           WidgetStatePropertyAll(GTokens.squareBorder),
      fixedSize:       WidgetStatePropertyAll(Size.square(sizing.height)),
      padding:         const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
      visualDensity:   VisualDensity.compact,
      elevation:       const WidgetStatePropertyAll(0),
      shadowColor:     const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    Widget button = TextButton(
      onPressed: enabled ? onPressed : null,
      style:     style,
      child: IconTheme(
        data: IconThemeData(size: sizing.iconSize, color: vs.fg),
        child: icon,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
