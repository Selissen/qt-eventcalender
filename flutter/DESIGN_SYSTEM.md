# G Design System — Implementation Spec

This file instructs Claude Code to scaffold a custom Flutter design system on top of Material 3.
Run this from the root of a Flutter project. Replace every occurrence of `G` / `g_` / `GTokens` etc.
with your actual prefix if needed — search-replace is safe, nothing is hardcoded outside this layer.

---

## What to build

Create the directory `lib/design_system/` and populate it with the files listed below,
**exactly as specified**. Do not skip files, do not merge files, do not alter the public API
surface unless a `TODO` comment explicitly permits it.

After writing all files, verify the project still compiles with `flutter analyze`.

---

## File tree

```
lib/design_system/
  design_system.dart               ← single barrel export
  tokens/
    g_tokens.dart                  ← raw values, no Flutter context needed
  theme/
    g_theme.dart                   ← ThemeData builder (light + dark)
    g_theme_extension.dart         ← custom ThemeExtension for extra tokens
  components/
    g_button.dart                  ← GButton + GIconButton
    g_card.dart                    ← GCard + GCardHeader + GCardFooter
    g_text_field.dart              ← GTextField (single-line)
  examples/
    g_kitchen_sink.dart            ← dev-only verification screen
```

---

## Design constraints — apply everywhere, no exceptions

- **Zero rounding.** `BorderRadius.zero` on every component. No pill shapes, no card radius.
- **No surface tint.** Set `surfaceTintColor: Colors.transparent` on every Material surface.
- **No floating labels.** `GTextField` renders its label as a `Text` widget above the field.
- **Component heights are exact.** Buttons and inputs use a shared sizing system that produces
  pixel-accurate heights via calculated vertical padding. See the height math section below.
- **No hardcoded values in components.** All colours, spacing, radii, and font sizes must
  come from `GTokens`, `Theme.of(context).colorScheme`, or `GThemeExtension.of(context)`.

---

## Height math (critical — read before writing any interactive component)

All interactive controls (buttons, inputs, chips, selects) share three height tiers:

| Tier | Height | Use |
|------|--------|-----|
| sm   | 28px   | Dense toolbars, table rows, inline actions |
| md   | 32px   | Default — the design spec target |
| lg   | 40px   | Hero CTAs, prominent standalone actions |

The height is achieved by forcing `TextStyle(height: 1.0)` on the label/input text
(so Flutter measures exactly `fontSize` px of line height, no leading) and then
computing vertical padding as:

```
vPad = (targetHeight - fontSize - borderPx) / 2

where borderPx = 2  for bordered variants (outlined buttons, all inputs)
      borderPx = 0  for borderless variants (filled buttons, ghost)
```

Per-tier font sizes: sm → 12, md → 13, lg → 14.

**This formula must be used in every interactive component.** Do not use fixed padding values
that happen to look right — they will drift when font size changes.

---

## File 1 — `lib/design_system/tokens/g_tokens.dart`

