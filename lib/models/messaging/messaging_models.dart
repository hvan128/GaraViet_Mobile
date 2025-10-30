import 'package:gara/models/request/request_service_model.dart';
import 'package:gara/models/quotation/quotation_model.dart';

class CreateRoomResponse {
  final bool success;
  final String message;
  final CreateRoomData? data;

  const CreateRoomResponse({required this.success, required this.message, this.data});
}

class CreateRoomData {
  final String roomId;
  final int requestServiceId;
  final int user1Id;
  final int user2Id;
  final String createdAt;
  final bool isActive;

  const CreateRoomData({
    required this.roomId,
    required this.requestServiceId,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.isActive,
  });

  factory CreateRoomData.fromJson(Map<String, dynamic> json) {
    return CreateRoomData(
      roomId: json['room_id'] ?? '',
      requestServiceId: json['request_service_id'] ?? 0,
      user1Id: json['user1_id'] ?? 0,
      user2Id: json['user2_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class RoomListResponse {
  final List<RoomData> rooms;
  final PaginationInfo pagination;

  const RoomListResponse({required this.rooms, required this.pagination});

  factory RoomListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json; // support both wrapped and flat
    final roomsList = data['rooms'] as List<dynamic>? ?? [];
    final rooms = roomsList.map((room) => RoomData.fromJson(room)).toList();
    final pagination = PaginationInfo.fromJson(data['pagination'] ?? {});
    return RoomListResponse(rooms: rooms, pagination: pagination);
  }
}

class RoomData {
  final String roomId;
  final int requestServiceId;
  final String? requestCode;
  final String? carInfo;
  final String? serviceDescription;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final String? status;
  final String? statusText;
  final String? price;
  final String? otherUserName;
  final String? otherUserAvatar;
  final RequestServiceModel? requestServiceInfo;
  final QuotationModel? quotationInfo;
  final int? messageStatus;

  const RoomData({
    required this.roomId,
    required this.requestServiceId,
    this.requestCode,
    this.carInfo,
    this.serviceDescription,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.status,
    this.statusText,
    this.price,
    this.otherUserName,
    this.otherUserAvatar,
    this.requestServiceInfo,
    this.quotationInfo,
    this.messageStatus,
  });

  factory RoomData.fromJson(Map<String, dynamic> json) {
    // Map new nested structure
    final requestInfo = json['request_service_info'] as Map<String, dynamic>?;
    final quotationInfoMap = json['quotation_info'] as Map<String, dynamic>?;

    String? computedCarInfo;
    if (requestInfo != null) {
      final type = requestInfo['car_type'];
      final year = requestInfo['car_year'];
      if (type != null && year != null) {
        computedCarInfo = '$type $year';
      } else if (type != null) {
        computedCarInfo = '$type';
      }
    }

    final priceString =
        quotationInfoMap != null && quotationInfoMap['price'] != null ? quotationInfoMap['price'].toString() : null;

    return RoomData(
      roomId: json['room_id'] ?? '',
      requestServiceId: json['request_service_id'] ?? requestInfo?['request_service_id'] ?? 0,
      requestCode: json['request_code'] ?? requestInfo?['request_code'],
      carInfo: json['car_info'] ?? computedCarInfo,
      serviceDescription: json['service_description'] ?? requestInfo?['description'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] ?? 0,
      status: json['status']?.toString() ?? requestInfo?['status']?.toString(),
      statusText: json['status_text'],
      price: json['price'] ?? priceString,
      otherUserName: json['other_user_name'] ?? json['garage_name'],
      otherUserAvatar: json['other_user_avatar'],
      requestServiceInfo: requestInfo != null ? RequestServiceModel.fromJson(requestInfo) : null,
      quotationInfo: quotationInfoMap != null ? QuotationModel.fromJson(quotationInfoMap) : null,
      messageStatus: int.tryParse((json['message_status'] ?? '').toString()),
    );
  }
}

class MessageListResponse {
  final List<MessageData> messages;
  final PaginationInfo pagination;

  const MessageListResponse({required this.messages, required this.pagination});

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesList.map((message) => MessageData.fromJson(message)).toList();
    final pagination = PaginationInfo.fromJson(json['pagination'] ?? {});
    return MessageListResponse(messages: messages, pagination: pagination);
  }
}

class MessageData {
  final String messageId;
  final String roomId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String message;
  final String createdAt;
  final bool isRead;
  final String? messageType;
  // URL file/hình ảnh nếu có (cho IMAGE/FILE)
  final String? fileUrl;
  // Thumbnail URLs cho video (các URL cách nhau dấu phẩy)
  final String? thumbnails;
  // Metadata bổ sung (ví dụ thông tin quotation/booking)
  final Map<String, dynamic>? metadata;

