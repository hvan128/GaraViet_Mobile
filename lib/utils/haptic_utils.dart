import 'package:flutter/services.dart';

/// Utility class for haptic feedback across the app
class HapticUtils {
  /// Light haptic feedback - subtle vibration
  /// Good for: button taps, selection changes, minor interactions
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback - moderate vibration
  /// Good for: navigation changes, form submissions, important actions
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback - strong vibration
  /// Good for: errors, warnings, major state changes
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection haptic feedback - for selection changes
  /// Good for: tab switches, toggle switches, picker selections
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Success haptic feedback - combination of light impacts
  /// Good for: successful actions, completions
  static void success() {
    // Custom success pattern: light -> medium
    light();
    Future.delayed(const Duration(milliseconds: 50), () {
      medium();
    });
  }

  /// Error haptic feedback - heavy impact
  /// Good for: errors, failures, invalid actions
  static void error() {
    heavy();
  }

  /// Warning haptic feedback - medium impact
  /// Good for: warnings, confirmations
  static void warning() {
    medium();
  }

  /// Custom haptic pattern
  /// [pattern] - list of durations in milliseconds for vibration
  /// Note: This is a simplified version, actual custom patterns require platform-specific implementation
  static void custom(List<int> pattern) {
    if (pattern.isEmpty) return;
    
    for (int i = 0; i < pattern.length; i++) {
      Future.delayed(Duration(milliseconds: pattern[i]), () {
        if (i % 2 == 0) {
          light();
        } else {
          medium();
        }
      });
    }
  }
}

/// Extension for easy haptic feedback on widgets
extension HapticFeedbackExtension on VoidCallback {
  /// Execute callback with light haptic feedback
  void withLightHaptic() {
    HapticUtils.light();
    this();
  }

  /// Execute callback with medium haptic feedback
  void withMediumHaptic() {
    HapticUtils.medium();
    this();
  }

  /// Execute callback with heavy haptic feedback
  void withHeavyHaptic() {
    HapticUtils.heavy();
    this();
  }

  /// Execute callback with selection haptic feedback
  void withSelectionHaptic() {
    HapticUtils.selection();
    this();
  }
}
