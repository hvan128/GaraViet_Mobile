import 'package:flutter/foundation.dart';

/// Theo dõi phòng chat hiện người dùng đang mở để quyết định
/// có hiển thị local notification hay chỉ cập nhật UI realtime.
class ChatPresence {
  ChatPresence._();

  static final ValueNotifier<String?> currentRoomIdNotifier =
      ValueNotifier<String?>(null);

  static String? get currentRoomId => currentRoomIdNotifier.value;

  static void enterRoom(String roomId) {
    if (currentRoomIdNotifier.value != roomId) {
      currentRoomIdNotifier.value = roomId;
    }
  }

  static void leaveRoom(String roomId) {
    if (currentRoomIdNotifier.value == roomId) {
      currentRoomIdNotifier.value = null;
    }
  }

  static void clear() {
    currentRoomIdNotifier.value = null;
  }
}


