import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notification_service.dart';
import 'chat_presence.dart';
import 'messaging_event_bus.dart';
import 'navigation_event_bus.dart';
import 'package:gara/navigation/navigation.dart';

class PushNotificationService {
  static bool _initialized = false;
  static Future<void>? _initializationFuture;

  static Future<void> initialize() async {
    
    if (_initialized) {
      return;
    }
    
    // Nếu đang khởi tạo, đợi kết quả của lần khởi tạo đó
    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }
    
    // Tạo future khởi tạo và lưu lại
    _initializationFuture = _performInitialization();
    await _initializationFuture;
  }

  // In ra payload thô của RemoteMessage cho mục đích debug (mọi trạng thái)
  static void _logRawMessage(RemoteMessage message, String contextLabel) {
    try {
      final payload = {
        'context': contextLabel,
        'data': message.data,
        'notification': {
          'title': message.notification?.title,
          'body': message.notification?.body,
        },
        'sentTime': message.sentTime?.toIso8601String(),
        'messageId': message.messageId,
      };
      // Sử dụng DebugLogger nếu có sẵn
      // ignore: avoid_print
      print('[PushNotificationService] RAW ${contextLabel}: ' + payload.toString());
    } catch (_) {
      // ignore: avoid_print
      print('[PushNotificationService] RAW ${contextLabel}: <log-failed>');
    }
  }

  static Future<void> _performInitialization() async {
    try {
      await Firebase.initializeApp();

      // Khởi tạo local notification service
      await LocalNotificationService.initialize();

      final messaging = FirebaseMessaging.instance;
      
      // Kiểm tra và xin quyền
      if (Platform.isIOS) {
        await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        await messaging.getNotificationSettings();
        // Android 13+: cần xin quyền POST_NOTIFICATIONS nếu chưa được cấp
        try {
          await LocalNotificationService.requestPermissionsIfNeeded();
        } catch (e) {
        }
      }

      // Xử lý foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Xử lý khi user tap vào notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Kiểm tra notification khi app khởi động (từ terminated state)
      await _checkInitialMessage();

      // Background handler - chỉ dùng cho data-only messages
      // Custom service sẽ xử lý notification payload khi app terminated
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _initialized = true;
      
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getFcmTokenSafely() async {
    try {
      // Chỉ initialize nếu chưa được khởi tạo
      if (!_initialized) {
        await initialize();
      }
      
      final token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  // Kiểm tra notification khi app khởi động từ terminated state
  static Future<void> _checkInitialMessage() async {
    try {
      
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      
      if (initialMessage != null) {
        _logRawMessage(initialMessage, 'INITIAL');
        
        // Xử lý navigation nếu cần
        await _handleNotificationTap(initialMessage);
      } else {
      }
    } catch (e) {
    }
  }

  // Xử lý message khi app đang ở foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logRawMessage(message, 'FOREGROUND');
    
    try {
      final data = message.data;
      final typeRaw = (data['type'] ?? '').toString().trim();
      final actionRaw = (data['action'] ?? '').toString().trim();
      final subtype = (data['subtype'] ?? data['messageType'] ?? '').toString().trim();
      final roomId = (data['room_id'] ?? data['roomId'] ?? data['roomID'] ?? data['room_id_str'] ?? '').toString().trim();
      final isChat = roomId.isNotEmpty || typeRaw == 'chat' || actionRaw == 'new_message';
      String messageId = (data['message_id'] ?? data['messageId'] ?? '').toString().trim();
      final senderIdStr = (data['sender_id'] ?? data['senderId'] ?? '0').toString().trim();
      final senderId = int.tryParse(senderIdStr) ?? 0;
      final senderName = (data['sender_name'] ?? data['senderName'] ?? '').toString().trim();
      final msgContent = (data['message'] ?? data['content'] ?? message.notification?.body ?? '').toString();
      // timestamp (millis) -> ISO8601
      final tsRaw = (data['timestamp'] ?? '').toString();
      String createdAt;
      if (tsRaw.isNotEmpty) {
        final millis = int.tryParse(tsRaw);
        if (millis != null) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toIso8601String();
        } else {
          createdAt = message.sentTime?.toIso8601String() ?? DateTime.now().toIso8601String();
        }
      } else {
        createdAt = message.sentTime?.toIso8601String() ?? DateTime.now().toIso8601String();
      }

      // Fallback messageId nếu thiếu/rỗng để tránh bỏ qua thêm vào UI
      if (messageId.isEmpty) {
        final tsPart = tsRaw.isNotEmpty ? tsRaw : DateTime.now().millisecondsSinceEpoch.toString();
        messageId = 'fcm-$tsPart-$senderId';
      }

      // Parse metadata & message status nếu có trong payload
      final Map<String, dynamic>? metadata = (() {
        final raw = data['metadata'];
        if (raw is Map<String, dynamic>) return raw;
        return null;
      })();
      final int? messageStatus = () {
        final raw = data['message_status'] ?? data['messageStatus'];
        if (raw == null) return null;
        final parsed = int.tryParse(raw.toString());
        return parsed;
      }();

      // Nếu là tin nhắn chat và đang mở đúng phòng -> phát sự kiện, KHÔNG hiện local notification
      if (isChat && roomId.isNotEmpty && ChatPresence.currentRoomId == roomId) {
        try {
          final log = {
            'where': 'FOREGROUND_IN_ROOM',
            'roomId': roomId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'messageType': subtype,
            'createdAt': createdAt,
          };
          // ignore: avoid_print
          print('[PushNotificationService] NewChatMessageEvent ' + log.toString());
        } catch (_) {}
        MessagingEventBus().emitNewMessage(NewChatMessageEvent(
          roomId: roomId,
          messageId: messageId,
          senderId: senderId,
          senderName: senderName,
          content: msgContent,
          createdAt: createdAt,
          messageType: subtype.isNotEmpty ? subtype : (message.data['message_type']?.toString() ?? data['messageType']?.toString()),
          metadata: metadata,
          messageStatus: messageStatus,
        ));
        return;
      }

      if (isChat && roomId.isNotEmpty && ChatPresence.currentRoomId != roomId) {
        // Phát sự kiện để màn danh sách phòng cập nhật realtime (reorder + unread)
        try {
          final log = {
            'where': 'FOREGROUND_OTHER_ROOM',
            'roomId': roomId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'messageType': subtype,
            'createdAt': createdAt,
          };
          // ignore: avoid_print
          print('[PushNotificationService] NewChatMessageEvent ' + log.toString());
        } catch (_) {}
        MessagingEventBus().emitNewMessage(NewChatMessageEvent(
          roomId: roomId,
          messageId: messageId,
          senderId: senderId,
          senderName: senderName,
          content: msgContent,
          createdAt: createdAt,
          messageType: subtype.isNotEmpty ? subtype : (message.data['message_type']?.toString() ?? data['messageType']?.toString()),
          metadata: metadata,
          messageStatus: messageStatus,
        ));
        
        // Emit sự kiện reload messages để cập nhật khi đang ở tab khác
        NavigationEventBus().emitReloadMessages(reason: 'new_chat_message');
      } else if (!isChat) {
        // Announcement
        final isAnnouncement = typeRaw == 'announcement' || actionRaw == 'announcement';
        final isNewRequest = subtype == 'new_request' || data['subtype'] == 'new_request';
        final isActivatedGarage = subtype == 'activatedGarage' || data['subtype'] == 'activatedGarage';
        
        if (isAnnouncement && isNewRequest) {
          // Phát reload request list với notification data
          NavigationEventBus().emitReloadRequests(
            reason: 'announcement:new_request',
            notificationData: data,
          );
        } else if (isAnnouncement && isActivatedGarage) {
          // Xử lý garage activation notification - force refresh user info
          NavigationEventBus().emitReloadUserInfo(reason: 'announcement:activatedGarage');
        }
        // not chat -> will show local notification
      } else if (roomId.isEmpty) {
        // roomId empty -> fallback to local notification
      }

      // Trường hợp khác: dựng title/body theo type/subtype rồi hiển thị local notification
      try {
        // Giao cho LocalNotificationService dựng title/body theo type/subtype
        await LocalNotificationService.showFirebaseNotification(message);
      } catch (e) {
      }
    } catch (e) {
    }
  }

  // Xử lý khi user tap vào notification
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    _logRawMessage(message, 'TAP');
    
    // Có thể navigate đến màn hình cụ thể dựa trên data
    final data = message.data;
    if (data.isNotEmpty) {
      // Xử lý navigation dựa trên data
      try {
        final typeRaw = (data['type'] ?? '').toString().trim();
        final actionRaw = (data['action'] ?? '').toString().trim();
        final isChat = typeRaw == 'chat' || actionRaw == 'new_message';
        final roomId = (data['room_id'] ?? data['roomId'] ?? '').toString().trim();

        if (isChat && roomId.isNotEmpty) {
          // Nếu đang ở đúng phòng thì không push thêm
          if (ChatPresence.currentRoomId == roomId) {
            return;
          }
          Navigate.pushNamed('/chat-room', arguments: roomId);
          return;
        }
      } catch (e) {
      }
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure firebase is initialized in background isolate
  try {
    await Firebase.initializeApp();
   
    // Log payload khi ở background/terminated
    PushNotificationService._logRawMessage(message, 'BACKGROUND');
   
    if (message.notification != null) {
      // Firebase sẽ tự động hiển thị notification
    } else if (message.data.isNotEmpty) {
      // Chỉ hoạt động khi app ở background, không phải terminated
      await LocalNotificationService.initialize();
      await LocalNotificationService.showFirebaseNotification(message);
    }
  } catch (e) {
  }
}



