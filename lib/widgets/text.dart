import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';

class MyText extends StatelessWidget {
  final String text;
  final String? textStyle; // body, label, title, head
  final String? textSize; // 12, 14, 16, 18, 24, 32
  final String? textColor; // primary, brand, invert, placeholder, tertiary, secondary, disable
  final Color? color; // Custom color override
  final TextDecoration decoration;
  final Color? decorationColor;
  final TextAlign? textAlign;
  final double? lineHeight;
  final int? maxLines;
  final TextOverflow? overflow;

  const MyText({
    super.key,
    required this.text,
    this.textStyle = 'body',
    this.textSize = '16',
    this.textColor = 'primary',
    this.color,
    this.decoration = TextDecoration.none,
    this.decorationColor,
    this.textAlign,
    this.lineHeight,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // Get base style from typography
    TextStyle? baseStyle;
    if (textStyle != null && textSize != null) {
      baseStyle = MyTypography.getStyle(textStyle!, textSize!);
    }

    // Get color
    Color textColorValue;
    if (color != null) {
      textColorValue = color!;
    } else if (textColor != null) {
      textColorValue = MyColors.text[textColor!]!;
    } else {
      textColorValue = MyColors.text['primary']!;
    }

    return Text(
      text,
      textAlign: textAlign,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
      overflow: overflow,
      style: (baseStyle ?? const TextStyle()).copyWith(
        color: textColorValue,
        decoration: decoration,
        decorationColor: decorationColor,
        height: lineHeight,
      ),
    );
  }
}
