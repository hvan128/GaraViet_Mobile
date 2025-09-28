import 'package:gara/models/car/car_info_model.dart';

class ImageAttachment {
  final int id;
  final String name;
  final String path;
  final String timeUpload;

  const ImageAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.timeUpload,
  });

  factory ImageAttachment.fromJson(Map<String, dynamic> json) {
    return ImageAttachment(
      id: RequestServiceModel._toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      timeUpload: (json['time_upload'] ?? json['timeUpload'] ?? '').toString(),
    );
  }
}

class Quotation {
  final int id;
  final int price;
  final int status;
  final String warranty;
  final String description;
  final String createdAt;
  final String updatedAt;

  const Quotation({
    required this.id,
    required this.price,
    required this.status,
    required this.warranty,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: RequestServiceModel._toInt(json['id']),
      price: RequestServiceModel._toInt(json['price']),
      status: RequestServiceModel._toInt(json['status']),
      warranty: (json['warranty'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
    );
  }
}

class RequestServiceModel {
  final int id;
  final String requestCode;
  final int createdBy;
  final CarInfo? carInfo;
  final int status; // 1 WAITING_FOR_QUOTATION, 2 ACCEPTED, 3 REJECTED, 4 COMPLETED
  final String address;
  final String? description;
  final String? radiusSearch;
  final List<ImageAttachment> listImageAttachment;
  final List<Quotation>? listQuotation;
  final String createdAt;
  final String updatedAt;
  final String? timeAgo;

  const RequestServiceModel({
    required this.id,
    required this.requestCode,
    required this.createdBy,
    this.carInfo,
    required this.status,
    required this.address,
    this.description,
    this.radiusSearch,
    this.listImageAttachment = const [],
    this.listQuotation,
    required this.createdAt,
    required this.updatedAt,
    this.timeAgo,
  });

  factory RequestServiceModel.fromJson(Map<String, dynamic> json) {
    return RequestServiceModel(
      id: _toInt(json['id']),
      requestCode: (json['request_code'] ?? json['requestCode'] ?? '').toString(),
      createdBy: _toInt(json['created_by'] ?? json['createdBy']),
      carInfo: json['car_infor'] != null ? CarInfo.fromJson(json['car_infor']) : null,
      status: _toInt(json['status']),
      address: (json['address'] ?? '').toString(),
      description: json['description']?.toString(),
      radiusSearch: (json['radius_search'] ?? json['radiusSearch'])?.toString(),
      listImageAttachment: (json['list_image_attachment'] as List?)
          ?.map((e) => ImageAttachment.fromJson(e))
          .toList() ?? [],
      listQuotation: (json['list_quotation'] as List?)
          ?.map((e) => Quotation.fromJson(e))
          .toList(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
      timeAgo: json['time_ago']?.toString(),
    );
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
      requests: (json['requests'] as List?)
          ?.map((e) => RequestServiceModel.fromJson(e))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}


