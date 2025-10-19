import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const Skeleton({super.key, this.width, this.height, this.borderRadius, this.margin});

  @override
  Widget build(BuildContext context) {
    final base = DesignTokens.gray300; // nền đậm hơn
    final highlight = DesignTokens.gray200; // highlight đậm hơn

    return _Shimmer(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: base,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }

  factory Skeleton.line({double width = double.infinity, double height = 12, EdgeInsetsGeometry? margin}) {
    return Skeleton(width: width, height: height, margin: margin, borderRadius: BorderRadius.circular(6));
  }

  factory Skeleton.circle({double size = 40, EdgeInsetsGeometry? margin}) {
    return Skeleton(
      width: size,
      height: size,
      margin: margin,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  factory Skeleton.box({double width = double.infinity, double height = 80, BorderRadius? radius, EdgeInsetsGeometry? margin}) {
    return Skeleton(width: width, height: height, margin: margin, borderRadius: radius ?? BorderRadius.circular(12));
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonList({super.key, this.itemCount = 6, this.itemHeight = 80, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, __) => Skeleton.box(height: itemHeight),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _Shimmer({required this.child, required this.baseColor, required this.highlightColor});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final width = bounds.width;
            final gradientWidth = width / 2;
            final dx = (width + gradientWidth) * _controller.value - gradientWidth;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: GradientTranslation(dx, 0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class GradientTranslation extends GradientTransform {
  final double dx;
  final double dy;

  const GradientTranslation(this.dx, this.dy);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(dx, dy);
  }
}


