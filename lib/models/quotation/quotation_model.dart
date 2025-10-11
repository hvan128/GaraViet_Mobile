import 'package:gara/models/user/user_info_model.dart';

class QuotationModel {
  final int id;
  final int requestServiceId;
  final UserInfoResponse? inforGarage; // Tái sử dụng UserInfoResponse cho garage info
  final String? codeQuotation;
  final int price;
  final int remainPrice;
  final int voucherValue;
  final int depositValue;
  final String description;
  final int status;
  final int? warranty;
  final String? createdAt;
  final String? updatedAt;
  final String? timeAgo;

  QuotationModel({
    required this.id,
    required this.requestServiceId,
    required this.price,
    required this.remainPrice,
    required this.voucherValue,
    required this.depositValue,
    required this.description,
    required this.status,
    this.inforGarage,
    this.codeQuotation,
    this.warranty,
    this.createdAt,
    this.updatedAt,
    this.timeAgo,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    // Normalize description: collapse multiple whitespaces/newlines to single space and trim
    final String normalizedDescription = ((json['description'] ?? '') as Object)
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return QuotationModel(
      id: json['id'] ?? 0,
      requestServiceId: json['request_service_id'] ?? 0,
      inforGarage: json['infor_garage'] is Map<String, dynamic>
          ? UserInfoResponse.fromJson(json['infor_garage'] as Map<String, dynamic>)
          : null,
      codeQuotation: json['code_quotation'],
      price: json['price'] ?? 0,
      remainPrice: json['remain_price'] ?? 0,
      voucherValue: json['voucher_value'] ?? 0,
      depositValue: json['deposit_value'] ?? 0,
      description: normalizedDescription,
      status: json['status'] ?? 1,
      warranty: json['warranty'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      timeAgo: json['time_ago'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_service_id': requestServiceId,
      'infor_garage': inforGarage?.toJson(),
      'code_quotation': codeQuotation,
      'price': price,
      'remain_price': remainPrice,
      'voucher_value': voucherValue,
      'deposit_value': depositValue,
      'description': description,
      'status': status,
      'warranty': warranty,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'time_ago': timeAgo,
    };
  }

  // Quotation status constants (7 trạng thái)
  static const int waitingForQuotation = 1; // Chờ báo giá
  static const int waitingForSchedule = 2; // Chờ lên lịch
  static const int noDeposit = 3; // Chưa cọc
  static const int depositPaid = 4; // Đã cọc
  static const int notYetCharge = 5; // Chưa thu phí
  static const int chargePaid = 6; // Đã thu phí
  static const int cancelled = 7; // Đã hủy

  String get statusText {
    switch (status) {
      case waitingForQuotation:
        return 'Chờ báo giá';
      case waitingForSchedule:
        return 'Chờ lên lịch';
      case noDeposit:
        return 'Chưa cọc';
      case depositPaid:
        return 'Đã cọc';
      case notYetCharge:
        return 'Chưa thu phí';
      case chargePaid:
        return 'Đã thu phí';
      case cancelled:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  // Format price with thousand separators
  String get formattedPrice {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Format remain price with thousand separators
  String get formattedRemainPrice {
    return remainPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Format voucher value with thousand separators
  String get formattedVoucherValue {
    return voucherValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Format deposit value with thousand separators
  String get formattedDepositValue {
    return depositValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}


class CreateQuotationRequest {
  final int requestServiceId;
  final int price;
  final String description;

  CreateQuotationRequest({
    required this.requestServiceId,
    required this.price,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_service_id': requestServiceId,
      'price': price,
      'description': description,
    };
  }
}

class CreateQuotationResponse {
  final bool success;
  final String message;
  final QuotationModel? data;

  CreateQuotationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CreateQuotationResponse.fromJson(Map<String, dynamic> json) {
    return CreateQuotationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? QuotationModel.fromJson(json['data']) : null,
    );
  }
}

class QuotationListResponse {
  final String message;
  final List<QuotationModel> data;

  QuotationListResponse({
    required this.message,
    required this.data,
  });

  factory QuotationListResponse.fromJson(Map<String, dynamic> json) {
    return QuotationListResponse(
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => QuotationModel.fromJson(item))
          .toList() ?? [],
    );
  }
}
