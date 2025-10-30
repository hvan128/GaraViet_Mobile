import 'package:gara/models/file/file_info_model.dart';

List<UserInfoResponse> userInfoResponseFromJson(dynamic str) => List<UserInfoResponse>.from(
      (str).map((x) => UserInfoResponse.fromJson(x)),
    );

class UserInfoResponse {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String? avatarPath;
  final int roleId;
  final String roleCode;
  final String roleName;
  final bool isActive;
  final bool isPhoneVerified;
  final String deviceId;
  final String sessionId;
  final String createdAt;
  final String updatedAt;

  // Garage-specific (nullable for non-garage roles)
  final String? nameGarage;
  final String? emailGarage;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? numberOfWorker;
  final String? descriptionGarage;
  final List<FileInfo>? listFileAvatar;
  final List<FileInfo>? listFileCertificate;
  final int? isVerifiedGarage;
  final String? servicesProvided;
  final String? activeFrom;
  final int? numberOfCompletedOrders;
  final double? starRatingStandard;
  final int? warranty;

  UserInfoResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.avatarPath,
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    required this.isActive,
    required this.isPhoneVerified,
    required this.deviceId,
    required this.sessionId,
    required this.createdAt,
    required this.updatedAt,
    this.nameGarage,
    this.emailGarage,
    this.address,
    this.latitude,
    this.longitude,
    this.numberOfWorker,
    this.descriptionGarage,
    this.listFileAvatar,
    this.listFileCertificate,
    this.isVerifiedGarage,
    this.servicesProvided,
    this.activeFrom,
    this.numberOfCompletedOrders,
    this.starRatingStandard,
    this.warranty,
  });

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    List<FileInfo>? _parseFileList(dynamic list) {
      if (list is List) {
        return list.map((item) => FileInfo.fromJson(item)).toList();
      }
      return null;
    }

    final roleId = json['role_id'] ?? 0;
    final normalizedName = roleId == 3 ? (json['name_garage'] ?? json['name'] ?? '') : (json['name'] ?? '');

    final addressJson = json['address'];
    final address = addressJson is Map<String, dynamic> ? (addressJson['label'] ?? '') : (addressJson ?? '');
    // Chuẩn hóa latitude/longitude về chuỗi để tránh lỗi kiểu dữ liệu (server có thể trả double)
    String? _toStringOrNull(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    final latitude =
        addressJson is Map<String, dynamic> ? _toStringOrNull(addressJson['latitude']) : _toStringOrNull(addressJson);
    final longitude =
        addressJson is Map<String, dynamic> ? _toStringOrNull(addressJson['longitude']) : _toStringOrNull(addressJson);

    return UserInfoResponse(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: normalizedName,
      phone: json['phone'] ?? '',
      avatarPath: json['avatar_path'],
      roleId: roleId,
      roleCode: json['role_code'] ?? '',
      roleName: json['role_name'] ?? '',
      isActive: _toBool(json['is_active']),
      isPhoneVerified: _toBool(json['is_phone_verified']),
      deviceId: json['device_id'] ?? '',
      sessionId: json['session_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      nameGarage: json['name_garage'],
      emailGarage: json['email_garage'],
      address: address,
      latitude: latitude,
      longitude: longitude,
      numberOfWorker: json['number_of_worker']?.toString(),
      descriptionGarage: json['description_garage'],
      listFileAvatar: _parseFileList(json['list_file_avatar']),
      listFileCertificate: _parseFileList(json['list_file_certificate']),
      isVerifiedGarage: json['isVerifiedGarage'] is num
          ? (json['isVerifiedGarage'] as num).toInt()
          : int.tryParse('${json['isVerifiedGarage'] ?? ''}'),
      servicesProvided: json['services_provided'],
      activeFrom: json['active_from'],
      numberOfCompletedOrders: json['number_of_completed_orders'] is num
          ? (json['number_of_completed_orders'] as num).toInt()
          : int.tryParse('${json['number_of_completed_orders'] ?? ''}'),
      starRatingStandard: json['star_rating_standard'] is num
          ? (json['star_rating_standard'] as num).toDouble()
          : double.tryParse('${json['star_rating_standard'] ?? ''}'),
      warranty: json['warranty'] is num ? (json['warranty'] as num).toInt() : int.tryParse('${json['warranty'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'avatar_path': avatarPath,
      'role_id': roleId,
      'role_code': roleCode,
      'role_name': roleName,
      'is_active': isActive,
      'is_phone_verified': isPhoneVerified,
      'device_id': deviceId,
      'session_id': sessionId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'name_garage': nameGarage,
      'email_garage': emailGarage,
      'address': address,
      'number_of_worker': numberOfWorker,
      'description_garage': descriptionGarage,
      'list_file_avatar': listFileAvatar?.map((e) => e.toJson()).toList(),
      'list_file_certificate': listFileCertificate?.map((e) => e.toJson()).toList(),
      'isVerifiedGarage': isVerifiedGarage,
      'services_provided': servicesProvided,
      'active_from': activeFrom,
      'number_of_completed_orders': numberOfCompletedOrders,
      'star_rating_standard': starRatingStandard,
      'warranty': warranty,
    };
  }

  /// Tạo bản copy với các field được cập nhật
  UserInfoResponse copyWith({
    int? id,
    int? userId,
    String? name,
    String? phone,
    String? avatarPath,
    int? roleId,
    String? roleCode,
    String? roleName,
    bool? isActive,
    bool? isPhoneVerified,
    String? deviceId,
    String? sessionId,
    String? createdAt,
    String? updatedAt,
    String? nameGarage,
    String? emailGarage,
    String? address,
    String? latitude,
    String? longitude,
    String? numberOfWorker,
    String? descriptionGarage,
    List<FileInfo>? listFileAvatar,
    List<FileInfo>? listFileCertificate,
    int? isVerifiedGarage,
    String? servicesProvided,
    String? activeFrom,
    int? numberOfCompletedOrders,
    double? starRatingStandard,
    int? warranty,
  }) {
    return UserInfoResponse(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      roleId: roleId ?? this.roleId,
      roleCode: roleCode ?? this.roleCode,
      roleName: roleName ?? this.roleName,
      isActive: isActive ?? this.isActive,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nameGarage: nameGarage ?? this.nameGarage,
      emailGarage: emailGarage ?? this.emailGarage,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      numberOfWorker: numberOfWorker ?? this.numberOfWorker,
      descriptionGarage: descriptionGarage ?? this.descriptionGarage,
      listFileAvatar: listFileAvatar ?? this.listFileAvatar,
      listFileCertificate: listFileCertificate ?? this.listFileCertificate,
      isVerifiedGarage: isVerifiedGarage ?? this.isVerifiedGarage,
      servicesProvided: servicesProvided ?? this.servicesProvided,
      activeFrom: activeFrom ?? this.activeFrom,
      numberOfCompletedOrders: numberOfCompletedOrders ?? this.numberOfCompletedOrders,
      starRatingStandard: starRatingStandard ?? this.starRatingStandard,
      warranty: warranty ?? this.warranty,
    );
  }
}
