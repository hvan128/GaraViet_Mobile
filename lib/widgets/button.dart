import 'package:gara/theme/color.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType buttonType;
  final double? width;
  final double? height;
  final String? startIcon;
  final String? endIcon;
  final Size? sizeStartIcon;
  final Size? sizeEndIcon;
  final String? textStyle;
  final String? textSize;
  final String? textColor;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? colorStartIcon;
  final Color? colorEndIcon;

  const MyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonType = ButtonType.primary,
    this.width,
    this.height,
    this.startIcon,
    this.endIcon,
    this.sizeStartIcon,
    this.sizeEndIcon,
    this.textStyle,
    this.textSize,
    this.textColor,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.colorStartIcon,
    this.colorEndIcon,
  })  : assert(
          (startIcon != null && sizeStartIcon != null) || startIcon == null,
          "Require sizeStartIcon if startIcon is provided",
        ),
        assert(
          (endIcon != null && sizeEndIcon != null) || endIcon == null,
          "Require sizeEndIcon if endIcon is provided",
        );

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? textColorStyle;
    Color? borderColorStyle;

    // Use custom colors if provided, otherwise use buttonType defaults
    if (backgroundColor != null) {
      bgColor = backgroundColor;
    } else {
      switch (buttonType) {
        case ButtonType.primary:
          bgColor = DesignTokens.surfaceBrand;
          break;
        case ButtonType.secondary:
          bgColor = DesignTokens.surfaceSecondary;
          break;
        case ButtonType.yellow:
          bgColor = DesignTokens.secondaryYellow;
          break;
        case ButtonType.disable:
          bgColor = DesignTokens.surfaceTertiary;
          break;
        case ButtonType.delete:
          bgColor = DesignTokens.surfaceInvert;
          break;
        case ButtonType.transparent:
          bgColor = Colors.transparent;
          break;
      }
    }

    if (color != null) {
      textColorStyle = color;
    } else {
      switch (buttonType) {
        case ButtonType.primary:
          textColorStyle = DesignTokens.surfaceTertiary;
          break;
        case ButtonType.secondary:
          textColorStyle = DesignTokens.surfaceBrand;
          break;
        case ButtonType.yellow:
          textColorStyle = DesignTokens.surfaceTertiary;
          break;
        case ButtonType.disable:
          textColorStyle = DesignTokens.textDisable;
          break;
        case ButtonType.delete:
          textColorStyle = DesignTokens.surfaceInvert;
          break;
        case ButtonType.transparent:
          textColorStyle = DesignTokens.surfaceBrand;
          break;
      }
    }
    if (borderColor != null) {
      borderColorStyle = borderColor;
    } else {
      switch (buttonType) {
        case ButtonType.primary:
          borderColorStyle = null;
          break;
        case ButtonType.secondary:
          borderColorStyle = DesignTokens.surfaceBrand;
          break;
        case ButtonType.yellow:
          borderColorStyle = DesignTokens.surfaceTertiary;
          break;
        case ButtonType.disable:
          borderColorStyle = DesignTokens.surfaceTertiary;
          break;
        case ButtonType.delete:
          borderColorStyle = DesignTokens.surfaceInvert;
          break;
        case ButtonType.transparent:
          borderColorStyle = DesignTokens.borderSecondary;
          break;
      }
    }

    

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48,
      child: GestureDetector(
        onTap: buttonType == ButtonType.disable ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: buttonType == ButtonType.disable 
                ? DesignTokens.surfaceTertiary 
                : bgColor,
            borderRadius: BorderRadius.circular(100),
            border: borderColorStyle != null 
                ? Border.all(color: borderColorStyle, width: 1.0)
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (startIcon != null && sizeStartIcon != null)
                  SvgIcon(
                    svgPath: startIcon!,
                    width: sizeStartIcon!.width,
                    height: sizeStartIcon!.height,
                    color: colorStartIcon,
                  ),
                if (startIcon != null && sizeStartIcon != null)
                  SizedBox(width: 4),
                MyText(
                  text: text,
                  textStyle: textStyle ?? 'label',
                  textSize: textSize ?? '16',
                  textColor: textColor,
                  color: color ?? textColorStyle!,
                ),
                if (endIcon != null)
                  SizedBox(width: 4),
                if (endIcon != null)
                  SvgIcon(
                    svgPath: endIcon!,
                    width: sizeEndIcon!.width,
                    height: sizeEndIcon!.height,
                    color: colorEndIcon,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyButtonFeature extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType buttonType;
  final double? width;
  final double? height;
  final String? startIcon;
  final String? endIcon;
  final Size? sizeStartIcon;
  final Size? sizeEndIcon;
  final String? textStyle;
  final String? textSize;
  final String? textColor;
  final Color? color;
  final bool disabled;
  final double? lineHeight;
  final bool isFocused;
  final Color? colorStartIcon;
  final Color? colorEndIcon;

  const MyButtonFeature({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonType = ButtonType.primary,
    this.width,
    this.height,
    this.startIcon,
    this.endIcon,
    this.sizeStartIcon,
    this.sizeEndIcon,
    this.textStyle,
    this.textSize,
    this.textColor,
    this.color,
    this.disabled = false,
    this.lineHeight,
    this.isFocused = false,
    this.colorStartIcon,
    this.colorEndIcon,
  })  : assert(
          (startIcon != null && sizeStartIcon != null) || startIcon == null,
          "Require sizeStartIcon if startIcon is provided",
        ),
        assert(
          (endIcon != null && sizeEndIcon != null) || endIcon == null,
          "Require sizeEndIcon if endIcon is provided",
        );

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? textColorStyle;

    switch (buttonType) {
      case ButtonType.primary:
        bgColor = MyColors.primary['blue']!;
        textColorStyle = MyColors.whiteOpacity['c900']!;
        break;
      case ButtonType.secondary:
        bgColor = MyColors.primary['blue4']!;
        textColorStyle = MyColors.primary['blue']!;
        break;

      case ButtonType.yellow:
        bgColor = MyColors.secondary['yellow']!;
        textColorStyle = MyColors.white['c900'];
        break;

      case ButtonType.disable:
        bgColor = MyColors.gray['100']!;
        textColorStyle = MyColors.gray['400']!;
        break;
      case ButtonType.delete:
        bgColor = MyColors.alerts['error']!;
        textColorStyle = MyColors.alerts['error']!;
        break;
      case ButtonType.transparent:
        bgColor = MyColors.white['c900'];
        textColorStyle = MyColors.gray['900']!;
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: GestureDetector(
        onTap: buttonType == ButtonType.disable ? null : onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            style: isFocused ? BorderStyle.solid : BorderStyle.none,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: bgColor!,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        decoration: BoxDecoration(
          color: disabled ? MyColors.gray['100']! : bgColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            style: isFocused ? BorderStyle.solid : BorderStyle.none,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
            color: MyColors.white['c900']!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (startIcon != null) ...[
              SvgIcon(
                svgPath: startIcon!,
                width: sizeStartIcon!.width,
                height: sizeStartIcon!.height,
                color: colorStartIcon,
              ),
              SizedBox(
                width: 4,
              )
            ],
            MyText(
              text: text,
              textStyle: textStyle ?? 'head',
              textSize: textSize ?? '16',
              textColor: textColor,
              color: color ?? textColorStyle!,
              lineHeight: lineHeight ?? 1.38,
            ),
            if (endIcon != null) ...[
              SizedBox(
                width: 4,
              ),
              SvgIcon(
                svgPath: endIcon!,
                width: sizeEndIcon!.width,
                height: sizeEndIcon!.height,
                color: colorEndIcon,
              )
            ],
          ],
        ),
      ),
    ));
  }
}

enum ButtonType { primary, secondary, disable, delete, transparent, yellow }