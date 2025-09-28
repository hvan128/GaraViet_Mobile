class UserLoginRequest {
  final String phone;
  final String password;
  final String deviceId;
  final bool rememberMe;

  UserLoginRequest({
    required this.phone,
    required this.password,
    required this.deviceId,
    required this.rememberMe,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'password': password,
      'device_id': deviceId,
      'remember_me': rememberMe,
    };
  }
}

class UserLoginResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final String? accessToken;
  final String? refreshToken;

  UserLoginResponse({
    required this.success,
    this.message,
    this.data,
    this.accessToken,
    this.refreshToken,
  });

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      accessToken: json['data']?['access_token'],
      refreshToken: json['data']?['refresh_token'],
    );
  }
}
