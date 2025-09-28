class QuotationModel {
  final int id;
  final int requestServiceId;
  final int price;
  final String description;
  final int status;
  final String? createdAt;
  final String? updatedAt;

  QuotationModel({
    required this.id,
    required this.requestServiceId,
    required this.price,
    required this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] ?? 0,
      requestServiceId: json['request_service_id'] ?? 0,
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      status: json['status'] ?? 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_service_id': requestServiceId,
      'price': price,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
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
