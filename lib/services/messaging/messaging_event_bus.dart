import 'dart:async';

/// Sự kiện khi nhận tin nhắn mới qua FCM (hoặc các nguồn realtime khác)
class NewChatMessageEvent {
  final String roomId;
  final String messageId;
  final int senderId;
  final String senderName;
  final String content;
  final String createdAt;
  final String? messageType; // '1'=TEXT, '2'=IMAGE, ...
  final Map<String, dynamic>? metadata; // Thông tin mở rộng (booking/quotation...)
  final int? messageStatus; // Trạng thái tin nhắn (ví dụ: sent/delivered/read)

  NewChatMessageEvent({
    required this.roomId,
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.messageType,
    this.metadata,
    this.messageStatus,
  });
}

/// Event bus tối giản cho messaging
class MessagingEventBus {
  MessagingEventBus._();

  static final MessagingEventBus _instance = MessagingEventBus._();
  factory MessagingEventBus() => _instance;

  final StreamController<NewChatMessageEvent> _newMessageController =
      StreamController<NewChatMessageEvent>.broadcast();

  Stream<NewChatMessageEvent> get onNewMessage => _newMessageController.stream;

  void emitNewMessage(NewChatMessageEvent event) {
    if (!_newMessageController.isClosed) {
      _newMessageController.add(event);
    }
  }

  // Phát sự kiện danh sách phòng thay đổi (không có push realtime)
  final StreamController<void> _roomsDirtyController =
      StreamController<void>.broadcast();

  Stream<void> get onRoomsDirty => _roomsDirtyController.stream;

  void emitRoomsDirty() {
    if (!_roomsDirtyController.isClosed) {
      _roomsDirtyController.add(null);
    }
  }

  void dispose() {
    _newMessageController.close();
    _roomsDirtyController.close();
  }
}


