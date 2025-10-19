import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/debug_logger.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static bool _isInitializing = false;
  static Future<void>? _initializationFuture;

  static Future<void> initialize() async {
    DebugLogger.log('🔍 [DEBUG] LocalNotificationService.initialize() called, _initialized: $_initialized, _isInitializing: $_isInitializing');
    
    if (_initialized) {
      DebugLogger.log('LocalNotificationService already initialized');
      return;
    }
    
    // Nếu đang khởi tạo, đợi kết quả của lần khởi tạo đó
    if (_initializationFuture != null) {
      DebugLogger.log('LocalNotificationService is already initializing, waiting for existing initialization...');
      await _initializationFuture;
      return;
    }
    
    // Tạo future khởi tạo và lưu lại
    _initializationFuture = _performInitialization();
    await _initializationFuture;
  }

  static Future<void> _performInitialization() async {
    DebugLogger.log('🔔 Initializing LocalNotificationService...');

    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? initialized = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        DebugLogger.log('✅ Local notifications plugin initialized successfully');
      } else {
        DebugLogger.log('⚠️ Local notifications plugin initialization returned false');
      }

      // Tạo notification channel cho Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // Kiểm tra quyền local notifications
      await _checkLocalNotificationPermissions();

      _initialized = true;
      DebugLogger.log('🎉 LocalNotificationService initialized successfully!');
      
    } catch (e) {
      DebugLogger.log('❌ Error initializing LocalNotificationService: $e');
      rethrow;
    }
  }

  static Future<void> _createNotificationChannel() async {
    DebugLogger.log('📱 Creating Android notification channel...');
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gara_notifications',
      'Gara Notifications',
      description: 'Thông báo từ ứng dụng Gara',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      // Đảm bảo notification hiển thị trên lock screen
      // lockscreenVisibility: NotificationVisibility.public,
    );

    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      DebugLogger.log('✅ Android notification channel created successfully');
    } catch (e) {
      DebugLogger.log('❌ Error creating Android notification channel: $e');
    }
  }

  static Future<void> _checkLocalNotificationPermissions() async {
    DebugLogger.log('🔍 Checking local notification permissions...');
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final bool? areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
          DebugLogger.log('Android notifications enabled: $areNotificationsEnabled');
          
          if (areNotificationsEnabled == false) {
            DebugLogger.log('⚠️ Android notifications are disabled. Requesting POST_NOTIFICATIONS permission (Android 13+)...');
            try {
              final bool? granted = await androidPlugin.requestNotificationsPermission();
              DebugLogger.log('Android POST_NOTIFICATIONS permission granted: $granted');
              if (granted != true) {
                DebugLogger.log('⚠️ User did not grant notification permission. Consider opening app settings.');
              }
            } catch (e) {
              DebugLogger.log('❌ Error requesting Android notification permission: $e');
            }
          }
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final bool? result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          DebugLogger.log('iOS notification permissions granted: $result');
        }
      }
    } catch (e) {
      DebugLogger.log('❌ Error checking local notification permissions: $e');
    }
  }

  // Public method: có thể gọi từ UI để xin quyền thủ công
  static Future<bool> requestPermissionsIfNeeded() async {
    try {
      if (Platform.isAndroid) {
        final android = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          final enabled = await android.areNotificationsEnabled() ?? false;
          if (!enabled) {
            final granted = await android.requestNotificationsPermission();
            DebugLogger.log('Manual request Android notifications permission granted: $granted');
            return granted ?? false;
          }
          return true;
        }
      } else if (Platform.isIOS) {
        final ios = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) {
          final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
          DebugLogger.log('Manual request iOS notifications permission granted: $granted');
          return granted ?? false;
        }
      }
      return false;
    } catch (e) {
      DebugLogger.log('❌ Error requesting notifications permission manually: $e');
      return false;
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    bool? playSound,
    Priority? androidPriority,
    Importance? androidImportance,
  }) async {
    DebugLogger.log('🔔 Showing local notification: ID=$id, Title="$title"');
    
    await initialize();

    // Nếu server chỉ định channelId riêng, tạo channel đó trước khi hiển thị
    final String effectiveChannelId = (channelId?.isNotEmpty == true)
        ? channelId!
        : 'gara_notifications';
    final Importance effectiveImportance = androidImportance ?? Importance.high;
    final Priority effectivePriority = androidPriority ?? Priority.high;
    final bool effectivePlaySound = playSound ?? true;

    if (Platform.isAndroid) {
      try {
        final AndroidNotificationChannel dynamicChannel = AndroidNotificationChannel(
          effectiveChannelId,
          // Đặt tên channel thân thiện nếu là channel mặc định thì dùng tên cũ
          effectiveChannelId == 'gara_notifications' ? 'Gara Notifications' : effectiveChannelId,
          description: 'Thông báo từ ứng dụng Gara',
          importance: effectiveImportance,
          playSound: effectivePlaySound,
          enableVibration: true,
        );
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(dynamicChannel);
      } catch (e) {
        DebugLogger.log('❌ Error creating dynamic Android channel: $e');
      }
    }

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      effectiveChannelId,
      effectiveChannelId == 'gara_notifications' ? 'Gara Notifications' : effectiveChannelId,
      channelDescription: 'Thông báo từ ứng dụng Gara',
      importance: effectiveImportance,
      priority: effectivePriority,
      playSound: effectivePlaySound,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      DebugLogger.log('✅ Local notification displayed successfully');
    } catch (e) {
      DebugLogger.log('❌ Error showing local notification: $e');
      rethrow;
    }
  }

  static Future<void> showFirebaseNotification(RemoteMessage message) async {
    DebugLogger.log('🔥 Converting Firebase message to local notification...');

    final notification = message.notification;
    final data = message.data;

    DebugLogger.largeJson('Firebase Notification Payload', {
      'title': notification?.title,
      'body': notification?.body,
      'android': notification?.android != null ? {
        'channelId': notification?.android?.channelId,
        'clickAction': notification?.android?.clickAction,
        'color': notification?.android?.color,
        'count': notification?.android?.count,
        'imageUrl': notification?.android?.imageUrl,
        'link': notification?.android?.link,
        'priority': notification?.android?.priority.toString(),
        'smallIcon': notification?.android?.smallIcon,
        'sound': notification?.android?.sound,
        'tag': notification?.android?.tag,
        'ticker': notification?.android?.ticker,
        'visibility': notification?.android?.visibility.toString(),
      } : null,
      'apple': notification?.apple != null ? {
        'badge': notification?.apple?.badge,
        'imageUrl': notification?.apple?.imageUrl,
        'sound': notification?.apple?.sound,
      } : null,
      'data': data,
    });

    try {
      final type = (data['type'] ?? '').toString();
      final subtype = (data['subtype'] ?? data['messageType'] ?? '').toString();
      final senderName = (data['sender_name'] ?? data['senderName'] ?? '').toString();
      final content = (data['message'] ?? data['content'] ?? notification?.body ?? '').toString();

      // Lấy title/body theo payload mới (notification.title/body)
      String title = notification?.title ?? 'Thông báo mới';
      String body = notification?.body ?? content;

      if (type == 'chat') {
        // Giữ UX cũ cho chat
        title = 'Bạn có tin nhắn mới';
        body = senderName.isNotEmpty ? '$senderName: $content' : content;
        switch (subtype) {
          case '2':
            body = '$senderName đã gửi một hình ảnh';
            break;
          case '3':
            body = '$senderName đã gửi một tệp tin';
            break;
          case '4':
            body = '$senderName đã gửi một báo giá';
            break;
          case '5':
            body = '$senderName đã gửi thông tin đặt lịch';
            break;
          case '6':
            body = '$senderName đã cập nhật trạng thái';
            break;
          case '7':
            body = 'Lịch hẹn đã bị huỷ';
            break;
          default:
            break;
        }
      } else if (type == 'announcement') {
        title = notification?.title ?? 'Thông báo';
        body = notification?.body ?? content;
      }

      // Extract channel_id, default_sound, priority từ payload Android (HTTP v1)
      // Trong Flutter, channel_id nhiều khả năng đã được map vào notification.android.channelId
      // nhưng ta vẫn fallback từ data nếu có (để linh hoạt với backend khác nhau)
      final String channelIdFromNotification = notification?.android?.channelId ?? '';
      final String channelIdFromData = (data['channel_id'] ?? data['android_channel_id'] ?? data['channelId'] ?? '').toString();
      final String effectiveChannelId = channelIdFromNotification.isNotEmpty
          ? channelIdFromNotification
          : (channelIdFromData.isNotEmpty ? channelIdFromData : 'gara_notifications');

      // Priority/Sound
      final String priorityRaw = (data['priority'] ?? data['android_priority'] ?? '').toString().toUpperCase();
      // Nếu gửi đúng qua Android notification option, firebase_messaging không expose trực tiếp -> dùng mặc định HIGH nếu không có
      final bool playSound = (data['default_sound']?.toString().toLowerCase() == 'true')
          || (notification?.android?.sound != null);

      final Importance importance = priorityRaw == 'MAX' || priorityRaw == 'HIGH' ? Importance.high : Importance.defaultImportance;
      final Priority priority = priorityRaw == 'MAX' || priorityRaw == 'HIGH' ? Priority.high : Priority.defaultPriority;

      // Đảm bảo channel mặc định tồn tại tối thiểu
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      await showNotification(
        id: message.hashCode,
        title: title,
        body: body,
        payload: message.data.toString(),
        channelId: effectiveChannelId,
        playSound: playSound,
        androidImportance: importance,
        androidPriority: priority,
      );
      DebugLogger.log('✅ Firebase notification converted to local notification successfully');
    } catch (e) {
      DebugLogger.log('❌ Error converting Firebase notification to local: $e');
      DebugLogger.log('❌ Stack trace: ${StackTrace.current}');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    DebugLogger.log('👆 Local notification tapped');
    DebugLogger.largeJson('Notification Tap Response', {
      'id': response.id,
      'actionId': response.actionId,
      'input': response.input,
      'payload': response.payload,
      'notificationResponseType': response.notificationResponseType.toString(),
    });
    
    // Xử lý khi user tap vào notification
    final payload = response.payload;
    if (payload != null) {
      DebugLogger.log('📱 Processing notification tap with payload: $payload');
      // Có thể navigate đến màn hình cụ thể dựa trên payload
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
