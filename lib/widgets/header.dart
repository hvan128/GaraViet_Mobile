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
    this.height = 56,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onLeftPressed ?? () => Navigator.pop(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    child: Center(
                      child: SizedBox(
                        width: widget.leftIconSize,
                        height: widget.leftIconSize,
                        child: widget.leftIcon ??
                            SvgIcon(
                              svgPath: widget.srcLeftIcon ?? "assets/icons_final/arrow-left.svg",
                              width: widget.leftIconSize,
                              height: widget.leftIconSize,
                              color: widget.leftIconColor,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            Builder(
              builder: (context) {
                // Nếu có custom rightIcon và không có onRightPressed,
                // render trực tiếp để widget con tự xử lý tap của nó
                if (widget.rightIcon != null && widget.onRightPressed == null) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: widget.rightIcon!,
                    ),
                  );
                }

                // Ngược lại, dùng GestureDetector để xử lý onRightPressed.
                // Giữ minHeight 44 cho vùng chạm, không ép width/height của widget con
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onRightPressed,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
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
                );
              },
            ),
        ],
      ),
    );
  }

}
