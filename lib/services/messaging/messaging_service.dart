import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/models/messaging/messaging_models.dart';

class MessagingServiceApi {
  // Create room from request service
  static Future<CreateRoomResponse> createRoomFromRequest({
    required int requestServiceId,
  }) async {
    final body = {
      'request_service_id': requestServiceId,
    };

    final response = await BaseApiService.post(
      '/messaging/create-room-from-request',
      body: body,
    );
    
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

    return CreateRoomResponse(
      success: false,
      message: response['message'] ?? 'Lỗi tạo phòng chat',
      data: null,
    );
  }

  // Get list of chat rooms
  static Future<RoomListResponse> getRooms({
    int pageNum = 1,
    int pageSize = 10,
    String? keyword,
  }) async {
    final queryParams = <String, String>{
      'pagenum': pageNum.toString(),
      'pagesize': pageSize.toString(),
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword,
    };

    // Endpoint per latest spec (singular)
    final response = await BaseApiService.get(
      '/messaging/get-all-rooms',
      queryParams: queryParams,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return RoomListResponse.fromJson(data);
      }
    }

    // Fallback: return empty response
    return const RoomListResponse(
      rooms: [],
      pagination: PaginationInfo(
        currentPage: 1,
        perPage: 10,
        total: 0,
        totalPages: 0,
      ),
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
      if (startAfterOffset != null && startAfterOffset >= 0)
        'start_after': startAfterOffset.toString(),
    };

    final response = await BaseApiService.get(
      '/messaging/get-chat-room-detail/$roomId',
      queryParams: queryParams,
    );

    // Chỉ log thông tin cần thiết để debug thứ tự: last_message và messages[0]
    try {
      final data = response['data'] as Map<String, dynamic>?;
      final roomInfo = data?['room_info'] as Map<String, dynamic>?;
      final messagesList = (data?['messages'] as List<dynamic>? ?? []);
      final firstMessage = messagesList.isNotEmpty ? messagesList.first as Map<String, dynamic> : null;
      final lastMessage = messagesList.isNotEmpty ? messagesList.last as Map<String, dynamic> : null;
      // Log raw messages array để kiểm tra payload gốc trả về từ API
      DebugLogger.largeJson('[MessagingServiceApi.getRoomDetailWithMessages.messages_raw]', messagesList);
      DebugLogger.largeJson('[MessagingServiceApi.getRoomDetailWithMessages]', {
        'roomId': roomId,
        'queryParams': queryParams,
        'room_last_message': roomInfo?['last_message'],
        'room_last_message_time': roomInfo?['last_message_time'],
        'messages_len': messagesList.length,
        'messages0_id': firstMessage?['message_id'],
        'messages0_created_at': firstMessage?['created_at'],
        'messages_last_id': lastMessage?['message_id'],
        'messages_last_created_at': lastMessage?['created_at'],
      });
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

    final response = await BaseApiService.post(
      '/messaging/room/$roomId/send',
      body: body,
    );
    
    DebugLogger.largeJson('[MessagingServiceApi.sendMessage]', {
      'roomId': roomId,
      'body': body,
      'response': response,
    });

    if (response['success'] == true && response['data'] != null) {
      final messageData = MessageData.fromJson(response['data']);
      return SendMessageResponse(
        success: true,
        message: response['message'] ?? 'Gửi tin nhắn thành công',
        data: messageData,
      );
    }

    return SendMessageResponse(
      success: false,
      message: response['message'] ?? 'Lỗi gửi tin nhắn',
      data: null,
    );
  }

  // Mark message as read
  static Future<Map<String, dynamic>> markMessageRead({
    required String roomId,
    required String messageId,
  }) async {
    final response = await BaseApiService.put(
      '/messaging/room/$roomId/message/$messageId/read',
    );
    
    DebugLogger.largeJson('[MessagingServiceApi.markMessageRead]', {
      'roomId': roomId,
      'messageId': messageId,
      'response': response,
    });

    return response;
  }

  // Get unread count
  static Future<UnreadCountResponse> getUnreadCount() async {
    final response = await BaseApiService.get(
      '/messaging/unread-count',
    );
    
    DebugLogger.largeJson('[MessagingServiceApi.getUnreadCount]', {
      'response': response,
    });

    if (response['success'] == true && response['data'] != null) {
      return UnreadCountResponse(
        success: true,
        count: response['data']['count'] ?? 0,
      );
    }

    return UnreadCountResponse(
      success: false,
      count: 0,
    );
  }
}
