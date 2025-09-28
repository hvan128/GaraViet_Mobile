import 'package:flutter/material.dart';

class MyColors {
  // Primary Colors - Blue
  static final primary = {
    'blue': const Color(0xFF006FFD), // Primary blue
    'blue2': const Color(0xFF2897FF), // Blue 2
    'blue3': const Color(0xFFB4DBFF), // Blue 3
    'blue4': const Color(0xFFEAF2FF), // Blue 4
  };

  // Secondary Colors
  static final secondary = {
    'green': const Color(0xFF6CD185), // Secondary green
    'yellow': const Color(0xFFFFDA00), // Secondary yellow
    'orange': const Color(0xFFFC7D5D), // Secondary orange
  };

  // Gray Scale
  static final gray = {
    '50': const Color(0xFFFAFAFA),
    '100': const Color(0xFFF5F5F5),
    '200': const Color(0xFFEAECF0),
    '300': const Color(0xFFD4D4D4),
    '400': const Color(0xFFA3A3A3),
    '500': const Color(0xFF737373),
    '600': const Color(0xFF525252),
    '700': const Color(0xFF404040),
    '800': const Color(0xFF262626),
    '900': const Color(0xFF171717),
  };

  // Alert Colors
  static final alerts = {
    'success': const Color(0xFF17B26A),
    'warning': const Color(0xFFF79009),
    'error': const Color(0xFFED544E),
  };

  // Text Colors
  static final text = {
    'primary': const Color(0xFF171717), // gray.900
    'brand': const Color(0xFF006FFD), // primary.blue
    'invert': const Color(0xFFFAFAFA), // gray.50
    'placeholder': const Color(0xFFA3A3A3), // gray.400
    'tertiary': const Color(0xFF737373), // gray.500
    'secondary': const Color(0xFF404040), // gray.700
    'disable': const Color(0xFFD4D4D4), // gray.300
    'error': const Color(0xFFED544E), // alerts.error
    'success': const Color(0xFF17B26A), // alerts.success
    'warning': const Color(0xFFF79009), // alerts.warning
  };

  // White and transparency
  static final white = {
    'c900': const Color(0xFFFFFFFF),
  };

  static final whiteOpacity = {
    'c900': const Color.fromRGBO(255, 255, 255, 0.9),
    'c800': const Color.fromRGBO(255, 255, 255, 0.8),
    'c700': const Color.fromRGBO(255, 255, 255, 0.7),
    'c600': const Color.fromRGBO(255, 255, 255, 0.6),
    'c500': const Color.fromRGBO(255, 255, 255, 0.5),
    'c400': const Color.fromRGBO(255, 255, 255, 0.4),
    'c300': const Color.fromRGBO(255, 255, 255, 0.3),
    'c200': const Color.fromRGBO(255, 255, 255, 0.2),
    'c100': const Color.fromRGBO(255, 255, 255, 0.1)
  };

  static const transparent = Colors.transparent;
}
