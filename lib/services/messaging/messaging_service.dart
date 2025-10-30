import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/models/messaging/messaging_models.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/config.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class MessagingServiceApi {
  // Create room from request service
  static Future<CreateRoomResponse> createRoomFromRequest({required int requestServiceId}) async {
    final body = {'request_service_id': requestServiceId};

    final response = await BaseApiService.post('/messaging/create-room-from-request', body: body);

    DebugLogger.largeJson('[MessagingServiceApi.createRoomFromRequest]', {
      'requestServiceId': requestServiceId,
      'response': response,
    });

    if (response['success'] == true && response['data'] != null) {
      final roomData = CreateRoomData.fromJson(response['data']);
      return CreateRoomResponse(
        success: true,
        message: response['message'] ?? 'Tạo phòng chat thành công',
        data: roomData,
      );
    }

    return CreateRoomResponse(success: false, message: response['message'] ?? 'Lỗi tạo phòng chat', data: null);
  }

  // Get list of chat rooms
  static Future<RoomListResponse> getRooms({
    int pageNum = 1,
    int pageSize = 10,
    String? keyword,
    String? statusCsv,
  }) async {
    final queryParams = <String, String>{
      'pagenum': pageNum.toString(),
      'pagesize': pageSize.toString(),
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword,
      if (statusCsv != null && statusCsv.trim().isNotEmpty) 'status': statusCsv,
    };

    // Endpoint per latest spec (singular)
    final response = await BaseApiService.get('/messaging/get-all-rooms', queryParams: queryParams);

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return RoomListResponse.fromJson(data);
      }
    }

    // Fallback: return empty response
    return const RoomListResponse(
      rooms: [],
      pagination: PaginationInfo(currentPage: 1, perPage: 10, total: 0, totalPages: 0),
    );
  }

  // Get room detail with messages (limit, start_after)
  static Future<RoomDetailResponse?> getRoomDetailWithMessages({
    required String roomId,
    int limit = 50,
    int? startAfterOffset,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (startAfterOffset != null && startAfterOffset >= 0) 'start_after': startAfterOffset.toString(),
    };

    final response = await BaseApiService.get('/messaging/get-chat-room-detail/$roomId', queryParams: queryParams);

    // Chỉ log thông tin cần thiết để debug thứ tự: last_message và messages[0]
    try {
      final data = response['data'] as Map<String, dynamic>?;
      final messagesList = (data?['messages'] as List<dynamic>? ?? []);

      // Log raw messages array để kiểm tra payload gốc trả về từ API
      DebugLogger.largeJson('[MessagingServiceApi.getRoomDetailWithMessages.messages_raw]', messagesList);
    } catch (_) {
      DebugLogger.largeJson('[MessagingServiceApi.getRoomDetailWithMessages]', {
        'roomId': roomId,
        'queryParams': queryParams,
        'log': 'parse-log-failed',
      });
    }

    if (response['success'] == true && response['data'] != null) {
      return RoomDetailResponse.fromJson(response);
    }

    return null;
  }

  // Send message in a room
  static Future<SendMessageResponse> sendMessage({
    required String roomId,
    required String message,
    int messageType = 1, // 1: TEXT (default)
    String? fileUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'message_type': messageType,
      if (fileUrl != null && fileUrl.isNotEmpty) 'file_url': fileUrl,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };

    final response = await BaseApiService.post('/messaging/room/$roomId/send', body: body);

    // DebugLogger.largeJson('[MessagingServiceApi.sendMessage]', {'roomId': roomId, 'body': body, 'response': response});

    if (response['success'] == true && response['data'] != null) {
      final messageData = MessageData.fromJson(response['data']);
      return SendMessageResponse(
        success: true,
        message: response['message'] ?? 'Gửi tin nhắn thành công',
        data: messageData,
      );
    }

    return SendMessageResponse(success: false, message: response['message'] ?? 'Lỗi gửi tin nhắn', data: null);
  }

  // Send media files (images/videos) in a room
  static Future<SendMessageResponse> sendMedia({
    required String roomId,
    required List<File> files,
    required int messageType, // 2: IMAGE, 3: VIDEO
    List<File>? thumbnails, // Optional thumbnails for videos
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // Get access token
        final tokenFromCache = TokenCache.getAccessToken();
        final tokenFromStorage = await Storage.getAccessToken();
        final accessToken = tokenFromCache ?? tokenFromStorage;
        if (accessToken == null) {
          throw Exception('No access token found');
        }

        // Create multipart request
        final uri = Uri.parse('${Config.baseUrl}/messaging/room/$roomId/send-media');
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $accessToken';
        request.fields['message_type'] = messageType.toString();

        // Add files
        for (final file in files) {
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath('files', file.path));
          }
        }

        // Add thumbnails for videos
        if (thumbnails != null && thumbnails.isNotEmpty) {
          for (final thumbnail in thumbnails) {
            if (await thumbnail.exists()) {
              request.files.add(await http.MultipartFile.fromPath('thumbnails', thumbnail.path));
            }
          }
        }

        // Send request
        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);

        // Check if response is HTML (server error page)
        if (response.body.trim().startsWith('<html>') || response.body.trim().startsWith('<!DOCTYPE')) {
          DebugLogger.log(
            '[MessagingServiceApi.sendMedia] Server returned HTML instead of JSON, body: ${response.body}',
          );
          return SendMessageResponse(
            success: false,
            message: 'Server đang bảo trì hoặc có lỗi. Vui lòng thử lại sau.',
            data: null,
          );
        }

        // Parse response
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          DebugLogger.log('[MessagingServiceApi.sendMedia] JSON parse error: $e');
          return SendMessageResponse(
            success: false,
            message: 'Lỗi định dạng phản hồi từ server. Vui lòng thử lại.',
            data: null,
          );
        }

        DebugLogger.largeJson('[MessagingServiceApi.sendMedia]', {
          'roomId': roomId,
          'messageType': messageType,
          'fileCount': files.length,
          'statusCode': response.statusCode,
          'response': responseData,
        });

        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            responseData['success'] == true &&
            responseData['data'] != null) {
          final messageData = MessageData.fromJson(responseData['data']);
          return SendMessageResponse(
            success: true,
            message: responseData['message'] ?? 'Gửi media thành công',
            data: messageData,
          );
        }

        return SendMessageResponse(success: false, message: responseData['message'] ?? 'Lỗi gửi media', data: null);
      } catch (e) {
        DebugLogger.largeJson('[MessagingServiceApi.sendMedia] error [${attempt + 1}]', {'error': e.toString()});

        // Nếu là lần thử cuối, trả về lỗi
        if (attempt == maxRetries) {
          return SendMessageResponse(success: false, message: 'Lỗi gửi media: ${e.toString()}', data: null);
        }

        // Delay trước khi thử lại (exponential backoff)
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        continue;
      }
    }

    // Nếu tất cả lần thử đều thất bại
    return SendMessageResponse(
      success: false,
      message: 'Không thể gửi media sau ${maxRetries + 1} lần thử',
      data: null,
    );
  }

  // Mark message as read
  static Future<Map<String, dynamic>> markMessageRead({required String roomId, required String messageId}) async {
    final response = await BaseApiService.put('/messaging/room/$roomId/message/$messageId/read');

    DebugLogger.largeJson('[MessagingServiceApi.markMessageRead]', {
      'roomId': roomId,
      'messageId': messageId,
      'response': response,
    });

    return response;
  }

  // Get unread count
  static Future<UnreadCountResponse> getUnreadCount() async {
    final response = await BaseApiService.get('/messaging/unread-count');

    DebugLogger.largeJson('[MessagingServiceApi.getUnreadCount]', {'response': response});

    if (response['success'] == true && response['data'] != null) {
      return UnreadCountResponse(success: true, count: response['data']['count'] ?? 0);
    }

    return UnreadCountResponse(success: false, count: 0);
  }

  // Delete rooms
  static Future<DeleteRoomsResponse> deleteRooms({required List<String> roomIds}) async {
    final body = {'room_ids': roomIds};

    final response = await BaseApiService.delete('/messaging/delete-room', body: body);

    // Parse response structure - sau khi sửa AuthHttpClient, chỉ còn cấu trúc đơn giản
    if (response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;

      final deletedCount = data['deleted_count'] ?? 0;
      final totalCount = data['total_count'] ?? 0;
      final failedRooms = (data['failed_rooms'] as List<dynamic>? ?? [])
          .map((item) => FailedRoom.fromJson(item as Map<String, dynamic>))
          .toList();

      // Phân biệt các trường hợp:
      // 1. Xóa thành công hoàn toàn (3/3)
      // 2. Xóa thành công một phần (2/3)
      // 3. Xóa thất bại do ràng buộc (0/3)
      final isFullySuccessful = deletedCount == totalCount && totalCount > 0;
      final isPartiallySuccessful = deletedCount > 0 && deletedCount < totalCount;
      final isBusinessRuleFailure = deletedCount == 0 && totalCount > 0;

      // Xác định data có thay đổi không
      final hasDataChanged = (data['has_data_changed'] ?? false) || (deletedCount > 0);

      return DeleteRoomsResponse(
        success: true, // API call thành công (có response data)
        message: response['message'] ?? 'Xóa phòng chat',
        deletedCount: deletedCount,
        totalCount: totalCount,
        failedRooms: failedRooms,
        isFullySuccessful: isFullySuccessful,
        isPartiallySuccessful: isPartiallySuccessful,
        isBusinessRuleFailure: isBusinessRuleFailure,
        hasDataChanged: hasDataChanged,
      );
    }

    // Phân biệt API failure vs business rule failure
    final isApiFailure = response['success'] == false && response['data'] == null;
    final isBusinessRuleFailure = response['success'] == false && response['data'] != null;

    return DeleteRoomsResponse(
      success: false,
      message: response['message'] ?? 'Lỗi xóa phòng chat',
      deletedCount: 0,
      totalCount: 0,
      failedRooms: [],
      isApiFailure: isApiFailure,
      isBusinessRuleFailure: isBusinessRuleFailure,
    );
  }
}