```dart
import 'package:flutter/material.dart';

abstract final class GTokens {
  // Shape
  static const BorderRadius radiusNone = BorderRadius.zero;
  static const RoundedRectangleBorder squareBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  // Spacing (4pt base grid)
  static const double space0  = 0;
  static const double space1  = 4;
  static const double space2  = 8;
  static const double space3  = 12;
  static const double space4  = 16;
  static const double space5  = 20;
  static const double space6  = 24;
  static const double space8  = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // Component heights
  static const double componentHeightSm = 28;
  static const double componentHeightMd = 32;
  static const double componentHeightLg = 40;

  // Horizontal padding per tier
  static const double componentPaddingSmH = 10;
  static const double componentPaddingMdH = 12;
  static const double componentPaddingLgH = 16;

  // Icon sizes per tier
  static const double componentIconSm  = 13;
  static const double componentIconMd  = 14;
  static const double componentIconLg  = 16;
  static const double componentIconGap = 6;

  // Elevation
  static const double elevationNone = 0;
  static const double elevationLow  = 1;
  static const double elevationMid  = 3;
  static const double elevationHigh = 6;

  // Palette — ink scale (neutral)
  static const Color ink900  = Color(0xFF0D0D0D);
  static const Color ink800  = Color(0xFF1A1A1A);
  static const Color ink700  = Color(0xFF2E2E2E);
  static const Color ink600  = Color(0xFF444444);
  static const Color ink500  = Color(0xFF6B6B6B);
  static const Color ink400  = Color(0xFF939393);
  static const Color ink300  = Color(0xFFBBBBBB);
  static const Color ink200  = Color(0xFFDDDDDD);
  static const Color ink100  = Color(0xFFF2F2F2);
  static const Color ink50   = Color(0xFFF9F9F9);
  static const Color inkWhite = Color(0xFFFFFFFF);

  // Palette — accent (TODO: replace with brand colour)
  static const Color accent600 = Color(0xFF1A56FF);
  static const Color accent500 = Color(0xFF3D6FFF);
  static const Color accent400 = Color(0xFF6690FF);
  static const Color accent200 = Color(0xFFBACAFF);
  static const Color accent100 = Color(0xFFE8EDFF);

  // Palette — semantic states
  static const Color success600 = Color(0xFF1A7A4A);
  static const Color success100 = Color(0xFFD6F0E3);
  static const Color warning600 = Color(0xFFA85C00);
  static const Color warning100 = Color(0xFFFFF0D6);
  static const Color error600   = Color(0xFFC0392B);
  static const Color error100   = Color(0xFFFDE8E6);

  // Typography (TODO: replace fontFamily with brand typeface)
  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge   = TextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12);
  static const TextStyle displayMedium  = TextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w400, height: 1.16);
  static const TextStyle displaySmall   = TextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w400, height: 1.22);
  static const TextStyle headlineLarge  = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w600, height: 1.25);
  static const TextStyle headlineMedium = TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w600, height: 1.29);
  static const TextStyle headlineSmall  = TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, height: 1.33);
  static const TextStyle titleLarge     = TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w500, height: 1.27);
  static const TextStyle titleMedium    = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.50);
  static const TextStyle titleSmall     = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,  height: 1.43);
  static const TextStyle labelLarge     = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,  height: 1.43);
  static const TextStyle labelMedium    = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,  height: 1.33);
  static const TextStyle labelSmall     = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,  height: 1.45);
  static const TextStyle bodyLarge      = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5,  height: 1.50);
  static const TextStyle bodyMedium     = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43);
  static const TextStyle bodySmall      = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,  height: 1.33);
}
```

---

## File 2 — `lib/design_system/theme/g_theme_extension.dart`

```dart
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
```

---

## File 3 — `lib/design_system/theme/g_theme.dart`

Build `ThemeData` for light and dark. Every component theme must:
- Set `shape: GTokens.squareBorder`
- Set `surfaceTintColor: Colors.transparent` where applicable
- Use `GTokens` elevation constants, never raw doubles

