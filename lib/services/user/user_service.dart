import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gara/config.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/models/car/car_info_model.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/services/api/base_api_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gara/utils/debug_logger.dart';

class UserService {
  // Tạo custom HTTP client để bỏ qua SSL certificate verification
  static http.Client _createHttpClient() {
    return http.Client();
  }

  static Future<List<CarInfo>> getAllCars() async {
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
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      client.close();

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        Iterable listPayload = const [];
        if (decoded is List) {
          listPayload = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          listPayload = decoded['data'] as List;
        }
        return listPayload
            .whereType<dynamic>()
            .map((e) => CarInfo.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      debugPrint('[getAllCars] non-200 status=${response.statusCode} body=${response.body}');
      return [];
    } catch (e, st) {
      debugPrint('[getAllCars] error=$e\n$st');
      return [];
    }
  }

  static Future<CarInfo?> getCarById(String carId) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final client = _createHttpClient();
      final uri = Uri.parse('${Config.carGetByIdUrl}?car_id=$carId');
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'}).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      client.close();

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        DebugLogger.largeJson('[getCarById] response', decoded);
        Map<String, dynamic>? data;
        if (decoded is Map && decoded['data'] is Map) {
          data = Map<String, dynamic>.from(decoded['data']);
        } else if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          data = Map<String, dynamic>.from(decoded.first as Map);
        }
        if (data != null) {
          return CarInfo.fromJson(data);
        }
        return null;
      }
      debugPrint('[getCarById] non-200 status=${response.statusCode} body=${response.body}');
      return null;
    } catch (e, st) {
      debugPrint('[getCarById] error=$e\n$st');
      return null;
    }
  }

  static Future<bool> createRequest({
    required String carId,
    required String address,
    required String description,
    required String radiusSearch,
    String? latitude,
    String? longitude,
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
      if (latitude != null && latitude.isNotEmpty) {
        request.fields['latitude'] = latitude;
      }
      if (longitude != null && longitude.isNotEmpty) {
        request.fields['longitude'] = longitude;
      }

      if (files != null && files.isNotEmpty) {
        for (final f in files) {
          if (await f.exists()) {
            request.files.add(await http.MultipartFile.fromPath('files', f.path));
          }
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('[createRequest] fields=${request.fields}');
      debugPrint('[createRequest] status=${response.statusCode} body=${response.body}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, st) {
      debugPrint('[createRequest] error=$e\n$st');
      return false;
    }
  }

  static Future<bool> createCar({
    required String typeCar,
    required String yearModel,
    required String vehicleLicensePlate,
    required String description,
    List<File>? files,
  }) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final uri = Uri.parse(Config.carCreateUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['type_car'] = typeCar;
      request.fields['year_model'] = yearModel;
      request.fields['vehicle_license_plate'] = vehicleLicensePlate;
      request.fields['description'] = description;

      if (files != null && files.isNotEmpty) {
        for (final f in files) {
          if (await f.exists()) {
            request.files.add(await http.MultipartFile.fromPath('files', f.path));
          }
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('[createCar] status=${response.statusCode} body=${response.body}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, st) {
      debugPrint('[createCar] error=$e\n$st');
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

      debugPrint('[UserService.getUserInfo] GET: ${Config.userGetInfoUrl}');
      debugPrint(
          '[UserService.getUserInfo] Authorization: Bearer ${accessToken.substring(0, accessToken.length > 10 ? 10 : accessToken.length)}...');
      final response = await client.get(
        Uri.parse(Config.userGetInfoUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('[UserService.getUserInfo] Status: ${response.statusCode}');
      debugPrint('[UserService.getUserInfo] Body: ${response.body}');
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
        debugPrint('[UserService.getUserInfo] 404 Not Found. Body: ${response.body}');
        client.close();
        return null;
      } else {
        debugPrint('[UserService.getUserInfo] Non-200 Status: ${response.statusCode} Body: ${response.body}');
        client.close();
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu là SSL error, thử với HTTP thay vì HTTPS
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') || e.toString().contains('HandshakeException')) {
        debugPrint('[UserService.getUserInfo] SSL error detected, trying HTTP fallback... Error: $e');
        return await _getUserInfoWithHttpFallback();
      }

      debugPrint('[UserService.getUserInfo] Error: $e');
      return null;
    }
  }

  static Future<bool> deleteCar(String carId) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Chuyển đổi carId từ String sang int
      final int carIdInt = int.tryParse(carId) ?? 0;
      if (carIdInt == 0) {
        debugPrint('[deleteCar] Invalid carId: $carId');
        return false;
      }

      final client = _createHttpClient();
      final uri = Uri.parse(Config.carDeleteUrl);
      final response = await client
          .delete(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({'car_id': carIdInt}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      client.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint('[deleteCar] non-2xx status=${response.statusCode} body=${response.body}');
      return false;
    } catch (e, st) {
      debugPrint('[deleteCar] error=$e\n$st');
      return false;
    }
  }

  static Future<bool> uploadAvatar(File file) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        debugPrint('[UserService.uploadAvatar] No access token found');
        throw Exception('No access token found');
      }

      debugPrint('[UserService.uploadAvatar] Starting upload to: ${Config.userUploadAvatarUrl}');
      debugPrint('[UserService.uploadAvatar] File path: ${file.path}');
      debugPrint('[UserService.uploadAvatar] File exists: ${await file.exists()}');

      final uri = Uri.parse(Config.userUploadAvatarUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      debugPrint('[UserService.uploadAvatar] Sending request...');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('[UserService.uploadAvatar] Response status: ${response.statusCode}');
      debugPrint('[UserService.uploadAvatar] Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[UserService.uploadAvatar] Upload successful');
        return true;
      } else {
        debugPrint('[UserService.uploadAvatar] Upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[UserService.uploadAvatar] Error: $e');
      debugPrint('[UserService.uploadAvatar] Stack trace: $stackTrace');
      return false;
    }
  }

  // Fallback method sử dụng HTTP thay vì HTTPS với authentication flow
  static Future<UserInfoResponse?> _getUserInfoWithHttpFallback() async {
    try {
      // Sử dụng BaseApiService để có authentication flow đầy đủ
      final endpoint = Config.userGetInfoUrl.replaceFirst(Config.baseUrl, '');
      final httpEndpoint = endpoint.replaceFirst('https://', 'http://');

      debugPrint('[UserService._getUserInfoWithHttpFallback] GET: $httpEndpoint');
      final response = await BaseApiService.get(httpEndpoint, includeAuth: true);
      debugPrint('[UserService._getUserInfoWithHttpFallback] Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        return UserInfoResponse.fromJson(userData);
      }

      return null;
    } catch (e) {
      debugPrint('[UserService._getUserInfoWithHttpFallback] Error: $e');
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
        headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
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
        headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
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
      final request = http.MultipartRequest('PUT', Uri.parse(Config.userUpdateCertificateUrl));

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
      final request = http.MultipartRequest('PUT', Uri.parse(Config.userUpdateGarageRegisterAttachmentUrl));

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

  // Cập nhật thông tin xe
  static Future<bool> updateCar({
    required String carId,
    required String typeCar,
    required String yearModel,
    required String vehicleLicensePlate,
    required String description,
    required List<Map<String, dynamic>> currentFiles,
    List<File>? newFiles,
  }) async {
    try {
      final tokenFromCache = TokenCache.getAccessToken();
      final tokenFromStorage = await Storage.getAccessToken();
      final accessToken = tokenFromCache ?? tokenFromStorage;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final client = _createHttpClient();
      final request = http.MultipartRequest('PUT', Uri.parse('${Config.baseUrl}/manager-car/update-car'));

      // Headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Basic fields
      request.fields['car_id'] = carId;
      request.fields['type_car'] = typeCar;
      request.fields['year_model'] = yearModel;
      request.fields['vehicle_license_plate'] = vehicleLicensePlate;
      request.fields['description'] = description;

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

      debugPrint('[UserService.updateCar] Status: ${response.statusCode}');
      debugPrint('[UserService.updateCar] Response: $responseBody');
      debugPrint('[UserService.updateCar] URL: ${Config.baseUrl}/manager-car/update-car');
      debugPrint('[UserService.updateCar] Method: PUT');

      if (response.statusCode == 200) {
        debugPrint('[UserService.updateCar] Update successful');
        return true;
      } else {
        throw Exception('Lỗi cập nhật xe: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('[UserService.updateCar] Error: $e');
      return false;
    }
  }
}
