import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';

// Trạng thái phòng chat tổng hợp từ nhiều trạng thái nghiệp vụ
// 1: Chờ báo giá, 2: Chờ lên lịch, 3: Đã lên lịch, 4: Hoàn thành, 5: Đã hủy
enum MessageStatus {
  waitingForQuotation(1, 'Chờ báo giá'),
  waitingForSchedule(2, 'Chờ lên lịch'),
  scheduled(3, 'Đã lên lịch'),
  completed(4, 'Hoàn thành'),
  cancelled(5, 'Đã hủy');

  const MessageStatus(this.value, this.displayName);

  final int value;
  final String displayName;

  static MessageStatus fromValue(int value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.waitingForQuotation,
    );
  }

  MessageStatusColors get color {
    switch (this) {
      case MessageStatus.waitingForQuotation:
        return const MessageStatusColors(
          background: DesignTokens.primaryBlue4,
          text: DesignTokens.textBrand,
          border: DesignTokens.borderBrandPrimary,
        );
      case MessageStatus.waitingForSchedule:
        return const MessageStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case MessageStatus.scheduled:
        return const MessageStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case MessageStatus.completed:
        return const MessageStatusColors(
          background: Color(0xFFF5FFF8),
          text: DesignTokens.secondaryGreen,
          border: DesignTokens.secondaryGreen,
        );
      case MessageStatus.cancelled:
        return const MessageStatusColors(
          background: Color(0xFFFFEAEA),
          text: DesignTokens.secondaryOrange,
          border: DesignTokens.secondaryOrange,
        );
    }
  }
}

class MessageStatusColors {
  final Color background;
  final Color text;
  final Color border;

  const MessageStatusColors({
    required this.background,
    required this.text,
    required this.border,
  });
}


