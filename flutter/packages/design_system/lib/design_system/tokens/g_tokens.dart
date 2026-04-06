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
  static const Color ink900   = Color(0xFF0D0D0D);
  static const Color ink800   = Color(0xFF1A1A1A);
  static const Color ink700   = Color(0xFF2E2E2E);
  static const Color ink600   = Color(0xFF444444);
  static const Color ink500   = Color(0xFF6B6B6B);
  static const Color ink400   = Color(0xFF939393);
  static const Color ink300   = Color(0xFFBBBBBB);
  static const Color ink200   = Color(0xFFDDDDDD);
  static const Color ink100   = Color(0xFFF2F2F2);
  static const Color ink50    = Color(0xFFF9F9F9);
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