```dart
import 'package:flutter/material.dart';
import '../tokens/g_tokens.dart';
import 'g_theme_extension.dart';

abstract final class GTheme {
  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark()  => _build(brightness: Brightness.dark);

  static ColorScheme _lightColorScheme() => const ColorScheme(
    brightness:           Brightness.light,
    primary:              GTokens.accent600,
    onPrimary:            GTokens.inkWhite,
    primaryContainer:     GTokens.accent100,
    onPrimaryContainer:   GTokens.accent600,
    secondary:            GTokens.ink700,
    onSecondary:          GTokens.inkWhite,
    secondaryContainer:   GTokens.ink100,
    onSecondaryContainer: GTokens.ink700,
    tertiary:             GTokens.ink500,
    onTertiary:           GTokens.inkWhite,
    tertiaryContainer:    GTokens.ink100,
    onTertiaryContainer:  GTokens.ink700,
    error:                GTokens.error600,
    onError:              GTokens.inkWhite,
    errorContainer:       GTokens.error100,
    onErrorContainer:     GTokens.error600,
    surface:              GTokens.inkWhite,
    onSurface:            GTokens.ink900,
    surfaceVariant:       GTokens.ink100,
    onSurfaceVariant:     GTokens.ink600,
    outline:              GTokens.ink300,
    outlineVariant:       GTokens.ink200,
    inverseSurface:       GTokens.ink800,
    onInverseSurface:     GTokens.ink50,
    inversePrimary:       GTokens.accent400,
    shadow:               GTokens.ink900,
    scrim:                GTokens.ink900,
    surfaceTint:          GTokens.accent600,
  );

  static ColorScheme _darkColorScheme() => const ColorScheme(
    brightness:           Brightness.dark,
    primary:              GTokens.accent400,
    onPrimary:            GTokens.ink900,
    primaryContainer:     GTokens.accent600,
    onPrimaryContainer:   GTokens.accent100,
    secondary:            GTokens.ink200,
    onSecondary:          GTokens.ink900,
    secondaryContainer:   GTokens.ink700,
    onSecondaryContainer: GTokens.ink200,
    tertiary:             GTokens.ink400,
    onTertiary:           GTokens.ink900,
    tertiaryContainer:    GTokens.ink700,
    onTertiaryContainer:  GTokens.ink200,
    error:                GTokens.error600,
    onError:              GTokens.inkWhite,
    errorContainer:       Color(0xFF5C1A14),
    onErrorContainer:     GTokens.error100,
    surface:              GTokens.ink900,
    onSurface:            GTokens.ink50,
    surfaceVariant:       GTokens.ink800,
    onSurfaceVariant:     GTokens.ink300,
    outline:              GTokens.ink600,
    outlineVariant:       GTokens.ink700,
    inverseSurface:       GTokens.ink100,
    onInverseSurface:     GTokens.ink800,
    inversePrimary:       GTokens.accent600,
    shadow:               GTokens.ink900,
    scrim:                GTokens.ink900,
    surfaceTint:          GTokens.accent400,
  );

  static TextTheme _textTheme(ColorScheme cs) => TextTheme(
    displayLarge:   GTokens.displayLarge.copyWith(color: cs.onSurface),
    displayMedium:  GTokens.displayMedium.copyWith(color: cs.onSurface),
    displaySmall:   GTokens.displaySmall.copyWith(color: cs.onSurface),
    headlineLarge:  GTokens.headlineLarge.copyWith(color: cs.onSurface),
    headlineMedium: GTokens.headlineMedium.copyWith(color: cs.onSurface),
    headlineSmall:  GTokens.headlineSmall.copyWith(color: cs.onSurface),
    titleLarge:     GTokens.titleLarge.copyWith(color: cs.onSurface),
    titleMedium:    GTokens.titleMedium.copyWith(color: cs.onSurface),
    titleSmall:     GTokens.titleSmall.copyWith(color: cs.onSurface),
    labelLarge:     GTokens.labelLarge.copyWith(color: cs.onSurface),
    labelMedium:    GTokens.labelMedium.copyWith(color: cs.onSurface),
    labelSmall:     GTokens.labelSmall.copyWith(color: cs.onSurface),
    bodyLarge:      GTokens.bodyLarge.copyWith(color: cs.onSurface),
    bodyMedium:     GTokens.bodyMedium.copyWith(color: cs.onSurface),
    bodySmall:      GTokens.bodySmall.copyWith(color: cs.onSurface),
  );

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final cs  = isDark ? _darkColorScheme() : _lightColorScheme();
    final tt  = _textTheme(cs);
    final ext = isDark ? GThemeExtension.dark : GThemeExtension.light;

    return ThemeData(
      useMaterial3:           true,
      brightness:             brightness,
      colorScheme:            cs,
      textTheme:              tt,
      extensions:             [ext],
      scaffoldBackgroundColor: cs.surface,

      appBarTheme: AppBarTheme(
        backgroundColor:        cs.surface,
        foregroundColor:        cs.onSurface,
        elevation:              GTokens.elevationNone,
        scrolledUnderElevation: GTokens.elevationLow,
        titleTextStyle:         tt.titleLarge,
        centerTitle:            false,
        shape:                  GTokens.squareBorder,
      ),

      cardTheme: CardTheme(
        elevation:       GTokens.elevationNone,
        shape:           GTokens.squareBorder,
        color:           cs.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior:    Clip.antiAlias,
        margin:          EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:     GTokens.squareBorder,
          textStyle: tt.labelLarge,
          padding:   const EdgeInsets.symmetric(horizontal: GTokens.space4, vertical: GTokens.space3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape:     GTokens.squareBorder,
          textStyle: tt.labelLarge,
          padding:   const EdgeInsets.symmetric(horizontal: GTokens.space4, vertical: GTokens.space3),
          side:      BorderSide(color: cs.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape:     GTokens.squareBorder,
          textStyle: tt.labelLarge,
          padding:   const EdgeInsets.symmetric(horizontal: GTokens.space3, vertical: GTokens.space2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape:     GTokens.squareBorder,
          textStyle: tt.labelLarge,
          elevation: GTokens.elevationLow,
          padding:   const EdgeInsets.symmetric(horizontal: GTokens.space4, vertical: GTokens.space3),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: GTokens.squareBorder),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   cs.surfaceVariant.withOpacity(0.5),
        border:           OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.outline)),
        enabledBorder:    OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.outline)),
        focusedBorder:    OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder:      OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.error, width: 2)),
        labelStyle:    tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        hintStyle:     tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: GTokens.space4, vertical: GTokens.space3),
      ),

      chipTheme: ChipThemeData(
        shape:          GTokens.squareBorder,
        elevation:      GTokens.elevationNone,
        pressElevation: GTokens.elevationNone,
        padding:        const EdgeInsets.symmetric(horizontal: GTokens.space3, vertical: GTokens.space1),
        labelStyle:     tt.labelMedium,
      ),

      dialogTheme: DialogTheme(
        shape:            GTokens.squareBorder,
        elevation:        GTokens.elevationHigh,
        backgroundColor:  cs.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:   tt.titleLarge,
        contentTextStyle: tt.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape:        GTokens.squareBorder,
        elevation:    GTokens.elevationMid,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
      ),

      snackBarTheme: SnackBarThemeData(
        shape:            GTokens.squareBorder,
        elevation:        GTokens.elevationMid,
        behavior:         SnackBarBehavior.floating,
        backgroundColor:  cs.inverseSurface,
        contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
      ),

      popupMenuTheme: PopupMenuThemeData(
        shape:     GTokens.squareBorder,
        elevation: GTokens.elevationMid,
        color:     cs.surface,
        textStyle: tt.bodyMedium,
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          shape:           WidgetStatePropertyAll(GTokens.squareBorder),
          elevation:       const WidgetStatePropertyAll(GTokens.elevationMid),
          backgroundColor: WidgetStatePropertyAll(cs.surface),
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border:       const OutlineInputBorder(borderRadius: BorderRadius.zero),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.primary, width: 2)),
        ),
        menuStyle: MenuStyle(shape: WidgetStatePropertyAll(GTokens.squareBorder)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation:      GTokens.elevationNone,
        labelTextStyle: WidgetStateProperty.all(tt.labelMedium),
        indicatorShape: GTokens.squareBorder,
        indicatorColor: cs.primaryContainer,
      ),

      navigationRailTheme: NavigationRailThemeData(
        elevation:                GTokens.elevationNone,
        indicatorShape:           GTokens.squareBorder,
        indicatorColor:           cs.primaryContainer,
        labelType:                NavigationRailLabelType.all,
        selectedLabelTextStyle:   tt.labelMedium?.copyWith(color: cs.primary),
        unselectedLabelTextStyle: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
      ),

      tabBarTheme: TabBarTheme(
        indicator:            UnderlineTabIndicator(borderSide: BorderSide(color: cs.primary, width: 2)),
        labelStyle:           tt.labelLarge,
        unselectedLabelStyle: tt.labelMedium,
        labelColor:           cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        overlayColor:         WidgetStateProperty.all(Colors.transparent),
      ),

      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        shape:             GTokens.squareBorder,
        contentPadding:    const EdgeInsets.symmetric(horizontal: GTokens.space4),
        titleTextStyle:    tt.bodyLarge,
        subtitleTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: BorderRadius.zero),
        textStyle:  tt.bodySmall?.copyWith(color: cs.onInverseSurface),
        padding:    const EdgeInsets.symmetric(horizontal: GTokens.space3, vertical: GTokens.space2),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:              cs.primary,
        linearTrackColor:   cs.surfaceVariant,
        circularTrackColor: cs.surfaceVariant,
        linearMinHeight:    4,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.surfaceVariant),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.transparent : cs.outline),
      ),

      checkboxTheme: CheckboxThemeData(
        shape:     const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(cs.onPrimary),
        side:       BorderSide(color: cs.outline, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant),
      ),

      sliderTheme: SliderThemeData(
        thumbShape:         const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight:        4,
        activeTrackColor:   cs.primary,
        inactiveTrackColor: cs.surfaceVariant,
        thumbColor:         cs.primary,
        overlayColor:       cs.primary.withOpacity(0.12),
      ),
    );
  }
}
```

