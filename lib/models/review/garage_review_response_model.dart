class GarageReviewResponse {
  final int total;
  final double averageRating;
  final List<GarageReview> reviews;

  GarageReviewResponse({
    required this.total,
    required this.averageRating,
    required this.reviews,
  });

  factory GarageReviewResponse.fromJson(Map<String, dynamic> json) {
    return GarageReviewResponse(
      total: json['total'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      reviews: (json['reviews'] as List<dynamic>?)?.map((item) => GarageReview.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'average_rating': averageRating,
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }
}

class GarageReview {
  final int id;
  final CreatedBy createdBy;
  final int quotationId;
  final int requestServiceId;
  final double starRating;
  final String comment;
  final String createdAt;
  final String updatedAt;

  GarageReview({
    required this.id,
    required this.createdBy,
    required this.quotationId,
    required this.requestServiceId,
    required this.starRating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GarageReview.fromJson(Map<String, dynamic> json) {
    return GarageReview(
      id: json['id'] ?? 0,
      createdBy: CreatedBy.fromJson(json['created_by'] ?? {}),
      quotationId: json['quotation_id'] ?? 0,
      requestServiceId: json['request_service_id'] ?? 0,
      starRating: (json['star_rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy.toJson(),
      'quotation_id': quotationId,
      'request_service_id': requestServiceId,
      'star_rating': starRating,
      'comment': comment,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class CreatedBy {
  final int id;
  final String name;
  final String phone;

  CreatedBy({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }
}
