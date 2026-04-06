import 'package:flutter/material.dart';
import '../tokens/g_tokens.dart';
import '../theme/g_theme_extension.dart';

enum GCardVariant { outlined, elevated, tonal }

// ── GCardHeader ───────────────────────────────────────────────────────────────

class GCardHeader extends StatelessWidget {
  const GCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding,
  });

  final String  title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ext = GThemeExtension.of(context);
    final tt  = Theme.of(context).textTheme;

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: GTokens.space4,
            vertical:   GTokens.space3,
          ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ext.borderDefault)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: GTokens.space3),
          ],
          Expanded(
            child: Column(
              mainAxisSize:     MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleSmall),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: GTokens.space3),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── GCardFooter ───────────────────────────────────────────────────────────────

class GCardFooter extends StatelessWidget {
  const GCardFooter({
    super.key,
    required this.actions,
    this.alignment = MainAxisAlignment.end,
    this.padding,
  });

  final List<Widget>   actions;
  final MainAxisAlignment alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ext = GThemeExtension.of(context);

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: GTokens.space4,
            vertical:   GTokens.space3,
          ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ext.borderDefault)),
      ),
      child: Row(
        mainAxisAlignment: alignment,
        children: actions,
      ),
    );
  }
}

// ── GCard ─────────────────────────────────────────────────────────────────────

class GCard extends StatelessWidget {
  const GCard({
    super.key,
    required this.child,
    this.variant = GCardVariant.outlined,
    this.header,
    this.footer,
    this.padding,
    this.onTap,
  });

  const GCard.elevated({
    Key? key,
    required Widget child,
    GCardHeader? header,
    GCardFooter? footer,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) : this(
          key:     key,
          child:   child,
          variant: GCardVariant.elevated,
          header:  header,
          footer:  footer,
          padding: padding,
          onTap:   onTap,
        );

  const GCard.tonal({
    Key? key,
    required Widget child,
    GCardHeader? header,
    GCardFooter? footer,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) : this(
          key:     key,
          child:   child,
          variant: GCardVariant.tonal,
          header:  header,
          footer:  footer,
          padding: padding,
          onTap:   onTap,
        );

  final Widget              child;
  final GCardVariant        variant;
  final GCardHeader?        header;
  final GCardFooter?        footer;
  final EdgeInsetsGeometry? padding;
  final VoidCallback?       onTap;

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final ext = GThemeExtension.of(context);

    Color bg;
    double elevation;
    BoxBorder? border;

    switch (variant) {
      case GCardVariant.outlined:
        bg        = cs.surface;
        elevation = GTokens.elevationNone;
        border    = Border.all(color: ext.borderDefault);
      case GCardVariant.elevated:
        bg        = cs.surface;
        elevation = GTokens.elevationLow;
        border    = null;
      case GCardVariant.tonal:
        bg        = ext.surfaceSubtle;
        elevation = GTokens.elevationNone;
        border    = null;
    }

    Widget content = Column(
      mainAxisSize:     MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        Padding(
          padding: padding ?? const EdgeInsets.all(GTokens.space4),
          child:   child,
        ),
        if (footer != null) footer!,
      ],
    );

    if (onTap != null) {
      content = InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.zero,
        child:        content,
      );
    }

    return Material(
      color:            bg,
      elevation:        elevation,
      surfaceTintColor: Colors.transparent,
      shape:            border != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: (border as Border).top, // use top as representative side
            )
          : GTokens.squareBorder,
      clipBehavior: Clip.antiAlias,
      child: border != null
          ? DecoratedBox(
              decoration: BoxDecoration(border: border),
              child: content,
            )
          : content,
    );
  }
}
