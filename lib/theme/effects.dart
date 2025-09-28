import 'package:flutter/material.dart';

class DesignEffects {
  // Small card shadow
  static const BoxShadow smallCard = BoxShadow(
    color: Color(0x0A111111), // #1111110a
    offset: Offset(0, 5),
    blurRadius: 20,
    spreadRadius: 0,
  );

  // Medium card shadow
  static const BoxShadow medCard = BoxShadow(
    color: Color(0x14111111), // #11111114
    offset: Offset(0, 12),
    blurRadius: 30,
    spreadRadius: 0,
  );

  // Large card shadow
  static const BoxShadow largeCard = BoxShadow(
    color: Color(0x1F111111), // #1111111f
    offset: Offset(4, 16),
    blurRadius: 32,
    spreadRadius: 0,
  );

  // Helper methods to get shadow lists
  static List<BoxShadow> get smallCardShadow => [smallCard];
  static List<BoxShadow> get medCardShadow => [medCard];
  static List<BoxShadow> get largeCardShadow => [largeCard];
}
