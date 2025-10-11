import 'package:flutter/material.dart';
import 'package:gara/widgets/text.dart';
import 'quotation_status.dart';
import 'request_status.dart';
import 'booking_status.dart';

class StatusWidget extends StatelessWidget {
  final dynamic status;
  final StatusType type;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double? borderRadius;
  final TextStyle? textStyle;
  final bool isSelected;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const StatusWidget({
    Key? key,
    required this.status,
    required this.type,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.isSelected = false,
    this.onRemove,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    final colors = _getStatusColors();

    final base = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: Border.all(color: colors.border, width: isSelected ? 2 : 1),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              text: statusInfo.displayName,
              color: colors.text,
              textStyle: 'body',
              textSize: '10',
            ),
          ],
        ),
      ),
    );

    final child = Stack(
      clipBehavior: Clip.none,
      children: [
        // Add padding to reserve space for the close badge so it won't be clipped by parent viewports
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 6),
          child: base,
        ),
        if (isSelected && onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFE74C3C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: child,
      );
    }
    return child;
  }

  StatusInfo _getStatusInfo() {
    if (type == StatusType.quotation) {
      final quotationStatus = status is int 
          ? QuotationStatus.fromValue(status)
          : status as QuotationStatus;
      return StatusInfo(
        displayName: quotationStatus.displayName,
        color: quotationStatus.color,
      );
    } else if (type == StatusType.request) {
      final requestStatus = status is int 
          ? RequestStatus.fromValue(status)
          : status as RequestStatus;
      return StatusInfo(
        displayName: requestStatus.displayName,
        color: requestStatus.color,
      );
    } else {
      final bookingStatus = status is int
          ? BookingStatus.fromValue(status)
          : status as BookingStatus;
      return StatusInfo(
        displayName: bookingStatus.displayName,
        color: bookingStatus.color,
      );
    }
  }

  _WidgetColors _getStatusColors() {
    final statusInfo = _getStatusInfo();
    return _WidgetColors(
      background: statusInfo.color.background,
      text: statusInfo.color.text,
      border: isSelected ? _getActiveBorderColor(statusInfo.color) : statusInfo.color.border,
    );
  }

  Color _getActiveBorderColor(dynamic statusColor) {
    // Sử dụng màu text của status làm viền active để đồng bộ
    // Hoặc có thể sử dụng màu background với độ đậm hơn
    if (statusColor.text != null) {
      return statusColor.text;
    }
    // Fallback: sử dụng màu background với độ đậm hơn
    return statusColor.background.withOpacity(0.8);
  }

}

class StatusInfo {
  final String displayName;
  final dynamic color;

  StatusInfo({
    required this.displayName,
    required this.color,
  });
}

enum StatusType {
  quotation,
  request,
  booking,
}

class _WidgetColors {
  final Color background;
  final Color text;
  final Color border;

  const _WidgetColors({
    required this.background,
    required this.text,
    required this.border,
  });
}

// Widget hiển thị danh sách trạng thái như trong ảnh
class StatusListWidget extends StatelessWidget {
  final StatusType type;
  final List<dynamic> statuses;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const StatusListWidget({
    Key? key,
    required this.type,
    required this.statuses,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          type == StatusType.quotation ? 'Báo giá' : 'Yêu cầu user',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: statuses.map((status) {
            return StatusWidget(
              status: status,
              type: type,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Widget hiển thị tất cả trạng thái như trong ảnh
class AllStatusWidget extends StatelessWidget {
  const AllStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Dark gray background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yêu cầu user section
          Expanded(
            child: StatusListWidget(
              type: StatusType.request,
              statuses: RequestStatus.values,
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
          const SizedBox(width: 24),
          // Báo giá section
          Expanded(
            child: StatusListWidget(
              type: StatusType.quotation,
              statuses: QuotationStatus.values,
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ],
      ),
    );
  }
}
