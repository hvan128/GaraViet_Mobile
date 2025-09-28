import 'package:flutter/material.dart';

/// Design Tokens
/// Dựa trên design-tokens.tokens.json từ Figma
class DesignTokens {
  // Base Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Surface Colors
  static const Color surfaceBrand = Color(0xFF006FFD); // primary.blue
  static const Color surfaceInvert = Color(0xFF171717); // gray.900
  static const Color surfacePrimary = Color(0xFFFFFFFF); // white
  static const Color surfaceTertiary = Color(0xFFF5F5F5); // gray.100
  static const Color surfaceSecondary = Color(0xFFFAFAFA); // gray.50

  // Border Colors
  static const Color borderBrandPrimary = Color(0xFF006FFD); // primary.blue
  static const Color borderTertiary = Color(0xFFF5F5F5); // gray.100
  static const Color borderBrandSecondary = Color(0xFFEAF2FF); // primary.blue4
  static const Color borderSecondary = Color(0xFFEAECF0); // gray.200
  static const Color borderPrimary = Color(0xFFD4D4D4); // gray.300

  // Text Colors
  static const Color textPrimary = Color(0xFF171717); // gray.900
  static const Color textBrand = Color(0xFF006FFD); // primary.blue
  static const Color textInvert = Color(0xFFFAFAFA); // gray.50
  static const Color textPlaceholder = Color(0xFFA3A3A3); // gray.400
  static const Color textTertiary = Color(0xFF737373); // gray.500
  static const Color textSecondary = Color(0xFF404040); // gray.700
  static const Color textDisable = Color(0xFFD4D4D4); // gray.300

  // Primary Colors
  static const Color primaryBlue = Color(0xFF006FFD);
  static const Color primaryBlue2 = Color(0xFF2897FF);
  static const Color primaryBlue3 = Color(0xFFB4DBFF);
  static const Color primaryBlue4 = Color(0xFFEAF2FF);

  // Gray Scale
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEAECF0);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFA3A3A3);
  static const Color gray500 = Color(0xFF737373);
  static const Color gray600 = Color(0xFF525252);
  static const Color gray700 = Color(0xFF404040);
  static const Color gray800 = Color(0xFF262626);
  static const Color gray900 = Color(0xFF171717);

  // Secondary Colors
  static const Color secondaryGreen = Color(0xFF6CD185);
  static const Color secondaryYellow = Color(0xFFFFDA00);
  static const Color secondaryOrange = Color(0xFFFC7D5D);

  // Alert Colors
  static const Color alertSuccess = Color(0xFF17B26A);
  static const Color alertWarning = Color(0xFFF79009);
  static const Color alertError = Color(0xFFED544E);

  // Surface Color Map
  static const Map<String, Color> surface = {
    'brand': surfaceBrand,
    'invert': surfaceInvert,
    'primary': surfacePrimary,
    'tertiary': surfaceTertiary,
    'secondary': surfaceSecondary,
  };

  // Border Color Map
  static const Map<String, Color> border = {
    'brandPrimary': borderBrandPrimary,
    'tertiary': borderTertiary,
    'brandSecondary': borderBrandSecondary,
    'secondary': borderSecondary,
    'primary': borderPrimary,
  };

  // Text Color Map
  static const Map<String, Color> text = {
    'primary': textPrimary,
    'brand': textBrand,
    'invert': textInvert,
    'placeholder': textPlaceholder,
    'tertiary': textTertiary,
    'secondary': textSecondary,
    'disable': textDisable,
  };

  // Primary Color Map
  static const Map<String, Color> primary = {
    'blue': primaryBlue,
    'blue2': primaryBlue2,
    'blue3': primaryBlue3,
    'blue4': primaryBlue4,
  };

  // Gray Color Map
  static const Map<String, Color> gray = {
    '50': gray50,
    '100': gray100,
    '200': gray200,
    '300': gray300,
    '400': gray400,
    '500': gray500,
    '600': gray600,
    '700': gray700,
    '800': gray800,
    '900': gray900,
  };

  // Secondary Color Map
  static const Map<String, Color> secondary = {
    'green': secondaryGreen,
    'yellow': secondaryYellow,
    'orange': secondaryOrange,
  };

  // Alert Color Map
  static const Map<String, Color> alerts = {
    'success': alertSuccess,
    'warning': alertWarning,
    'error': alertError,
  };

  // Base Color Map
  static const Map<String, Color> base = {
    'black': black,
    'white': white,
  };

  /// Lấy màu surface theo tên
  static Color getSurfaceColor(String name) {
    return surface[name] ?? surfacePrimary;
  }

  /// Lấy màu border theo tên
  static Color getBorderColor(String name) {
    return border[name] ?? borderPrimary;
  }

  /// Lấy màu text theo tên
  static Color getTextColor(String name) {
    return text[name] ?? textPrimary;
  }

  /// Lấy màu primary theo tên
  static Color getPrimaryColor(String name) {
    return primary[name] ?? primaryBlue;
  }

  /// Lấy màu gray theo tên
  static Color getGrayColor(String name) {
    return gray[name] ?? gray500;
  }

  /// Lấy màu secondary theo tên
  static Color getSecondaryColor(String name) {
    return secondary[name] ?? secondaryGreen;
  }

  /// Lấy màu alert theo tên
  static Color getAlertColor(String name) {
    return alerts[name] ?? alertError;
  }

  /// Lấy màu base theo tên
  static Color getBaseColor(String name) {
    return base[name] ?? white;
  }
}

