import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';

enum QuotationStatus {
  waitingForQuotation(1, 'Chờ báo giá'),
  waitingForSchedule(2, 'Chờ chốt lịch'),
  noDeposit(3, 'Chưa cọc'),
  depositPaid(4, 'Đã cọc'),
  notYetCharge(5, 'Chưa thu phí'),
  chargePaid(6, 'Đã thu phí'),
  cancelled(7, 'Đã hủy');

  const QuotationStatus(this.value, this.displayName);

  final int value;
  final String displayName;

  static QuotationStatus fromValue(int value) {
    return QuotationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => QuotationStatus.waitingForQuotation,
    );
  }

  // Màu sắc cho từng trạng thái (background/text/border)
  QuotationStatusColors get color {
    switch (this) {
      case QuotationStatus.waitingForQuotation:
        return const QuotationStatusColors(
          background: DesignTokens.primaryBlue4,
          text: DesignTokens.textBrand,
          border: DesignTokens.borderBrandPrimary,
        );
      case QuotationStatus.waitingForSchedule:
        return const QuotationStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case QuotationStatus.noDeposit:
        return const QuotationStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case QuotationStatus.depositPaid:
        return const QuotationStatusColors(
          background: Color(0xFFFFFDEA),
          text: Color(0xFFD0B304),
          border: DesignTokens.secondaryYellow,
        );
      case QuotationStatus.notYetCharge:
        return const QuotationStatusColors(
          background: Color(0xFFF5FFF8),
          text: DesignTokens.secondaryGreen,
          border: DesignTokens.secondaryGreen,
        );
      case QuotationStatus.chargePaid:
        return const QuotationStatusColors(
          background: Color(0xFFF5FFF8),
          text: DesignTokens.secondaryGreen,
          border: DesignTokens.secondaryGreen,
        );
      case QuotationStatus.cancelled:
        return const QuotationStatusColors(
          background: Color(0xFFFFEAEA),
          text: DesignTokens.secondaryOrange,
          border: DesignTokens.secondaryOrange,
        );
    }
  }

  // Kiểm tra trạng thái có thể chuyển đổi được không
  bool canTransitionTo(QuotationStatus newStatus) {
    switch (this) {
      case QuotationStatus.waitingForQuotation:
        return newStatus == QuotationStatus.waitingForSchedule || 
               newStatus == QuotationStatus.cancelled;
      case QuotationStatus.waitingForSchedule:
        return newStatus == QuotationStatus.noDeposit || 
               newStatus == QuotationStatus.cancelled;
      case QuotationStatus.noDeposit:
        return newStatus == QuotationStatus.depositPaid || 
               newStatus == QuotationStatus.cancelled;
      case QuotationStatus.depositPaid:
        return newStatus == QuotationStatus.notYetCharge || 
               newStatus == QuotationStatus.cancelled;
      case QuotationStatus.notYetCharge:
        return newStatus == QuotationStatus.chargePaid || 
               newStatus == QuotationStatus.cancelled;
      case QuotationStatus.chargePaid:
        return false; // Trạng thái cuối cùng
      case QuotationStatus.cancelled:
        return false; // Không thể chuyển từ trạng thái hủy
    }
  }
}

class QuotationStatusColors {
  final Color background;
  final Color text;
  final Color border;

  const QuotationStatusColors({
    required this.background,
    required this.text,
    required this.border,
  });
}
