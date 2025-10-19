import 'package:gara/theme/index.dart';
import 'package:gara/widgets/text.dart';
import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String? hintText;
  final bool obscureText;
  final bool hasError; // Added hasError property
  final String? errorText;
  final String? label;
  final double? borderRadius;
  final String? value; // Chỉ dùng khi KHÔNG truyền controller
  final void Function(String)? onChange;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool showLabel;
  final FocusNode? focusNode;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final int? minLines;
  final int? maxLines; // Set >1 để dùng như textarea

  const MyTextField({
    super.key,
    this.hintText,
    required this.obscureText,
    required this.hasError, // Added hasError property
    this.errorText,
    this.label,
    this.borderRadius = 12.0,
    this.value,
    this.onChange,
    this.controller,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.enabled = true,
    this.showLabel = true,
    this.focusNode,
    this.labelStyle,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.padding,
    this.height,
    this.minLines,
    this.maxLines,
  });

  @override
  State createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    // Chỉ áp dụng value khi không có controller bên ngoài và value khác null
    if (widget.controller == null && widget.value != null) {
      _controller.text = widget.value!;
    }
  }

  @override
  void didUpdateWidget(MyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ đồng bộ value -> controller khi dùng controller nội bộ
    if (widget.controller == null &&
        oldWidget.value != widget.value &&
        widget.value != null) {
      _controller.text = widget.value!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: theo dõi giá trị controller mỗi lần build
    try {
      // ignore: avoid_print
      debugPrint(
        '[MyTextField:build] label=${widget.label} text="${(widget.controller ?? _controller).text}" hasError=${widget.hasError}',
      );
    } catch (_) {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          MyText(
            text: widget.label!,
            textStyle: 'body',
            textSize: '14',
            textColor: 'secondary',
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height:
              widget.height ??
              (widget.maxLines != null && (widget.maxLines ?? 1) > 1
                  ? null
                  : 44),
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? DesignTokens.surfacePrimary,
            borderRadius: BorderRadius.circular(widget.borderRadius!),
            border: Border.all(
              color:
                  widget.hasError
                      ? DesignTokens.alerts['error']!
                      : widget.borderColor ?? DesignTokens.borderPrimary,
              width: widget.hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            minLines: widget.minLines,
            maxLines: widget.maxLines ?? 1,
            controller: widget.controller ?? _controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            cursorColor: DesignTokens.textBrand,
            onChanged: (value) {
              setState(() {
                if (widget.controller != null) {
                  widget.controller!.text = value;
                }
              });
              if (widget.onChange != null) {
                widget.onChange!(value);
              }
            },
            style:
                MyTypography.getStyle('label', '14')?.copyWith(
                  color: widget.textColor ?? DesignTokens.textPrimary,
                ) ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.textColor ?? DesignTokens.textPrimary,
                ),
            obscureText: widget.obscureText,
            decoration: InputDecoration(
              isDense: true,
              // Dùng prefix thay cho prefixIcon để tránh padding ngang mặc định
              prefixIcon: Padding(
                padding: const EdgeInsets.all(0.0),
                child: widget.prefixIcon,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              // Dùng suffix thay cho suffixIcon để tránh padding ngang mặc định
              suffixIcon: widget.suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              contentPadding: EdgeInsets.only(
                left: widget.prefixIcon != null ? 8 : 0,
                right: widget.suffixIcon != null ? 8 : 0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              hintText: widget.hintText,
              hintStyle:
                  MyTypography.getStyle(
                    'label',
                    '14',
                  )?.copyWith(color: DesignTokens.textPlaceholder) ??
                  TextStyle(
                    color: DesignTokens.textPlaceholder,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: 6),
          MyText(
            text: widget.errorText!,
            textStyle: 'label',
            textSize: '12',
            textColor: 'error',
            lineHeight: 1.38,
          ),
        ],
      ],
    );
  }
}
