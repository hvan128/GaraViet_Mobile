import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';

enum BookingStatus {
  scheduled(1, 'Đã lên lịch'),
  completed(2, 'Hoàn thành'),
  cancelled(3, 'Đã hủy');

  const BookingStatus(this.value, this.displayName);
  final int value;
  final String displayName;

  static BookingStatus fromValue(int value) {
    return BookingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BookingStatus.scheduled,
    );
  }

  BookingStatusColors get color {
    switch (this) {
      case BookingStatus.scheduled:
        return const BookingStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case BookingStatus.completed:
        return const BookingStatusColors(
          background: Color(0xFFF5FFF8),
          text: DesignTokens.secondaryGreen,
          border: DesignTokens.secondaryGreen,
        );
      case BookingStatus.cancelled:
        return const BookingStatusColors(
          background: Color(0xFFFFEAEA),
          text: DesignTokens.secondaryOrange,
          border: DesignTokens.secondaryOrange,
        );
    }
  }

  bool canTransitionTo(BookingStatus newStatus) {
    switch (this) {
      case BookingStatus.scheduled:
        return newStatus == BookingStatus.completed || newStatus == BookingStatus.cancelled;
      case BookingStatus.completed:
        return false;
      case BookingStatus.cancelled:
        return false;
    }
  }
}

class BookingStatusColors {
  final Color background;
  final Color text;
  final Color border;

  const BookingStatusColors({
    required this.background,
    required this.text,
    required this.border,
  });
}