---

## File 4 — `lib/design_system/components/g_button.dart`

Implement `GButton` and `GIconButton`.

### Enums

```dart
enum GButtonVariant { primary, secondary, neutral, ghost, danger, dangerGhost }
enum GButtonSize    { sm, md, lg }
```

### Sizing helper `_GSizing`

Internal class. Maps `GButtonSize` → target height, horizontal padding, icon size, font size.
Exposes `padding({required bool hasBorder})` that applies the height formula.
Exposes `TextStyle get textStyle` with `height: 1.0`.

```
heights:    sm=28, md=32, lg=40
hPad:       sm=10, md=12, lg=16
iconSizes:  sm=13, md=14, lg=16
fontSizes:  sm=12, md=13, lg=14
```

### Variant colours `_VariantStyle` + `_resolveStyle`

Pure function `_VariantStyle _resolveStyle(GButtonVariant, ColorScheme)`.

| Variant | bg | fg | border |
|---|---|---|---|
| primary | cs.primary | cs.onPrimary | none |
| secondary | transparent | cs.primary | BorderSide(cs.primary) |
| neutral | transparent | cs.onSurface | BorderSide(cs.outline) |
| ghost | transparent | cs.onSurface | none |
| danger | cs.error | cs.onError | none |
| dangerGhost | transparent | cs.error | none |

