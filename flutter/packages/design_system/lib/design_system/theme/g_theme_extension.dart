import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../tokens/g_tokens.dart';

@immutable
class GThemeExtension extends ThemeExtension<GThemeExtension> {
  const GThemeExtension({
    required this.surfaceSubtle,
    required this.surfaceStrong,
    required this.borderDefault,
    required this.borderStrong,
    required this.contentSecondary,
    required this.contentDisabled,
    required this.spacingPage,
    required this.spacingSection,
    required this.spacingComponent,
  });

  final Color  surfaceSubtle;
  final Color  surfaceStrong;
  final Color  borderDefault;
  final Color  borderStrong;
  final Color  contentSecondary;
  final Color  contentDisabled;
  final double spacingPage;
  final double spacingSection;
  final double spacingComponent;

  static GThemeExtension of(BuildContext context) =>
      Theme.of(context).extension<GThemeExtension>()!;

  static const GThemeExtension light = GThemeExtension(
    surfaceSubtle:    GTokens.ink50,
    surfaceStrong:    GTokens.ink100,
    borderDefault:    GTokens.ink200,
    borderStrong:     GTokens.ink400,
    contentSecondary: GTokens.ink500,
    contentDisabled:  GTokens.ink300,
    spacingPage:      GTokens.space6,
    spacingSection:   GTokens.space8,
    spacingComponent: GTokens.space4,
  );

  static const GThemeExtension dark = GThemeExtension(
    surfaceSubtle:    GTokens.ink800,
    surfaceStrong:    GTokens.ink700,
    borderDefault:    GTokens.ink600,
    borderStrong:     GTokens.ink400,
    contentSecondary: GTokens.ink400,
    contentDisabled:  GTokens.ink600,
    spacingPage:      GTokens.space6,
    spacingSection:   GTokens.space8,
    spacingComponent: GTokens.space4,
  );

  @override
  GThemeExtension copyWith({
    Color?  surfaceSubtle,
    Color?  surfaceStrong,
    Color?  borderDefault,
    Color?  borderStrong,
    Color?  contentSecondary,
    Color?  contentDisabled,
    double? spacingPage,
    double? spacingSection,
    double? spacingComponent,
  }) => GThemeExtension(
    surfaceSubtle:    surfaceSubtle    ?? this.surfaceSubtle,
    surfaceStrong:    surfaceStrong    ?? this.surfaceStrong,
    borderDefault:    borderDefault    ?? this.borderDefault,
    borderStrong:     borderStrong     ?? this.borderStrong,
    contentSecondary: contentSecondary ?? this.contentSecondary,
    contentDisabled:  contentDisabled  ?? this.contentDisabled,
    spacingPage:      spacingPage      ?? this.spacingPage,
    spacingSection:   spacingSection   ?? this.spacingSection,
    spacingComponent: spacingComponent ?? this.spacingComponent,
  );

  @override
  GThemeExtension lerp(GThemeExtension? other, double t) {
    if (other == null) return this;
    return GThemeExtension(
      surfaceSubtle:    Color.lerp(surfaceSubtle,    other.surfaceSubtle,    t)!,
      surfaceStrong:    Color.lerp(surfaceStrong,    other.surfaceStrong,    t)!,
      borderDefault:    Color.lerp(borderDefault,    other.borderDefault,    t)!,
      borderStrong:     Color.lerp(borderStrong,     other.borderStrong,     t)!,
      contentSecondary: Color.lerp(contentSecondary, other.contentSecondary, t)!,
      contentDisabled:  Color.lerp(contentDisabled,  other.contentDisabled,  t)!,
      spacingPage:      lerpDouble(spacingPage,      other.spacingPage,      t)!,
      spacingSection:   lerpDouble(spacingSection,   other.spacingSection,   t)!,
      spacingComponent: lerpDouble(spacingComponent, other.spacingComponent, t)!,
    );
  }
}
