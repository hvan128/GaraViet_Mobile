import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/svg_icon.dart';

class IconField extends StatelessWidget {
  final String svgPath;
  final bool isVisible;
  const IconField({super.key, required this.svgPath, this.isVisible = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(99),
        boxShadow: DesignEffects.smallCardShadow,
      ),

      child: SvgIcon(svgPath: svgPath, color: isVisible ? DesignTokens.textPrimary : DesignTokens.textPlaceholder, size: 100),
    );
  }
}