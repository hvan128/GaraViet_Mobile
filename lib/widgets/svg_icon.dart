import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget tái sử dụng để hiển thị icon từ SVG
/// Hỗ trợ truyền path SVG, width, height và các thuộc tính khác
class SvgIcon extends StatelessWidget {
  /// Đường dẫn đến file SVG
  final String svgPath;
  
  /// Chiều rộng của icon
  final double? width;
  
  /// Chiều cao của icon
  final double? height;
  
  /// Màu sắc của icon
  final Color? color;
  
  /// Kích thước của icon (áp dụng cho cả width và height)
  final double? size;
  
  /// Alignment của icon trong container
  final Alignment alignment;
  
  /// BoxFit cho icon
  final BoxFit fit;
  
  /// Semantics label cho accessibility
  final String? semanticsLabel;

  const SvgIcon({
    super.key,
    required this.svgPath,
    this.width,
    this.height,
    this.color,
    this.size,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  });

  /// Constructor với kích thước cố định (size áp dụng cho cả width và height)
  const SvgIcon.sized({
    super.key,
    required this.svgPath,
    required double size,
    this.color,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  }) : width = size,
       height = size,
       this.size = null;

  /// Constructor cho icon vuông với kích thước cố định
  const SvgIcon.square({
    super.key,
    required this.svgPath,
    required double size,
    this.color,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  }) : width = size,
       height = size,
       this.size = null;

  @override
  Widget build(BuildContext context) {
    // Sử dụng size nếu được cung cấp, ngược lại sử dụng width/height riêng lẻ
    final double? finalWidth = size ?? width;
    final double? finalHeight = size ?? height;

    return SvgPicture.asset(
      svgPath,
      width: finalWidth,
      height: finalHeight,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      alignment: alignment,
      fit: fit,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Extension để tạo SvgIcon dễ dàng hơn
extension SvgIconExtension on String {
  /// Tạo SvgIcon từ đường dẫn SVG
  SvgIcon toSvgIcon({
    double? width,
    double? height,
    Color? color,
    double? size,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    String? semanticsLabel,
  }) {
    return SvgIcon(
      svgPath: this,
      width: width,
      height: height,
      color: color,
      size: size,
      alignment: alignment,
      fit: fit,
      semanticsLabel: semanticsLabel,
    );
  }

  /// Tạo SvgIcon với kích thước cố định
  SvgIcon toSvgIconSized({
    required double size,
    Color? color,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    String? semanticsLabel,
  }) {
    return SvgIcon.sized(
      svgPath: this,
      size: size,
      color: color,
      alignment: alignment,
      fit: fit,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Predefined icon sizes cho consistency
class SvgIconSizes {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Predefined colors cho icons
class SvgIconColors {
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.grey;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
}