Disabled bg: `cs.onSurface.withOpacity(0.12)` for filled, `transparent` for others.
Disabled fg: `cs.onSurface.withOpacity(0.38)` for all.
Disabled border (secondary/neutral): `cs.onSurface.withOpacity(0.12)`.
Overlay: `fg.withOpacity(0.06)` for bordered/ghost; `cs.onPrimary.withOpacity(0.08)` for filled.

### `GButton` widget

- Wraps `TextButton` for all variants (unified styling surface).
- Uses `ButtonStyle` with `fixedSize: Size.fromHeight(targetHeight)`.
- Also set `tapTargetSize: MaterialTapTargetSize.shrinkWrap` and `visualDensity: VisualDensity.compact`.
- `loading: true` shows a `CircularProgressIndicator` (strokeWidth 1.5, sized to iconSize) and disables press.
- `expand: true` wraps in `SizedBox(width: double.infinity)`.
- `leading`/`trailing` widgets render with a `GTokens.componentIconGap` gap.

### `GIconButton` widget

- Square button: `fixedSize: Size.square(targetHeight)`, `padding: EdgeInsets.zero`.
- Reuses `_resolveStyle` for colours.
- Optional `tooltip` wraps in `Tooltip`.

---

## File 5 — `lib/design_system/components/g_text_field.dart`

Implement `GTextField` as a `StatefulWidget`.

### Key behaviours

- Label renders as `Text(label)` above the field with a `SizedBox(height: GTokens.space1)` gap.
- Field wrapped in `SizedBox(height: _targetHeight)` — never taller.
- Uses `isDense: true` on `InputDecoration`.
- `contentPadding` computed from height formula (borderPx=2 always, since inputs always have a border).
- `TextStyle(height: 1.0)` on the field's style.
- `cursorHeight` set to fontSize.
- Helper text and error text render below the field only when non-null — no reserved space.
- `readOnly: true` → `fillColor: ext.surfaceSubtle`.
- `enabled: false` → `fillColor: cs.onSurface.withOpacity(0.04)`, disabled border.
- `prefix` / `suffix` widgets wrapped in `_FieldAdornment` (constrains to field height, centers child).
- `prefixIconConstraints` / `suffixIconConstraints` set to `BoxConstraints(minWidth: targetHeight, minHeight: targetHeight)`.
- `counterText: ''` to hide the maxLength counter.
- No `labelText` in `InputDecoration` — we handle the label ourselves.

### Named constructor `GTextField.password`

- Sets `obscureText: true` initially.
- State manages a `_obscure` bool.
- Injects a `_PasswordToggle` as suffix when the original `obscureText` was true.
- `_PasswordToggle` renders a `visibility_outlined` / `visibility_off_outlined` icon
  sized to the tier's icon size, padded with `GTokens.space3` horizontally.

### Sizing tables (same as button)

```
heights:  sm=28,  md=32,  lg=40
hPad:     sm=10,  md=12,  lg=16
fontSize: sm=12,  md=13,  lg=14
iconSize: sm=13,  md=14,  lg=16
```

