import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_notification_service.dart';
import 'fcm_token_service.dart';
import 'chat_presence.dart';
import 'messaging_event_bus.dart';
import 'navigation_event_bus.dart';
import 'package:gara/navigation/navigation.dart';
// Keep only debug logging and basic flows; remove APNS waiting/fallbacks for now

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
      // In ra toàn bộ RemoteMessage nguyên bản (dùng jsonEncode để readable hoặc in thô)
      // ignore: avoid_print
      print('[PushNotificationService] RAW $contextLabel: ${jsonEncode(message)}');
    } catch (_) {
      // ignore: avoid_print
      print('[PushNotificationService] RAW $contextLabel: <log-failed>');
    }
  }

  static Future<void> _performInitialization() async {
    try {
      await Firebase.initializeApp();

      // Đảm bảo channel được tạo và xin quyền (Android 13+)
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
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        await messaging.getNotificationSettings();
        // Android 13+: cần xin POST_NOTIFICATIONS
        await LocalNotificationService.requestPermissionsIfNeeded();
      }

      // Lắng nghe token refresh để cập nhật token mới lên server
      FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
        try {
          await FcmTokenService.refreshFcmToken(newToken: token);
        } catch (_) {}
      });

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

      // Kiểm tra quyền notification trước khi lấy token (debug only)
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        print('🔍 [FCM] iOS notification settings: ${settings.authorizationStatus}');
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          print('❌ [FCM] iOS notification permission denied, cannot get FCM token');
          return null;
        }
      }

      print('🔍 [FCM] Getting FCM token...');
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        print('✅ [FCM] FCM token obtained successfully: ${token.substring(0, 20)}...');
      } else {
        print('❌ [FCM] FCM token is null');
      }

      return token;
    } catch (e) {
      print('❌ [FCM] Error getting FCM token: $e');
      print('❌ [FCM] Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Kiểm tra trạng thái notification permission chi tiết
  static Future<void> checkNotificationPermissionStatus() async {
    if (Platform.isIOS) {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        print('🔍 [FCM] iOS Notification Permission Status:');
        print('  - Authorization: ${settings.authorizationStatus}');
        print('  - Alert: ${settings.alert}');
        print('  - Badge: ${settings.badge}');
        print('  - Sound: ${settings.sound}');
        print('  - Announcement: ${settings.announcement}');
        print('  - Car Play: ${settings.carPlay}');
        print('  - Critical Alert: ${settings.criticalAlert}');
      } catch (e) {
        print('❌ [FCM] Error checking iOS notification permission: $e');
      }
    }
  }

  // Fallback strategies removed for pre-production; rely on simple path and debug logs

  // Kiểm tra notification khi app khởi động từ terminated state
  static Future<void> _checkInitialMessage() async {
    try {
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        _logRawMessage(initialMessage, 'INITIAL');

        // Xử lý navigation nếu cần
        await _handleNotificationTap(initialMessage);
      } else {}
    } catch (e) {}
  }

  // Xử lý message khi app đang ở foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logRawMessage(message, 'FOREGROUND');

    try {
      final data = message.data;
      final typeRaw = (data['type'] ?? '').toString().trim();
      final actionRaw = (data['action'] ?? '').toString().trim();
      final subtype = (data['subtype'] ?? data['messageType'] ?? '').toString().trim();
      final roomId =
          (data['room_id'] ?? data['roomId'] ?? data['roomID'] ?? data['room_id_str'] ?? '').toString().trim();
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

      // Parse fileUrl cho message type 2 (IMAGE) và 3 (VIDEO)
      String? fileUrl;
      String? thumbnailUrl;
      final messageTypeInt = int.tryParse(subtype) ?? int.tryParse(data['message_type']?.toString() ?? '');
      if (messageTypeInt == 2 || messageTypeInt == 3) {
        fileUrl = (data['file_url'] ?? data['fileUrl'] ?? data['fileurl'] ?? '').toString().trim();
        if (fileUrl.isEmpty) {
          fileUrl = null;
        }
        // Thumbnail cho video hoặc khi server gửi kèm
        final thumbRaw =
            (data['thumbnail_url'] ?? data['thumbnailUrl'] ?? data['thumbnails'] ?? data['thumb_url'] ?? '')
                .toString()
                .trim();
        if (thumbRaw.isNotEmpty) {
          thumbnailUrl = thumbRaw;
        }
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
        if (raw is String && raw.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (_) {}
        }
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
        MessagingEventBus().emitNewMessage(
          NewChatMessageEvent(
            roomId: roomId,
            messageId: messageId,
            senderId: senderId,
            senderName: senderName,
            content: msgContent,
            createdAt: createdAt,
            messageType: subtype.isNotEmpty
                ? subtype
                : (message.data['message_type']?.toString() ?? data['messageType']?.toString()),
            fileUrl: fileUrl,
            thumbnailUrl: thumbnailUrl,
            metadata: metadata,
            messageStatus: messageStatus,
          ),
        );
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
        MessagingEventBus().emitNewMessage(
          NewChatMessageEvent(
            roomId: roomId,
            messageId: messageId,
            senderId: senderId,
            senderName: senderName,
            content: msgContent,
            createdAt: createdAt,
            messageType: subtype.isNotEmpty
                ? subtype
                : (message.data['message_type']?.toString() ?? data['messageType']?.toString()),
            fileUrl: fileUrl,
            thumbnailUrl: thumbnailUrl,
            metadata: metadata,
            messageStatus: messageStatus,
          ),
        );

        // Emit sự kiện reload messages để cập nhật khi đang ở tab khác
        NavigationEventBus().emitReloadMessages(reason: 'new_chat_message');
      } else if (!isChat) {
        // Announcement
        final isAnnouncement = typeRaw == 'announcement' || actionRaw == 'announcement';
        final isNewRequest = subtype == 'new_request' || data['subtype'] == 'new_request';
        final isActivatedGarage = subtype == 'activatedGarage' || data['subtype'] == 'activatedGarage';

        if (isAnnouncement && isNewRequest) {
          // Phát reload request list với notification data
          NavigationEventBus().emitReloadRequests(reason: 'announcement:new_request', notificationData: data);
        } else if (isAnnouncement && isActivatedGarage) {
          // Xử lý garage activation notification - force refresh user info
          NavigationEventBus().emitReloadUserInfo(reason: 'announcement:activatedGarage');
        }
        // not chat -> Firebase tự hiển thị notification nếu có notification payload
      } else if (roomId.isEmpty) {
        // roomId empty -> Firebase tự hiển thị notification nếu có notification payload
      }

      // Hiển thị notification khi app ở foreground nếu server gửi notification payload
      if (message.notification != null) {
        await LocalNotificationService.showFirebaseNotification(message);
      }
    } catch (e) {}
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
      } catch (e) {}
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
      // Data only payload - chỉ xử lý logic realtime, KHÔNG hiển thị notification
      // Firebase xử lý notification, data payload để xử lý logic trong app
    }
  } catch (e) {}
}
