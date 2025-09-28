import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;
  final double borderRadius;
  final bool fullWidth;

  const ProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
    this.inactiveColor,
    this.height = 1.0,
    this.borderRadius = 2.0,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    final activeColorValue = activeColor ?? DesignTokens.borderBrandPrimary;
    final inactiveColorValue = inactiveColor ?? Colors.transparent;

    Widget progressBar = Container(
      height: height,
      decoration: BoxDecoration(
        color: inactiveColorValue,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          // Active progress bar - starts from left
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: activeColorValue,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ],
      ),
    );

    // If fullWidth is true, wrap with SizedBox to take full width
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: progressBar,
      );
    }

    return progressBar;
  }
}

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;
  final bool fullWidth;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
    this.inactiveColor,
    this.height = 1.0,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColorValue = activeColor ?? Colors.blue[600]!;
    final inactiveColorValue = inactiveColor ?? Colors.transparent;

    return ProgressBar(
      currentStep: currentStep,
      totalSteps: totalSteps,
      activeColor: activeColorValue,
      inactiveColor: inactiveColorValue,
      height: height,
      fullWidth: fullWidth,
    );
  }
}
