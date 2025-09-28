import 'package:flutter/material.dart';

class MyTypography {
  // Typography Styles based on design tokens
  static final typography = {
    'body': {
      '12': const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'Manrope',
        letterSpacing: -0.12,
        height: 1.5, // 18/12
      ),
      '14': const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: 'Manrope',
        letterSpacing: -0.14,
        height: 1.43, // 20/14
      ),
      '16': const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: 'Manrope',
        letterSpacing: -0.16,
        height: 1.5, // 24/16
      ),
      '18': const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        fontFamily: 'Manrope',
        letterSpacing: -0.36,
        height: 1.56, // 28/18
      ),
    },
    'label': {
      '12': const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Manrope',
        letterSpacing: -0.12,
        height: 1.5, // 18/12
      ),
      '14': const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Manrope',
        letterSpacing: -0.14,
        height: 1.43, // 20/14
      ),
      '16': const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Manrope',
        letterSpacing: -0.32,
        height: 1.5, // 24/16
      ),
      '18': const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        fontFamily: 'Manrope',
        letterSpacing: -0.36,
        height: 1.56, // 28/18
      ),
    },
    'title': {
      '12': const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
        letterSpacing: -0.12,
        height: 1.5, // 18/12
      ),
      '14': const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
        letterSpacing: -0.14,
        height: 1.43, // 20/14
      ),
      '16': const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
        letterSpacing: -0.32,
        height: 1.5, // 24/16
      ),
      '18': const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
        letterSpacing: -0.36,
        height: 1.56, // 28/18
      ),
      '24': const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
        letterSpacing: -0.48,
        height: 1.33, // 32/24
      ),
    },
    'head': {
      '12': const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
        letterSpacing: -0.12,
        height: 1.5, // 18/12
      ),
      '14': const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
        letterSpacing: -0.14,
        height: 1.43, // 20/14
      ),
      '16': const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
        letterSpacing: -0.32,
        height: 1.5, // 24/16
      ),
      '18': const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
        letterSpacing: -0.36,
        height: 1.56, // 28/18
      ),
      '24': const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
        letterSpacing: -0.48,
        height: 1.33, // 32/24
      ),
      '32': const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
        letterSpacing: -0.32,
        height: 1.5, // 48/32
      ),
    },
  };

  // Convenience methods for easy access
  static TextStyle? getStyle(String style, String size) {
    return typography[style]?[size];
  }

  // Predefined style combinations for common use cases
  static final TextStyle heading1 = typography['head']!['32']!;
  static final TextStyle heading2 = typography['head']!['24']!;
  static final TextStyle heading3 = typography['head']!['18']!;
  static final TextStyle heading4 = typography['head']!['16']!;
  static final TextStyle heading5 = typography['head']!['14']!;
  static final TextStyle heading6 = typography['head']!['12']!;
  
  static final TextStyle title1 = typography['title']!['24']!;
  static final TextStyle title2 = typography['title']!['18']!;
  static final TextStyle title3 = typography['title']!['16']!;
  static final TextStyle title4 = typography['title']!['14']!;
  static final TextStyle title5 = typography['title']!['12']!;
  
  static final TextStyle body1 = typography['body']!['18']!;
  static final TextStyle body2 = typography['body']!['16']!;
  static final TextStyle body3 = typography['body']!['14']!;
  static final TextStyle body4 = typography['body']!['12']!;
  
  static final TextStyle label1 = typography['label']!['18']!;
  static final TextStyle label2 = typography['label']!['16']!;
  static final TextStyle label3 = typography['label']!['14']!;
  static final TextStyle label4 = typography['label']!['12']!;
}
