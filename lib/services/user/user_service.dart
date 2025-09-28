 import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gara/config.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UserService {
  // Tạo custom HTTP client để bỏ qua SSL certificate verification
  static http.Client _createHttpClient() {
    return http.Client();
  }

  static Future<List<Map<String, dynamic>>> getAllCars() async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final client = _createHttpClient();
      final response = await client.get(
        Uri.parse(Config.carGetAllUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timeout');
      });

      client.close();

      if (response.statusCode == 200) {
        debugPrint('[getAllCars] status=200 body=${response.body}');
        final decoded = json.decode(response.body);
        if (decoded is List) {
          debugPrint('[getAllCars] decoded List length=${decoded.length}');
          return List<Map<String, dynamic>>.from(decoded.map((e) => Map<String, dynamic>.from(e)));
        }
        if (decoded is Map && decoded['data'] is List) {
          debugPrint('[getAllCars] decoded Map.data length=${(decoded['data'] as List).length}');
          return List<Map<String, dynamic>>.from((decoded['data'] as List).map((e) => Map<String, dynamic>.from(e)));
        }
        debugPrint('[getAllCars] Unexpected payload type: ${decoded.runtimeType}');
        return [];
      }
      debugPrint('[getAllCars] non-200 status=${response.statusCode} body=${response.body}');
      return [];
    } catch (e, st) {
      debugPrint('[getAllCars] error=$e\n$st');
      return [];
    }
  }

  static Future<bool> createRequest({
    required String carId,
    required String address,
    required String description,
    required String radiusSearch,
    List<File>? files,
  }) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final uri = Uri.parse(Config.requestCreateUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['car_id'] = carId;
      request.fields['address'] = address;
      request.fields['description'] = description;
      request.fields['radius_search'] = radiusSearch;

      if (files != null && files.isNotEmpty) {
        for (final f in files) {
          if (await f.exists()) {
            request.files.add(await http.MultipartFile.fromPath('files', f.path));
          }
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('[createRequest] status=${response.statusCode} body=${response.body}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, st) {
      debugPrint('[createRequest] error=$e\n$st');
      return false;
    }
  }

  static Future<UserInfoResponse?> getUserInfo() async {
    try {
      // Try TokenCache first, then Storage as fallback
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Tạo custom HTTP client để handle SSL issues
      final client = _createHttpClient();
      
      final response = await client.get(
        Uri.parse(Config.userGetInfoUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        Map<String, dynamic>? userData;

        // 1) { success: true, data: {...} }
        if (decoded is Map && decoded['data'] is Map) {
          userData = Map<String, dynamic>.from(decoded['data']);
        }
        // 2) { ...fields } trực tiếp
        else if (decoded is Map) {
          userData = Map<String, dynamic>.from(decoded);
        }
        // 3) [ {...} ]
        else if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          userData = Map<String, dynamic>.from(decoded.first as Map);
        }

        if (userData != null) {
          final userInfo = UserInfoResponse.fromJson(userData);
          client.close();
          return userInfo;
        }

        client.close();
        return null;
      } else if (response.statusCode == 404) {
        client.close();
        return null;
      } else {
        client.close();
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu là SSL error, thử với HTTP thay vì HTTPS
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') || 
          e.toString().contains('HandshakeException')) {
        return await _getUserInfoWithHttpFallback();
      }
      
      return null;
    }
  }

  static Future<bool> uploadAvatar(File file) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final uri = Uri.parse(Config.userUploadAvatarUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Fallback method sử dụng HTTP thay vì HTTPS
  static Future<UserInfoResponse?> _getUserInfoWithHttpFallback() async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      
      if (accessToken == null) {
        return null;
      }

      // Thay HTTPS bằng HTTP
      final httpUrl = Config.userGetInfoUrl.replaceFirst('https://', 'http://');
      
      final client = _createHttpClient();
      
      final response = await client.get(
        Uri.parse(httpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        Map<String, dynamic>? userData;

        if (decoded is Map && decoded['data'] is Map) {
          userData = Map<String, dynamic>.from(decoded['data']);
        } else if (decoded is Map) {
          userData = Map<String, dynamic>.from(decoded);
        } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          userData = Map<String, dynamic>.from(decoded.first as Map);
        }

        if (userData != null) {
          final userInfo = UserInfoResponse.fromJson(userData);
          client.close();
          return userInfo;
        }

        client.close();
        return null;
      } else if (response.statusCode == 404) {
        client.close();
        return null;
      } else {
        client.close();
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Cập nhật thông tin user thường
  static Future<void> updateUserInfo(Map<String, dynamic> updateData) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;

      if (accessToken == null) {
        throw Exception('Không tìm thấy access token');
      }

      final client = _createHttpClient();
      final response = await client.put(
        Uri.parse(Config.userUpdateInfoUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      debugPrint('[UserService.updateUserInfo] Status: ${response.statusCode}');
      debugPrint('[UserService.updateUserInfo] Response: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('[UserService.updateUserInfo] Update successful');
      } else {
        throw Exception('Lỗi cập nhật thông tin: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[UserService.updateUserInfo] Error: $e');
      rethrow;
    }
  }

  // Cập nhật thông tin gara
  static Future<void> updateGarageInfo(Map<String, dynamic> updateData) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;

      if (accessToken == null) {
        throw Exception('Không tìm thấy access token');
      }

      final client = _createHttpClient();
      final response = await client.put(
        Uri.parse(Config.userUpdateGarageUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      debugPrint('[UserService.updateGarageInfo] Status: ${response.statusCode}');
      debugPrint('[UserService.updateGarageInfo] Response: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('[UserService.updateGarageInfo] Update successful');
      } else {
        throw Exception('Lỗi cập nhật thông tin gara: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[UserService.updateGarageInfo] Error: $e');
      rethrow;
    }
  }

  // Cập nhật chứng chỉ gara
  static Future<void> updateGarageCertificate({
    required List<Map<String, dynamic>> currentFiles,
    List<File>? newFiles,
  }) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;

      if (accessToken == null) {
        throw Exception('Không tìm thấy access token');
      }

      final client = _createHttpClient();
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(Config.userUpdateCertificateUrl),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Current files
      request.fields['current_files'] = jsonEncode(currentFiles);

      // New files
      if (newFiles != null && newFiles.isNotEmpty) {
        for (int i = 0; i < newFiles.length; i++) {
          final file = newFiles[i];
          final multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();

      debugPrint('[UserService.updateGarageCertificate] Status: ${response.statusCode}');
      debugPrint('[UserService.updateGarageCertificate] Response: $responseBody');
      debugPrint('[UserService.updateGarageCertificate] URL: ${Config.userUpdateCertificateUrl}');
      debugPrint('[UserService.updateGarageCertificate] Method: PUT');

      if (response.statusCode == 200) {
        debugPrint('[UserService.updateGarageCertificate] Update successful');
      } else {
        throw Exception('Lỗi cập nhật chứng chỉ: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('[UserService.updateGarageCertificate] Error: $e');
      rethrow;
    }
  }

  // Cập nhật file đăng ký gara
  static Future<void> updateGarageRegisterAttachment({
    required List<Map<String, dynamic>> currentFiles,
    List<File>? newFiles,
  }) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;

      if (accessToken == null) {
        throw Exception('Không tìm thấy access token');
      }

      final client = _createHttpClient();
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(Config.userUpdateGarageRegisterAttachmentUrl),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Current files
      request.fields['current_files'] = jsonEncode(currentFiles);

      // New files
      if (newFiles != null && newFiles.isNotEmpty) {
        for (int i = 0; i < newFiles.length; i++) {
          final file = newFiles[i];
          final multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();

      debugPrint('[UserService.updateGarageRegisterAttachment] Status: ${response.statusCode}');
      debugPrint('[UserService.updateGarageRegisterAttachment] Response: $responseBody');
      debugPrint('[UserService.updateGarageRegisterAttachment] URL: ${Config.userUpdateGarageRegisterAttachmentUrl}');
      debugPrint('[UserService.updateGarageRegisterAttachment] Method: PUT');

      if (response.statusCode == 200) {
        debugPrint('[UserService.updateGarageRegisterAttachment] Update successful');
      } else {
        throw Exception('Lỗi cập nhật file đăng ký: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('[UserService.updateGarageRegisterAttachment] Error: $e');
      rethrow;
    }
  }
}