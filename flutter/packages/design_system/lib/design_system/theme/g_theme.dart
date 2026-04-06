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
    surfaceContainerHighest: GTokens.ink100,
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
    surfaceContainerHighest: GTokens.ink800,
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
      useMaterial3:            true,
      brightness:              brightness,
      colorScheme:             cs,
      textTheme:               tt,
      extensions:              [ext],
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

      cardTheme: CardThemeData(
        elevation:        GTokens.elevationNone,
        shape:            GTokens.squareBorder,
        color:            cs.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior:     Clip.antiAlias,
        margin:           EdgeInsets.zero,
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
        filled:             true,
        fillColor:          cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border:             OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.outline)),
        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.outline)),
        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: cs.error, width: 2)),
        labelStyle:         tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        hintStyle:          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        contentPadding:     const EdgeInsets.symmetric(horizontal: GTokens.space4, vertical: GTokens.space3),
      ),

      chipTheme: ChipThemeData(
        shape:          GTokens.squareBorder,
        elevation:      GTokens.elevationNone,
        pressElevation: GTokens.elevationNone,
        padding:        const EdgeInsets.symmetric(horizontal: GTokens.space3, vertical: GTokens.space1),
        labelStyle:     tt.labelMedium,
      ),

      dialogTheme: DialogThemeData(
        shape:            GTokens.squareBorder,
        elevation:        GTokens.elevationHigh,
        backgroundColor:  cs.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:   tt.titleLarge,
        contentTextStyle: tt.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape:          GTokens.squareBorder,
        elevation:      GTokens.elevationMid,
        showDragHandle: false,
        clipBehavior:   Clip.antiAlias,
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
          border:        const OutlineInputBorder(borderRadius: BorderRadius.zero),
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

      tabBarTheme: TabBarThemeData(
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
        linearTrackColor:   cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
        linearMinHeight:    4,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
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
        inactiveTrackColor: cs.surfaceContainerHighest,
        thumbColor:         cs.primary,
        overlayColor:       cs.primary.withValues(alpha: 0.12),
      ),
    );
  }
}
