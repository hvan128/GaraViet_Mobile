List<UserInfoResponse> userInfoResponseFromJson(dynamic str) =>
    List<UserInfoResponse>.from(
      (str).map((x) => UserInfoResponse.fromJson(x)),
    );

class FileInfo {
  final int id;
  final String name;
  final String path;
  final String uploadTime;

  FileInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.uploadTime,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      uploadTime: json['upload_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'upload_time': uploadTime,
    };
  }
}

class UserInfoResponse {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String? avatar;
  final String? avatarPath; // New field from API
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
  final String? numberOfWorker;
  final String? descriptionGarage;
  final List<FileInfo>? listFileAvatar; // Changed to FileInfo objects
  final List<FileInfo>? listFileCertificate; // New field from API
  final int? isVerifiedGarage; // 0 INACTIVE, 1 ACTIVE, 2 PENDING
  final String? servicesProvided; // New field from API
  final String? activeFrom; // New field from API
  final int? numberOfCompletedOrders; // New field from API
  final double? starRatingStandard; // New field from API
  final int? warranty; // New field from API

  UserInfoResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.avatar,
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
    final normalizedName = roleId == 3
        ? (json['name_garage'] ?? json['name'] ?? '')
        : (json['name'] ?? '');

    return UserInfoResponse(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: normalizedName,
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
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
      address: json['address'],
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
      warranty: json['warranty'] is num
          ? (json['warranty'] as num).toInt()
          : int.tryParse('${json['warranty'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'avatar': avatar,
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
}
