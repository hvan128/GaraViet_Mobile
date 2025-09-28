class ReputableProductModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? rating;
  final int? customerCount;
  final bool? isVerified;

  ReputableProductModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.rating,
    this.customerCount,
    this.isVerified,
  });

  factory ReputableProductModel.fromJson(Map<String, dynamic> json) {
    return ReputableProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      rating: json['rating'],
      customerCount: json['customerCount'],
      isVerified: json['isVerified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'customerCount': customerCount,
      'isVerified': isVerified,
    };
  }
}
