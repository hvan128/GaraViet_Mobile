import 'package:flutter/material.dart';

/// Widget wrapper để tự động dismiss keyboard khi tap ra ngoài
/// Sử dụng cho tất cả các màn hình có TextField
class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;
  final bool enableScroll;
  final EdgeInsetsGeometry? padding;
  
  const KeyboardDismissWrapper({
    super.key,
    required this.child,
    this.enableScroll = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus tất cả TextField khi tap ra ngoài
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: enableScroll
            ? SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Container(
                  width: double.infinity,
                  padding: padding,
                  child: child,
                ),
              )
            : Container(
                width: double.infinity,
                height: double.infinity,
                padding: padding,
                child: child,
              ),
      ),
    );
  }
}
