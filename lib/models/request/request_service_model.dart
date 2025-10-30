import 'package:gara/models/car/car_info_model.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/models/file/file_info_model.dart';

// Removed inline Quotation; use QuotationModel instead

class RequestServiceModel {
  final int id;
  final String requestCode;
  final UserInfoResponse? inforUser;
  final CarInfo? carInfo;
  final int status; // 1 WAITING_FOR_QUOTATION, 2 ACCEPTED, 3 REJECTED, 4 COMPLETED
  // Address label for display; server may return address as an object
  // { label: string, latitude: number|null, longitude: number|null }
  final String address;
  final double? addressLatitude;
  final double? addressLongitude;
  final String? description;
  final String? radiusSearch;
  final List<FileInfo> listImageAttachment;
  final List<QuotationModel>? listQuotation;
  final String createdAt;
  final String updatedAt;
  final String? timeAgo;

  const RequestServiceModel({
    required this.id,
    required this.requestCode,
    required this.inforUser,
    this.carInfo,
    required this.status,
    required this.address,
    this.addressLatitude,
    this.addressLongitude,
    this.description,
    this.radiusSearch,
    this.listImageAttachment = const [],
    this.listQuotation,
    required this.createdAt,
    required this.updatedAt,
    this.timeAgo,
  });

  factory RequestServiceModel.fromJson(Map<String, dynamic> json) {
    // Normalize textual fields: collapse multiple whitespaces/newlines to single space and trim
    String _normalize(String? v) => (v ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    // Address could be a string or an object
    final dynamic addressJson = json['address'];
    String addressLabel;
    double? latitude;
    double? longitude;
    if (addressJson is Map<String, dynamic>) {
      addressLabel = _normalize((addressJson['label'] ?? '').toString());
      latitude = _toDouble(addressJson['latitude']);
      longitude = _toDouble(addressJson['longitude']);
    } else {
      addressLabel = _normalize((addressJson ?? '').toString());
    }
    return RequestServiceModel(
      id: _toInt(json['id']),
      requestCode: _normalize((json['request_code'] ?? json['requestCode'])?.toString()),
      inforUser: (json['infor_user'] is Map<String, dynamic>)
          ? UserInfoResponse.fromJson(json['infor_user'] as Map<String, dynamic>)
          : (json['inforUser'] is Map<String, dynamic>
              ? UserInfoResponse.fromJson(json['inforUser'] as Map<String, dynamic>)
              : (json['created_by'] is Map<String, dynamic>
                  ? UserInfoResponse.fromJson(json['created_by'] as Map<String, dynamic>)
                  : (json['createdBy'] is Map<String, dynamic>
                      ? UserInfoResponse.fromJson(json['createdBy'] as Map<String, dynamic>)
                      : null))),
      carInfo: json['car_infor'] != null ? CarInfo.fromJson(json['car_infor']) : null,
      status: _toInt(json['status']),
      address: addressLabel,
      addressLatitude: latitude,
      addressLongitude: longitude,
      description: _normalize(json['description']?.toString()),
      radiusSearch: _normalize((json['radius_search'] ?? json['radiusSearch'])?.toString()),
      listImageAttachment: (json['list_image_attachment'] as List?)?.map((e) => FileInfo.fromJson(e)).toList() ?? [],
      listQuotation: (json['list_quotation'] as List?)?.map((e) => QuotationModel.fromJson(e)).toList(),
      createdAt: _normalize((json['created_at'] ?? json['createdAt'] ?? '').toString()),
      updatedAt: _normalize((json['updated_at'] ?? json['updatedAt'] ?? '').toString()),
      timeAgo: _normalize(json['time_ago']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_code': requestCode,
      'infor_user': inforUser?.toJson(),
      'car_infor': carInfo?.toJson(),
      'status': status,
      'address': {
        'label': address,
        'latitude': addressLatitude,
        'longitude': addressLongitude,
      },
      'description': description,
      'radius_search': radiusSearch,
      'list_image_attachment': listImageAttachment.map((e) => e.toJson()).toList(),
      'list_quotation': listQuotation?.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'time_ago': timeAgo,
    };
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }
}

class PaginationInfo {
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;

  const PaginationInfo({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: RequestServiceModel._toInt(json['current_page'] ?? json['currentPage']),
      perPage: RequestServiceModel._toInt(json['per_page'] ?? json['perPage']),
      total: RequestServiceModel._toInt(json['total']),
      totalPages: RequestServiceModel._toInt(json['total_pages'] ?? json['totalPages']),
    );
  }
}

class RequestListResponse {
  final List<RequestServiceModel> requests;
  final PaginationInfo pagination;

  const RequestListResponse({
    required this.requests,
    required this.pagination,
  });

  factory RequestListResponse.fromJson(Map<String, dynamic> json) {
    return RequestListResponse(
      requests: (json['requests'] as List?)?.map((e) => RequestServiceModel.fromJson(e)).toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}
