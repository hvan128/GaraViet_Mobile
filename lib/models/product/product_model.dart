class ProductModel {
  String? name;
  String? description;
  int? customerCount;
  bool? isPartner;

  ProductModel({
    this.name,
    this.description,
    this.customerCount,
    this.isPartner,
  });

  ProductModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    customerCount = json['customerCount'];
    isPartner = json['isPartner'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'customerCount': customerCount,
      'isPartner': isPartner,
    };
  }
}

