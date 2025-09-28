class ReviewModel {
  final String id;
  final String userName;
  final String? userAvatar;
  final String serviceName;
  final String comment;
  final int rating;
  final DateTime? createdAt;
  final String? context; // "Vietnam car" như trong hình

  ReviewModel({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.serviceName,
    required this.comment,
    required this.rating,
    this.createdAt,
    this.context,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      serviceName: json['serviceName'] ?? '',
      comment: json['comment'] ?? '',
      rating: json['rating'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      context: json['context'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userAvatar': userAvatar,
      'serviceName': serviceName,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt?.toIso8601String(),
      'context': context,
    };
  }
}
