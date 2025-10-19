// Status Library - Thư viện quản lý trạng thái báo giá và yêu cầu dịch vụ
// 
// Cách sử dụng:
// 1. Import thư viện: import 'package:gara/utils/status/status_library.dart';
// 2. Sử dụng các widget và utility functions

export 'quotation_status.dart';
export 'request_status.dart';
export 'status_widget.dart';
export 'status_utils.dart';
export 'message_status.dart';
export 'booking_status.dart';

// Ví dụ sử dụng:
/*
// Hiển thị một trạng thái đơn lẻ
StatusWidget(
  status: QuotationStatus.waitingForQuotation,
  type: StatusType.quotation,
)

// Hiển thị danh sách trạng thái
StatusListWidget(
  type: StatusType.quotation,
  statuses: QuotationStatus.values,
)

// Hiển thị tất cả trạng thái như trong ảnh
AllStatusWidget()

// Sử dụng utility functions
final status = StatusUtils.getQuotationStatusByValue(1);
final canTransition = StatusUtils.canTransitionQuotationStatus(1, 2);
final nextStatuses = StatusUtils.getNextPossibleQuotationStatuses(1);
*/
