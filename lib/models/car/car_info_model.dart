class CarInfo {
  final int id;
  final int userId;
  final String typeCar;
  final String yearModel;
  final String vehicleLicensePlate;
  final String? description;
  final int status;

  const CarInfo({
    required this.id,
    required this.userId,
    required this.typeCar,
    required this.yearModel,
    required this.vehicleLicensePlate,
    this.description,
    required this.status,
  });

  factory CarInfo.fromJson(Map<String, dynamic> json) {
    return CarInfo(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      typeCar: (json['type_car'] ?? json['typeCar'] ?? '').toString(),
      yearModel: (json['year_model'] ?? json['yearModel'] ?? '').toString(),
      vehicleLicensePlate: (json['vehicle_license_plate'] ?? json['vehicleLicensePlate'] ?? '').toString(),
      description: json['description']?.toString(),
      status: _toInt(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type_car': typeCar,
      'year_model': yearModel,
      'vehicle_license_plate': vehicleLicensePlate,
      'description': description,
      'status': status,
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
