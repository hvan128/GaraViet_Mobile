import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/models/user/user_model.dart';
import 'package:gara/models/user/login_model.dart';
import 'package:gara/services/auth/jwt_token_manager.dart';
import 'package:gara/services/debug_helper.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/providers/user_provider.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AuthService {
  // User registration
  static Future<UserRegisterResponse> registerUser(UserRegisterRequest request) async {
    final response = await BaseApiService.post(
      '/auth/user-register-for-user',
      body: request.toJson(),
      includeAuth: false, // Registration doesn't need auth
    );

    return UserRegisterResponse(
      success: response['success'] ?? false,
      message: response['message'],
      data: response['data'],
    );
  }

  // User login
  static Future<UserLoginResponse> loginUser(UserLoginRequest request) async {
    // Log request (mask sensitive fields)
    final Map<String, dynamic> maskedBody = {
      ...request.toJson(),
      if (request.toJson().containsKey('password')) 'password': '******',
    };
    DebugHelper.logApiCall('POST', '/auth/user-login', body: maskedBody);

    final response = await BaseApiService.post(
      '/auth/user-login',
      body: request.toJson(),
      includeAuth: false, // Login doesn't need auth
    );

    // Log raw response for debugging
    DebugLogger.largeJson('LOGIN /auth/user-login RESPONSE', response);
    
    final loginResponse = UserLoginResponse.fromJson(response);
    
    // Nếu login thành công, lưu token và khởi tạo refresh timer
    if (loginResponse.success && loginResponse.accessToken != null) {
      await JwtTokenManager.saveNewTokens(
        accessToken: loginResponse.accessToken!,
        refreshToken: loginResponse.refreshToken,
      );
      
      // Initialize user provider với thông tin mới
      await UserProvider().initializeUserInfo();
    }
    
    return loginResponse;
  }

  // Refresh token
  static Future<Map<String, dynamic>> refreshToken() async {
    return await BaseApiService.post(
      '/auth/refresh-token',
      includeAuth: false, // Refresh token doesn't need auth
    );
  }

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    final response = await BaseApiService.post(
      '/auth/logout',
      includeAuth: true, // Logout needs auth
    );
    
    // Xóa token và hủy timer refresh
    await JwtTokenManager.clearTokens();
    
    // Clear user provider
    UserProvider().clearUserInfo();
    
    return response;
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    return await BaseApiService.post(
      '/auth/reset-password',
      body: {
        'phone': phone,
        'new_password': newPassword,
      },
      includeAuth: false, // Reset password doesn't need auth
    );
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
  }) async {
    DebugHelper.logApiCall('POST', '/auth/send-otp', body: {'phone': phone});
    
    final response = await BaseApiService.post(
      '/auth/send-otp',
      body: {
        'phone': phone,
      },
      includeAuth: false, // Send OTP doesn't need auth
    );
    
    DebugHelper.logApiResponse('/auth/send-otp', response);
    return response;
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String phone,
  }) async {
    DebugHelper.logApiCall('POST', '/auth/resend-otp', body: {'phone': phone});
    
    final response = await BaseApiService.post(
      '/auth/resend-otp',
      body: {
        'phone': phone,
      },
      includeAuth: false, // Resend OTP doesn't need auth
    );
    
    DebugHelper.logApiResponse('/auth/resend-otp', response);
    return response;
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    DebugHelper.logApiCall('POST', '/auth/verify-otp', body: {'phone': phone, 'otp_code': otp});
    
    final response = await BaseApiService.post(
      '/auth/verify-otp',
      body: {
        'phone': phone,
        'otp_code': otp,
      },
      includeAuth: false, // Verify OTP doesn't need auth
    );
    
    DebugHelper.logApiResponse('/auth/verify-otp', response);
    return response;
  }

  // Sign contract for garage (multipart/form-data)
  static Future<Map<String, dynamic>> signContractForGarage({
    required String idCardNumber,
    required String idCardIssuedDate, // yyyy-MM-dd
    required Uint8List signatureBytes,
  }) async {
    DebugHelper.logApiCall('POST', '/auth/sign-contract-for-garage', body: {
      'id_card_number': idCardNumber,
      'id_card_issued_date': idCardIssuedDate,
      'file': 'signature.png(bytes)',
    });

    final file = http.MultipartFile.fromBytes(
      'file',
      signatureBytes,
      filename: 'signature.png',
      contentType: MediaType('image', 'png'),
    );

    final response = await BaseApiService.postMultipartFormData(
      '/auth/sign-contract-for-garage',
      formData: {
        'id_card_number': idCardNumber,
        'id_card_issued_date': idCardIssuedDate,
      },
      files: [file],
      includeAuth: true,
    );

    DebugHelper.logApiResponse('/auth/sign-contract-for-garage', response);
    return response;
  }

  // Garage registration
  static Future<GarageRegisterResponse> registerGarage(
    GarageRegisterRequest request, {
    List<http.MultipartFile>? files,
  }) async {
    // Convert to form data for garage registration
    final formData = <String, String>{};
    final jsonData = request.toJson();
    
    // Convert all values to string for form data
    jsonData.forEach((key, value) {
      if (value != null) {
        formData[key] = value.toString();
      }
    });
    
    DebugHelper.logApiCall('POST', '/auth/user-register-for-garage', body: formData);
    
    // Debug: Log exact form data being sent
    DebugHelper.logError('Form Data Details', {
      'formData': formData,
      'formDataKeys': formData.keys.toList(),
      'formDataValues': formData.values.toList(),
    });
    
    // Try multipart form data first (as API spec shows formData)
    final response = await BaseApiService.postMultipartFormData(
      '/auth/user-register-for-garage',
      formData: formData,
      files: files,
      includeAuth: false, // Registration doesn't need auth
    );

    DebugHelper.logApiResponse('/auth/user-register-for-garage', response);
    final garageResponse = GarageRegisterResponse.fromJson(response);
    
    // Nếu đăng ký thành công, lưu token và khởi tạo refresh timer
    if (garageResponse.success && garageResponse.accessToken != null) {
      await JwtTokenManager.saveNewTokens(
        accessToken: garageResponse.accessToken!,
        refreshToken: garageResponse.refreshToken,
      );
      
      // Initialize user provider với thông tin mới
      await UserProvider().initializeUserInfo();
    }
    
    return garageResponse;
  }
}