---

## File 6 — `lib/design_system/components/g_card.dart`

Implement `GCard`, `GCardHeader`, `GCardFooter`.

### `GCard`

```dart
enum GCardVariant { outlined, elevated, tonal }
```

| Variant | bg | elevation | border |
|---|---|---|---|
| outlined | cs.surface | 0 | BorderSide(ext.borderDefault) |
| elevated | cs.surface | elevationLow | none |
| tonal | ext.surfaceSubtle | 0 | none |

- Named constructors: `GCard.elevated(...)`, `GCard.tonal(...)`.
- `onTap` wraps content in `InkWell(borderRadius: BorderRadius.zero)`.
- Default padding `EdgeInsets.all(GTokens.space4)` unless overridden.
- Renders: `[header?, Padding(child), footer?]` in a `Column`.
- Uses `Material` (not Flutter's `Card`) so `surfaceTintColor: Colors.transparent` is reliable.

### `GCardHeader`

- Renders title + optional subtitle, leading, trailing.
- Container with `Border(bottom: BorderSide(ext.borderDefault))`.
- Default padding `EdgeInsets.symmetric(horizontal: space4, vertical: space3)`.

### `GCardFooter`

- Renders a `Row` of `actions`.
- Container with `Border(top: BorderSide(ext.borderDefault))`.
- Default padding `EdgeInsets.symmetric(horizontal: space4, vertical: space3)`.
- `alignment` defaults to `MainAxisAlignment.end`.

---

## File 7 — `lib/design_system/examples/g_kitchen_sink.dart`

A `StatefulWidget` named `GKitchenSink` that renders every component in a scrollable `ListView`.

Sections (use a private `_section(String title, Widget content)` helper):

1. **Button variants — md** — `Wrap` of all 6 variants at md size.
2. **Button variants — sm** — same at sm size.
3. **Button variants — lg** — same at lg size.
4. **With icons** — 4 buttons demonstrating `leading`/`trailing` icons.
5. **States** — enabled, disabled, loading (simulated with a 2-second timer), disabled outlined.
6. **Icon buttons** — all 5 variants + all 3 sizes of `GIconButton`.
7. **Vertical alignment** — a `Row` with a `GTextField` + `GButton` + `GIconButton`, repeated for md and sm tiers, to verify height alignment.
8. **Inputs** — email, username with helper, username with error, password, read-only, disabled.
9. **Input sizes** — sm, md, lg labelled fields stacked vertically.

---

## File 8 — `lib/design_system/design_system.dart`

```dart
library design_system;

export 'tokens/g_tokens.dart';
export 'theme/g_theme.dart';
export 'theme/g_theme_extension.dart';
export 'components/g_button.dart';
export 'components/g_card.dart';
export 'components/g_text_field.dart';
// Do not export g_kitchen_sink — it is dev-only.
```

---

## Wiring into the app

After the files are created, update `lib/main.dart` (or wherever `MaterialApp` lives):

```dart
import 'design_system/design_system.dart';

MaterialApp(
  theme:     GTheme.light(),
  darkTheme: GTheme.dark(),
  // themeMode: ThemeMode.system,  ← recommended
  ...
)
```

To verify during development, add a route to `GKitchenSink`:

```dart
import 'design_system/examples/g_kitchen_sink.dart';

// Inside your routes or a dev drawer:
Navigator.push(context, MaterialPageRoute(builder: (_) => const GKitchenSink()));
```

---

## Conventions for future components

When adding new components:

1. Create `lib/design_system/components/g_<name>.dart`.
2. Accept only semantic inputs — no raw `Color` or `double` in the constructor.
3. Resolve all values from `GTokens`, `Theme.of(context).colorScheme`, or `GThemeExtension.of(context)`.
4. For any interactive control that has a height: use the shared height formula, not fixed padding.
5. Export from `design_system.dart`.
6. Add a section to `g_kitchen_sink.dart`.

---

## What this system deliberately does NOT do

- No animation overrides — Flutter's default state-layer animation is kept.
- No custom `InheritedWidget` for theme — `Theme.of(context)` + `GThemeExtension.of(context)` is sufficient.
- No generated token files — tokens are hand-authored Dart constants. If a token pipeline (Style Dictionary, Tokens Studio) is added later, it should output into `g_tokens.dart` only.
