import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';

enum RequestStatus {
  waitingForQuotation(1, 'Chờ báo giá'),
  accepted(2, 'Đã lên lịch'),
  rejected(3, 'Hủy'),
  completed(4, 'Hoàn thành');

  const RequestStatus(this.value, this.displayName);

  final int value;
  final String displayName;

  static RequestStatus fromValue(int value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RequestStatus.waitingForQuotation,
    );
  }

  // Màu sắc cho từng trạng thái (background/text/border)
  RequestStatusColors get color {
    switch (this) {
      case RequestStatus.waitingForQuotation:
        return const RequestStatusColors(
          background: DesignTokens.primaryBlue4,
          text: DesignTokens.textBrand,
          border: DesignTokens.borderBrandPrimary,
        );
      case RequestStatus.accepted:
        return const RequestStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case RequestStatus.completed:
        return const RequestStatusColors(
          background: Color(0xFFF5FFF8),
          text: DesignTokens.secondaryGreen,
          border: DesignTokens.secondaryGreen,
        );
      case RequestStatus.rejected:
        return const RequestStatusColors(
          background: Color(0xFFFFEAEA),
          text: DesignTokens.secondaryOrange,
          border: DesignTokens.secondaryOrange,
        );
    }
  }

  // Kiểm tra trạng thái có thể chuyển đổi được không
  bool canTransitionTo(RequestStatus newStatus) {
    switch (this) {
      case RequestStatus.waitingForQuotation:
        return newStatus == RequestStatus.accepted || 
               newStatus == RequestStatus.rejected;
      case RequestStatus.accepted:
        return newStatus == RequestStatus.completed;
      case RequestStatus.completed:
        return false; // Trạng thái cuối cùng
      case RequestStatus.rejected:
        return false; // Không thể chuyển từ trạng thái từ chối
    }
  }
}

class RequestStatusColors {
  final Color background;
  final Color text;
  final Color border;

  const RequestStatusColors({
    required this.background,
    required this.text,
    required this.border,
  });
}
