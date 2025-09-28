class UserRegisterRequest {
  final String phone;
  final String password;
  final String name;
  final String typeCar;
  final String yearModel;
  final String vehicleLicensePlate;

  UserRegisterRequest({
    required this.phone,
    required this.password,
    required this.name,
    required this.typeCar,
    required this.yearModel,
    required this.vehicleLicensePlate,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'password': password,
      'name': name,
      'type_car': typeCar,
      'year_model': yearModel,
      'vehicle_license_plate': vehicleLicensePlate,
    };
  }
}

class UserRegisterResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  UserRegisterResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory UserRegisterResponse.fromJson(Map<String, dynamic> json) {
    return UserRegisterResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}

class GarageRegisterRequest {
  final String phone;
  final String password;
  final String nameGarage;
  final String emailGarage;
  final String address;
  final String numberOfWorker;
  final String descriptionGarage;
  final String? deviceId;
  final String? cccd;
  final String? issueDate;
  final String? signature;

  GarageRegisterRequest({
    required this.phone,
    required this.password,
    required this.nameGarage,
    required this.emailGarage,
    required this.address,
    required this.numberOfWorker,
    required this.descriptionGarage,
    this.deviceId,
    this.cccd,
    this.issueDate,
    this.signature,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'phone': phone,
      'password': password,
      'name_garage': nameGarage,
      'email_garage': emailGarage,
      'address': address,
      'number_of_worker': numberOfWorker,
      'description_garage': descriptionGarage,
    };
    
    // Chỉ thêm các trường optional nếu có giá trị
    if (deviceId != null) data['device_id'] = deviceId;
    if (cccd != null) data['cccd'] = cccd;
    if (issueDate != null) data['issue_date'] = issueDate;
    if (signature != null) data['signature'] = signature;
    
    return data;
  }
}

class GarageRegisterResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final String? accessToken;
  final String? refreshToken;

  GarageRegisterResponse({
    required this.success,
    this.message,
    this.data,
    this.accessToken,
    this.refreshToken,
  });

  factory GarageRegisterResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return GarageRegisterResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: data,
      accessToken: data?['access_token'],
      refreshToken: data?['refresh_token'],
    );
  }
}

