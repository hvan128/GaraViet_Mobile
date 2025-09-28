class GaraModel {
  String? image;
  String? title;
  String? description;
  String? address;
  String? phone;
  String? email;
  String? website;
  String? facebook;

  GaraModel({this.image, this.title, this.description, this.address, this.phone, this.email, this.website, this.facebook});

  GaraModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    title = json['title'];
    description = json['description'];
    address = json['address'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'title': title,
      'description': description,
      'address': address,
      'phone': phone,
    };
  }
}

