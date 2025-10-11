import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/models/request/request_service_model.dart';

class BookingModel {
  final int id;
  final int status; // dùng cho garage API (status của quotation) hoặc user booking status
  final RequestServiceModel? requestService;
  final QuotationModel? quotation;
  final DateTime? time;

  const BookingModel({
    required this.id,
    required this.status,
    this.requestService,
    this.quotation,
    this.time,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: _toInt(json['id']),
      status: _toInt(json['status']),
      requestService: (json['request_service'] is Map<String, dynamic>)
          ? RequestServiceModel.fromJson(json['request_service'] as Map<String, dynamic>)
          : null,
      quotation: (json['quotation'] is Map<String, dynamic>)
          ? QuotationModel.fromJson(json['quotation'] as Map<String, dynamic>)
          : null,
      time: _parseTime(json['booking']?['time'] ?? json['time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'request_service': requestService?.toJson(),
      'quotation': quotation?.toJson(),
      'time': time?.toIso8601String(),
    };
  }

  static DateTime? _parseTime(dynamic v) {
    final s = (v ?? '').toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class BookingPagination {
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;

  const BookingPagination({
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory BookingPagination.fromJson(Map<String, dynamic> json) {
    return BookingPagination(
      currentPage: BookingModel._toInt(json['current_page'] ?? json['currentPage']),
      perPage: BookingModel._toInt(json['per_page'] ?? json['perPage']),
      totalItems: BookingModel._toInt(json['total_items'] ?? json['total'] ?? json['totalItems']),
      totalPages: BookingModel._toInt(json['total_pages'] ?? json['totalPages']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total_items': totalItems,
      'total_pages': totalPages,
    };
  }
}

class BookingListResponse {
  final List<BookingModel> data;
  final BookingPagination pagination;
  final bool success;
  final String message;

  const BookingListResponse({
    required this.data,
    required this.pagination,
    required this.success,
    required this.message,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    // API bọc: { success, message, data: { data: [...], pagination: {...} } }
    final container = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : <String, dynamic>{};
    final list = (container['data'] as List?) ?? [];
    return BookingListResponse(
      success: json['success'] ?? true,
      message: json['message']?.toString() ?? '',
      data: list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList(),
      pagination: BookingPagination.fromJson(container['pagination'] ?? const <String, dynamic>{}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'data': data.map((e) => e.toJson()).toList(),
        'pagination': pagination.toJson(),
      },
    };
  }
}


