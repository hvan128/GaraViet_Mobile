import 'package:flutter/material.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class MyHeader extends StatefulWidget {
  final String title;
  final String? srcLeftIcon;
  final String? srcRightIcon;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;
  final bool showLeftButton;
  final bool showRightButton;
  final double height;
  final Color? backgroundColor;
  final Widget? customTitle;
  final double? leftIconSize;
  final double? rightIconSize;
  final Color? leftIconColor;
  final Color? rightIconColor;

  const MyHeader({
    super.key,
    this.title = "",
    this.srcLeftIcon,
    this.srcRightIcon,
    this.leftIcon,
    this.rightIcon,
    this.onLeftPressed,
    this.onRightPressed,
    this.showLeftButton = true,
    this.showRightButton = false,
    this.height = 65,
    this.backgroundColor = Colors.transparent,
    this.customTitle,
    this.leftIconSize = 24,
    this.rightIconSize = 24,
    this.leftIconColor,
    this.rightIconColor,
  });

  @override
  State<MyHeader> createState() => _HeaderState();
}

class _HeaderState extends State<MyHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Row(
            children: [
              if (widget.showLeftButton) ...[
                GestureDetector(
                  onTap: widget.onLeftPressed ?? () => Navigator.pop(context),
                  child: Container(
                    width: widget.leftIconSize,
                    height: widget.leftIconSize,
                    padding: const EdgeInsets.all(4),
                    child: widget.leftIcon ?? 
                      SvgIcon(
                        svgPath: widget.srcLeftIcon ?? "assets/icons_final/arrow-left.svg",
                        width: widget.leftIconSize,
                        height: widget.leftIconSize,
                        color: widget.leftIconColor,
                      ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Title
              widget.customTitle ?? 
                MyText(
                  text: widget.title,
                  textStyle: 'head',
                  textSize: '16',
                  textColor: 'primary',
                ),
            ],
          ),
          
          // Right side
          if (widget.showRightButton)
            GestureDetector(
              onTap: widget.onRightPressed,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: widget.rightIcon ?? 
                  SvgIcon(
                    svgPath: widget.srcRightIcon ?? "assets/icons_final/close.svg",
                    width: widget.rightIconSize,
                    height: widget.rightIconSize,
                    color: widget.rightIconColor,
                  ),
              ),
            ),
        ],
      ),
    );
  }

}