  const MessageData({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.messageType,
    this.fileUrl,
    this.thumbnails,
    this.metadata,
  });

  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      messageId: json['message_id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: int.tryParse((json['sender_id'] ?? 0).toString()) ?? 0,
      senderName: json['sender_name'] ?? json['other_user_name'] ?? '',
      senderAvatar: json['sender_avatar'],
      message: (json['content'] ?? json['message'] ?? '').toString(),
      createdAt: json['created_at'] ?? '',
      isRead: json['is_read'] ?? false,
      messageType: json['message_type']?.toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'])?.toString(),
      thumbnails: (json['thumbnail_url'] ?? json['thumbnails'])?.toString(),
      metadata: (json['metadata'] is Map<String, dynamic>) ? (json['metadata'] as Map<String, dynamic>) : null,
    );
  }
}

class SendMessageResponse {
  final bool success;
  final String message;
  final MessageData? data;

  const SendMessageResponse({required this.success, required this.message, this.data});
}

class UnreadCountResponse {
  final bool success;
  final int count;

  const UnreadCountResponse({required this.success, required this.count});
}

class PaginationInfo {
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;

  const PaginationInfo({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? json['page_num'] ?? 1,
      perPage: json['page_size'] ?? json['per_page'] ?? 10,
      total: json['total_items'] ?? json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

// Combined room detail + messages response
class RoomDetailResponse {
  final RoomData roomInfo;
  final List<MessageData> messages;
  final bool hasMore;
  final int count;

  const RoomDetailResponse({
    required this.roomInfo,
    required this.messages,
    required this.hasMore,
    required this.count,
  });

  factory RoomDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final roomInfoJson = data['room_info'] as Map<String, dynamic>? ?? {};
    final messagesList = data['messages'] as List<dynamic>? ?? [];
    return RoomDetailResponse(
      roomInfo: RoomData.fromJson(roomInfoJson),
      messages: messagesList.map((e) => MessageData.fromJson(e)).toList(),
      hasMore: data['has_more'] ?? false,
      count: data['count'] ?? (messagesList.length),
    );
  }
}

class DeleteRoomsResponse {
  final bool success;
  final String message;
  final int deletedCount;
  final int totalCount;
  final List<FailedRoom> failedRooms;

  // Flags để phân biệt các trường hợp
  final bool isFullySuccessful; // 3/3 - Xóa thành công hoàn toàn
  final bool isPartiallySuccessful; // 2/3 - Xóa thành công một phần
  final bool isBusinessRuleFailure; // 0/3 - Xóa thất bại do ràng buộc nghiệp vụ
  final bool isApiFailure; // API error (token, mạng, server)

  // Trường để xác định data có thay đổi không
  final bool hasDataChanged; // Có room nào được xóa thành công không

  const DeleteRoomsResponse({
    required this.success,
    required this.message,
    required this.deletedCount,
    required this.totalCount,
    required this.failedRooms,
    this.isFullySuccessful = false,
    this.isPartiallySuccessful = false,
    this.isBusinessRuleFailure = false,
    this.isApiFailure = false,
    this.hasDataChanged = false,
  });
}

class FailedRoom {
  final String roomId;
  final String error;

  const FailedRoom({required this.roomId, required this.error});

  factory FailedRoom.fromJson(Map<String, dynamic> json) {
    return FailedRoom(roomId: json['room_id'] ?? '', error: json['error'] ?? '');
  }
}
