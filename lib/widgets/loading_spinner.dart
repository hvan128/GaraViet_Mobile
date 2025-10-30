import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';

class LoadingSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? text;
  final TextStyle? textStyle;

  const LoadingSpinner({super.key, this.size = 24.0, this.color, this.strokeWidth = 2.0, this.text, this.textStyle});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2.0 * 3.14159,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: widget.strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color ?? DesignTokens.textBrand),
                ),
              ),
            );
          },
        ),
        if (widget.text != null) ...[
          const SizedBox(height: 8),
          Text(widget.text!, style: widget.textStyle ?? TextStyle(fontSize: 14, color: DesignTokens.textTertiary)),
        ],
      ],
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DesignTokens.surfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: LoadingSpinner(text: loadingText),
              ),
            ),
          ),
      ],
    );
  }
}
