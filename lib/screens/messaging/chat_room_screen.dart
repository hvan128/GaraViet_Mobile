import 'package:flutter/material.dart';
import 'package:gara/screens/messaging/widgets/service_info_card.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/messaging/messaging_service.dart';
import 'package:gara/models/messaging/messaging_models.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/widgets/skeleton.dart';
import 'package:gara/services/messaging/chat_presence.dart';
import 'package:gara/services/quotation/quotation_service.dart';
import 'package:gara/services/messaging/messaging_event_bus.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/utils/status/status_widget.dart';
import 'package:gara/utils/status/quotation_status.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/fullscreen_image_viewer.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:v_video_compressor/v_video_compressor.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _loading = true;
  bool _loadingMore = false;
  bool _initialListReady = false;
  // Danh sách DESC: phần tử 0 là mới nhất
  List<MessageData> _messagesDesc = [];
  // Phân trang: lấy cũ hơn dựa vào oldestId (phần tử cuối cùng)
  // Phân trang theo offset
  int _startAfterOffset = 0;
  final int _limit = 15;
  RoomData? _room;

  // Optimistic send state
  final Set<String> _pendingMessageIds = {};
  final Set<String> _failedMessageIds = {};
  final Set<String> _retryingMessageIds = {};
  final Map<String, String> _localMessageContentById = {};

  // Media selection state
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];
  final VVideoCompressor _videoCompressor = VVideoCompressor();

  // Upload state
  final Map<String, double> _uploadProgress = {}; // messageId -> progress (0.0 to 1.0)
  // Throttle buckets để hạn chế setState liên tục khi cập nhật progress (5%/bước)
  final Map<String, int> _uploadProgressBuckets = {}; // messageId -> bucket index

  // Video compression state
  final Map<String, double> _compressionProgress = {}; // videoPath -> progress (0.0 to 1.0)
  final Map<String, bool> _isCompressing = {}; // videoPath -> isCompressing
  final Map<String, File?> _compressedVideos = {}; // originalPath -> compressedFile
  // Throttle buckets cho tiến trình nén
  final Map<String, int> _compressionProgressBuckets = {}; // videoPath -> bucket index

  // Video thumbnail state
  final Map<String, String?> _videoThumbnails = {}; // videoPath -> thumbnailPath
  final Map<String, bool> _generatingThumbnails = {}; // videoPath -> isGenerating
  // Cached aspect ratios (width / height) for thumbnails per video
  final Map<String, double> _videoAspectRatios = {}; // videoPath -> aspectRatio

  // Mapping failed messages to their files
  final Map<String, List<File>> _failedMessageFiles = {}; // messageId -> List<File>
  final Map<String, int> _failedMessageTypes = {}; // messageId -> messageType

  // Getter for current user
  int get currentUserId {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Use userId to match message.senderId from API
    return userProvider.userInfo?.userId ?? 0;
  }

  // Getter for role: is garage user
  bool get isGarageUser {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.isGarageUser;
  }

  @override
  void initState() {
    super.initState();
    // Subscribe realtime new message events
    _newMessageSub = MessagingEventBus().onNewMessage.listen(_onNewMessageEvent);
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _initRoomAndMessages();
    }
  }

  @override
  void dispose() {
    // Clear presence and subscription
    final id = _room?.roomId;
    if (id != null) ChatPresence.leaveRoom(id);
    _newMessageSub?.cancel();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup video compressor
    _videoCompressor.cleanup();

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Called when keyboard appears/disappears
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      _scrollToBottom();
    }
  }

  StreamSubscription<NewChatMessageEvent>? _newMessageSub;
  bool _isAtBottom = true;
  int _newIncomingCount = 0;
  bool _loadMoreRetrying = false;

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Với reverse:true, "đáy" là offset ~0 (tin nhắn mới nhất)
    final atBottom = _scrollController.position.pixels <= 10;
    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
        if (_isAtBottom) _newIncomingCount = 0;
      });
    }

    // Với reverse:true:
    // - extentAfter: khoảng cách từ vị trí hiện tại đến cuối danh sách (tin nhắn cũ nhất)
    // - Khi user cuộn lên (kéo xuống trên màn hình) để xem tin nhắn cũ hơn → extentAfter giảm
    // - Load more khi gần đến cuối danh sách (tin nhắn cũ nhất)
    final extentAfter = _scrollController.position.extentAfter;

    // Chỉ load more khi:
    // 1. Gần đến cuối danh sách (extentAfter < 200)
    // 2. Không đang load more
    // 3. Có roomId
    // 4. Đã có ít nhất một số tin nhắn (tránh load more khi danh sách rỗng)
    if (extentAfter < 200 && !_loadingMore && (_room?.roomId) != null && _messagesDesc.isNotEmpty) {
      DebugLogger.log('[ChatRoom] Trigger load more: extentAfter=$extentAfter, messagesCount=${_messagesDesc.length}');
      _loadMoreMessages();
    }
  }

  void _onNewMessageEvent(NewChatMessageEvent event) {
    // Chỉ xử lý khi đang ở đúng room hiện tại
    if (_room?.roomId == null || _room!.roomId != event.roomId) return;
    DebugLogger.largeJson('[ChatRoom] onNewMessageEvent', {
      'roomId': event.roomId,
      'messageId': event.messageId,
      'senderId': event.senderId,
      'type': event.messageType,
      'fileUrl': event.fileUrl,
      'metadata': event.metadata,
    });
    final newMsg = MessageData(
      messageId: event.messageId,
      roomId: event.roomId,
      senderId: event.senderId,
      senderName: event.senderName,
      senderAvatar: null,
      message: event.content,
      createdAt: event.createdAt,
      isRead: true,
      messageType: event.messageType,
      fileUrl: event.fileUrl,
      thumbnails: event.thumbnailUrl,
      metadata: event.metadata,
    );
    setState(() {
      // Tránh trùng lặp
      final exists = _messagesDesc.any((m) => m.messageId == newMsg.messageId);
      if (!exists) {
        // Insert vào đầu danh sách DESC
        _messagesDesc.insert(0, newMsg);
        DebugLogger.largeJson('[ChatRoom] message inserted at head', {
          'listLength': _messagesDesc.length,
          'firstId': _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
        });
        if (_isAtBottom) {
          // Nếu đang ở đáy thì tự cuộn xuống để thấy tin mới
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        } else {
          _newIncomingCount += 1;
        }
      } else {
        DebugLogger.log('[ChatRoom] message already exists in list, skip append');
      }
    });

    // Fallback đồng bộ nhẹ nếu vì lý do nào đó chưa thấy trong danh sách
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final stillMissing = !_messagesDesc.any((m) => m.messageId == event.messageId);
      if (stillMissing && (_room?.roomId) != null) {
        DebugLogger.log('[ChatRoom] fallback fetch latest messages due to missing new message');
        try {
          final detail = await MessagingServiceApi.getRoomDetailWithMessages(roomId: _room!.roomId, limit: _limit);
          if (!mounted || detail == null) return;
          setState(() {
            final merged = [..._messagesDesc];
            for (final m in detail.messages) {
              if (!merged.any((e) => e.messageId == m.messageId)) {
                merged.add(m);
              }
            }
            _messagesDesc = _sortDesc(merged);
          });
          if (_isAtBottom) _scrollToBottom();
        } catch (_) {}
      }
    });
  }

  Future<void> _initRoomAndMessages() async {
    setState(() {
      _loading = true;
    });
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      final id = args is String ? args : null;
      DebugLogger.largeJson('[ChatRoomScreen] init args', {'args': args?.toString(), 'roomId': id});
      if (id != null && id.isNotEmpty) {
        // Reset state khi vào phòng mới để tránh merge nhầm dữ liệu cũ
        setState(() {
          _messagesDesc = [];
          _startAfterOffset = 0;
          _isAtBottom = true;
          _newIncomingCount = 0;
        });
        // Set presence: vào phòng
        ChatPresence.enterRoom(id);
        DebugLogger.largeJson('[ChatRoomScreen] call getRoomDetailWithMessages', {
          'roomId': id,
          'limit': _limit,
          'startAfter': _startAfterOffset,
          'state_len': _messagesDesc.length,
          'state_firstId': _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
          'state_lastId': _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
          'isAtBottom': _isAtBottom,
          'newIncoming': _newIncomingCount,
        });
        final detail = await MessagingServiceApi.getRoomDetailWithMessages(
          roomId: id,
          limit: _limit,
          startAfterOffset: _startAfterOffset,
        );
        DebugLogger.largeJson('[ChatRoomScreen] fetch completed', {'detail_null': detail == null, 'mounted': mounted});
        if (mounted && detail != null) {
          setState(() {
            _room = detail.roomInfo;
            DebugLogger.log('[Chat Room Detail ] $_room');
            // Merge tránh ghi đè các tin mới đã nhận qua realtime
            final merged = [..._messagesDesc];
            for (final m in detail.messages) {
              if (!merged.any((e) => e.messageId == m.messageId)) {
                merged.add(m);
              }
            }
            _messagesDesc = _sortDesc(merged);
            _startAfterOffset = _messagesDesc.length;
            _loading = false;
            _initialListReady = false;
          });
          DebugLogger.largeJson('[ChatRoomScreen] after merge initial', {
            'len': _messagesDesc.length,
            'firstId': _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
            'firstCreatedAt': _messagesDesc.isNotEmpty ? _messagesDesc.first.createdAt : null,
            'lastId': _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
            'lastCreatedAt': _messagesDesc.isNotEmpty ? _messagesDesc.last.createdAt : null,
          });
          _ensureInitialScrollToBottom();
          // _markOpponentMessagesRead();
          return;
        }
        DebugLogger.log('[ChatRoomScreen] getRoomDetailWithMessages returned null');
      }
    } catch (e, st) {
      DebugLogger.largeJson('[ChatRoomScreen] init error', {'error': e.toString(), 'stack': st.toString()});
    }
    // If we reach here without data but have an id, try messages only as fallback
    if (_room?.roomId != null) {
      await _loadMoreMessages(initial: true);
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  // Giữ dữ liệu ở DESC và có helper sort DESC khi cần chuẩn hoá
  List<MessageData> _sortDesc(List<MessageData> items) {
    int cmp(MessageData a, MessageData b) {
      DateTime? pa;
      DateTime? pb;
      try {
        pa = DateTime.parse(a.createdAt);
      } catch (_) {}
      try {
        pb = DateTime.parse(b.createdAt);
      } catch (_) {}
      if (pa != null && pb != null) return pb.compareTo(pa); // newest first
      if (pa != null && pb == null) return -1;
      if (pa == null && pb != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    }

    items.sort(cmp);
    return items;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        // reverse:true → đáy là offset 0
        _scrollController.jumpTo(0.0);
      }
    });
  }

  void _ensureInitialScrollToBottom() {
    if (_initialListReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialListReady = true;
      _scrollToBottom();
    });
  }

  Future<void> _loadMoreMessages({bool initial = false}) async {
    if (_loadingMore) return;

    setState(() {
      if (initial) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final id = (_room?.roomId)!;
      final detail = await MessagingServiceApi.getRoomDetailWithMessages(
        roomId: id,
        limit: _limit,
        startAfterOffset: _startAfterOffset,
      );

      if (!mounted || detail == null) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
        return;
      }

      // API trả DESC (mới → cũ) cho page tiếp theo cũng DESC
      final newMessages = detail.messages;

      int appendedCount = 0;
      setState(() {
        _room ??= detail.roomInfo;
        if (initial || _messagesDesc.isEmpty) {
          _messagesDesc = newMessages;
        } else {
          // Vì list đang DESC, các tin cũ hơn cũng DESC → append vào CUỐI list
          final oldLen = _messagesDesc.length;
          final toAppend = newMessages.where((m) => !_messagesDesc.any((e) => e.messageId == m.messageId));
          _messagesDesc.addAll(toAppend);
          appendedCount = _messagesDesc.length - oldLen;
          // Không jump; Flutter giữ vị trí ổn với reverse:true
          DebugLogger.log('[ChatRoom] appended older messages: +$appendedCount');
        }
        // Offset tăng theo tổng số item đã có
        _startAfterOffset = _messagesDesc.length;
        _loading = false;
        _loadingMore = false;
      });
      DebugLogger.largeJson('[ChatRoomScreen] after loadMore append', {
        'len': _messagesDesc.length,
        'firstId': _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
        'firstCreatedAt': _messagesDesc.isNotEmpty ? _messagesDesc.first.createdAt : null,
        'lastId': _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
        'lastCreatedAt': _messagesDesc.isNotEmpty ? _messagesDesc.last.createdAt : null,
        'startAfter_next': _startAfterOffset,
      });

      // Fallback: nếu server trả về trùng trang (bỏ qua start_after) → thử dịch cursor 1 lần
      try {
        if (!initial && appendedCount == 0 && detail.messages.isNotEmpty && !_loadMoreRetrying) {
          final serverFirstId = detail.messages.first.messageId;
          final currentFirstId = _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null;
          if (serverFirstId == currentFirstId) {
            _loadMoreRetrying = true;
            final nextCursor = _messagesDesc.length;
            DebugLogger.largeJson('[ChatRoomScreen] loadMore fallback retry', {
              'prev_start_after': _startAfterOffset,
              'retry_start_after': nextCursor,
            });
            _startAfterOffset = nextCursor;
            await _loadMoreMessages();
            _loadMoreRetrying = false;
          }
        }
      } catch (_) {
        _loadMoreRetrying = false;
      }

      if (initial) {
        _ensureInitialScrollToBottom();
        // _markOpponentMessagesRead();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      DebugLogger.largeJson('[ChatRoomScreen] error', {'error': e.toString()});
      AppToastHelper.showError(context, message: 'Không thể tải tin nhắn. Vui lòng thử lại sau.');
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final hasMedia = _selectedImages.isNotEmpty || _selectedVideos.isNotEmpty;

    if (content.isEmpty && !hasMedia) return;

    // Store media for potential retry
    final imagesToSend = List<File>.from(_selectedImages);
    final videosToSend = List<File>.from(_selectedVideos);

    // Hide media preview immediately
    if (hasMedia) {
      setState(() {
        _selectedImages.clear();
        _selectedVideos.clear();
      });
    }

    try {
      // Send text message if has content
      if (content.isNotEmpty) {
        await _sendTextMessage(content);
      }

      // Send images if has images
      if (imagesToSend.isNotEmpty) {
        await _sendMediaFiles(imagesToSend, 2, currentUserId); // Type 2: IMAGE
      }

      // Send videos if has videos
      if (videosToSend.isNotEmpty) {
        // Show bubble immediately; actual upload will wait for compression inside
        DebugLogger.log(
            '[ChatRoom] Preparing to send videos. Will wait for compression if needed. count=${videosToSend.length}');
        await _sendMediaFiles(videosToSend, 3, currentUserId, waitForCompression: true); // Type 3: VIDEO
      }

      // Clear selected media only after all messages are sent successfully
      setState(() {
        _selectedImages.clear();
        _selectedVideos.clear();
      });
    } catch (e) {
      DebugLogger.largeJson('[ChatRoomScreen] send error', {'error': e.toString()});
      AppToastHelper.showError(context, message: 'Có lỗi xảy ra khi gửi tin nhắn');
      // Don't clear on error - user can retry
    }
  }

  Future<void> _sendTextMessage(String content) async {
    final tempId = 'temp-text-${DateTime.now().microsecondsSinceEpoch}';
    final tempMessage = MessageData(
      messageId: tempId,
      roomId: (_room?.roomId)!,
      senderId: currentUserId,
      senderName: '',
      senderAvatar: null,
      message: content,
      createdAt: DateTime.now().toIso8601String(),
      isRead: true,
      messageType: '1',
      thumbnails: null,
    );

    setState(() {
      _messagesDesc.insert(0, tempMessage);
      _pendingMessageIds.add(tempId);
      _localMessageContentById[tempId] = content;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final response = await MessagingServiceApi.sendMessage(
        roomId: (_room?.roomId)!,
        message: content,
        messageType: 1,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          final idx = _messagesDesc.indexWhere((m) => m.messageId == tempId);
          if (idx != -1) {
            _messagesDesc[idx] = response.data!;
          } else {
            _messagesDesc.insert(0, response.data!);
          }
          _pendingMessageIds.remove(tempId);
          _localMessageContentById.remove(tempId);
          _failedMessageIds.remove(tempId);
        });
        _scrollToBottom();
      } else {
        if (!mounted) return;
        setState(() {
          _pendingMessageIds.remove(tempId);
          _failedMessageIds.add(tempId);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingMessageIds.remove(tempId);
        _failedMessageIds.add(tempId);
      });
    }
  }

  Future<void> _sendMediaFiles(List<File> files, int messageType, int userId, {bool waitForCompression = false}) async {
    final tempId = 'temp-media-${DateTime.now().microsecondsSinceEpoch}';
    final mediaType = messageType == 2 ? 'ảnh' : 'video';

    // For videos, use compressed version if available
    List<File> filesToSend = files;
    if (messageType == 3) {
      filesToSend = files.map((file) {
        return _compressedVideos[file.path] ?? file;
      }).toList();
      DebugLogger.largeJson('[ChatRoom] Video send mapping (original -> used)', {
        'pairs': files
            .map((f) => {
                  'original': f.path,
                  'used': (_compressedVideos[f.path]?.path ?? f.path),
                })
            .toList(),
      });
    }

    // Create temp message with file URLs for thumbnail display
    final fileUrls = filesToSend.map((file) => file.path).join(',');
    final tempMessage = MessageData(
      messageId: tempId,
      roomId: (_room?.roomId)!,
      senderId: userId,
      senderName: '',
      senderAvatar: null,
      message: 'Đang gửi $mediaType...',
      createdAt: DateTime.now().toIso8601String(),
      isRead: true,
      messageType: messageType.toString(),
      fileUrl: fileUrls, // Store local file paths for thumbnail display
      thumbnails: null,
    );

    setState(() {
      _messagesDesc.insert(0, tempMessage);
      _pendingMessageIds.add(tempId);
      _uploadProgress[tempId] = 0.0;
    });
    _scrollToBottom();

    // Simulate progress updates
    _simulateUploadProgress(tempId, files);

    try {
      // If requested, wait silently for compression to complete before uploading
      if (messageType == 3 && waitForCompression) {
        DebugLogger.log('[ChatRoom] Waiting for video compression before upload...');
        await _waitForVideoCompression(files);
        DebugLogger.log('[ChatRoom] Done waiting, continue to upload videos');
      }

      // For videos, ensure and collect thumbnails one-to-one with filesToSend
      List<File>? thumbnailsToSend;
      if (messageType == 3) {
        await _ensureThumbnailsForVideos(filesToSend);
        DebugLogger.log('[ChatRoom] Thumbnails ensured for videos: ${filesToSend.map((f) => f.path).toList()}');
        final tmp = <File>[];
        for (final file in filesToSend) {
          final tp = _videoThumbnails[file.path];
          if (tp == null) {
            // If any thumbnail is missing, skip sending thumbnails entirely to avoid misalignment
            tmp.clear();
            break;
          }
          tmp.add(File(tp));
        }
        thumbnailsToSend = tmp.isEmpty ? null : tmp;
        DebugLogger.largeJson('[ChatRoom] Thumbnail files to send', {
          'count': thumbnailsToSend?.length ?? 0,
          'paths': thumbnailsToSend?.map((f) => f.path).toList(),
        });
      }

      DebugLogger.largeJson('[ChatRoom] Uploading media', {
        'type': mediaType,
        'count': filesToSend.length,
        'paths': filesToSend.map((f) => f.path).toList(),
      });
      final response = await MessagingServiceApi.sendMedia(
        roomId: (_room?.roomId)!,
        files: filesToSend,
        messageType: messageType,
        thumbnails: thumbnailsToSend,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        DebugLogger.log(
            '[ChatRoom] Upload media success. Replacing temp message $tempId with server message ${response.data!.messageId}');
        // Ensure senderId is set to current userId (in case server doesn't return it)
        final updatedMessage = MessageData(
          messageId: response.data!.messageId,
          roomId: response.data!.roomId,
          senderId: userId, // Use current user's ID
          senderName: response.data!.senderName,
          senderAvatar: response.data!.senderAvatar,
          message: response.data!.message,
          createdAt: response.data!.createdAt,
          isRead: response.data!.isRead,
          messageType: response.data!.messageType,
          fileUrl: response.data!.fileUrl,
          thumbnails: response.data!.thumbnails,
          metadata: response.data!.metadata,
        );

        setState(() {
          final idx = _messagesDesc.indexWhere((m) => m.messageId == tempId);
          if (idx != -1) {
            _messagesDesc[idx] = updatedMessage;
          } else {
            _messagesDesc.insert(0, updatedMessage);
          }
          _pendingMessageIds.remove(tempId);
          _failedMessageIds.remove(tempId);
          _uploadProgress.remove(tempId);
          _failedMessageFiles.remove(tempId);
          _failedMessageTypes.remove(tempId);
        });
        _scrollToBottom();
      } else {
        if (!mounted) return;
        setState(() {
          _pendingMessageIds.remove(tempId);
          _failedMessageIds.add(tempId);
          _uploadProgress.remove(tempId);
          // Lưu files để retry
          _failedMessageFiles[tempId] = files;
          _failedMessageTypes[tempId] = messageType;
        });
        DebugLogger.log('[ChatRoom] Upload media failed for temp $tempId');
        AppToastHelper.showError(context, message: 'Không thể gửi $mediaType');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingMessageIds.remove(tempId);
        _failedMessageIds.add(tempId);
        _uploadProgress.remove(tempId);
        // Lưu files để retry
        _failedMessageFiles[tempId] = files;
        _failedMessageTypes[tempId] = messageType;
      });
      DebugLogger.log('[ChatRoom] Exception while uploading $mediaType: $e');
      AppToastHelper.showError(context, message: 'Lỗi gửi $mediaType');
    }
  }

  void _simulateUploadProgress(String messageId, List<File> files) {
    double currentProgress = 0.0;

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_uploadProgress.containsKey(messageId)) {
        timer.cancel();
        return;
      }

      currentProgress += 0.05; // Increase by 5% each 200ms
      if (currentProgress > 0.9) currentProgress = 0.9; // Stop at 90% until real upload completes
      final int bucket = (currentProgress * 20).floor(); // 5% per bucket
      if (_uploadProgressBuckets[messageId] != bucket) {
        _uploadProgressBuckets[messageId] = bucket;
        setState(() {
          _uploadProgress[messageId] = currentProgress;
        });
      }
    });
  }

  Future<void> _retrySend(String localMessageId) async {
    final content = _localMessageContentById[localMessageId];
    if (content == null || (_room?.roomId) == null) return;

    // Ngay lập tức chuyển sang trạng thái retrying để hiển thị phản hồi
    setState(() {
      _failedMessageIds.remove(localMessageId);
      _retryingMessageIds.add(localMessageId);
    });

    try {
      final response = await MessagingServiceApi.sendMessage(
        roomId: (_room?.roomId)!,
        message: content,
        messageType: 1,
      );

      DebugLogger.log('[ChatRoom] Send message response received');

      if (!mounted) {
        DebugLogger.log('[ChatRoom] Widget not mounted, skipping UI update');
        return;
      }

      if (response.success && response.data != null) {
        DebugLogger.log('[ChatRoom] Message sent successfully');
        setState(() {
          final idx = _messagesDesc.indexWhere((m) => m.messageId == localMessageId);
          if (idx != -1) {
            _messagesDesc[idx] = response.data!;
          } else {
            _messagesDesc.insert(0, response.data!);
          }
          _retryingMessageIds.remove(localMessageId);
          _localMessageContentById.remove(localMessageId);
        });
        _scrollToBottom();
      } else {
        // Thất bại - hiển thị toast và chuyển về trạng thái failed
        DebugLogger.log('[ChatRoom] Send message failed: ${response.message}');
        AppToastHelper.showError(context, message: 'Gửi tin nhắn thất bại. Vui lòng thử lại.');
        setState(() {
          _retryingMessageIds.remove(localMessageId);
          _failedMessageIds.add(localMessageId);
        });
      }
    } catch (e, stackTrace) {
      DebugLogger.largeJson('[ChatRoom] Send message exception', {
        'error': e.toString(),
        'stack': stackTrace.toString(),
      });

      if (!mounted) {
        DebugLogger.log('[ChatRoom] Widget not mounted after exception, skipping UI update');
        return;
      }

      // Lỗi - hiển thị toast và chuyển về trạng thái failed
      AppToastHelper.showError(context, message: 'Có lỗi xảy ra. Vui lòng thử lại.');
      setState(() {
        _retryingMessageIds.remove(localMessageId);
        _failedMessageIds.add(localMessageId);
      });
    }
  }

  Future<void> _retrySendMedia(MessageData message, int messageType) async {
    if ((_room?.roomId) == null) return;

    // Lưu lại messageId để dùng cho việc track state
    final oldMessageId = message.messageId;

    // Lấy files đã lưu từ mapping
    final files = _failedMessageFiles[oldMessageId];
    final storedMessageType = _failedMessageTypes[oldMessageId];

    if (files == null || storedMessageType == null) {
      final mediaType = messageType == 2 ? 'ảnh' : 'video';
      AppToastHelper.showWarning(context, message: 'Không thể thử lại. Vui lòng chọn lại $mediaType.');

      if (!mounted) return;
      setState(() {
        _messagesDesc.removeWhere((m) => m.messageId == oldMessageId);
        _failedMessageIds.remove(oldMessageId);
        _uploadProgress.remove(oldMessageId);
        _failedMessageFiles.remove(oldMessageId);
        _failedMessageTypes.remove(oldMessageId);
      });
      return;
    }

    // Tạo temp message mới để hiển thị thumbnail và progress
    final tempId = 'temp-retry-${DateTime.now().microsecondsSinceEpoch}';
    final mediaType = storedMessageType == 2 ? 'ảnh' : 'video';
    final fileUrls = files.map((file) => file.path).join(',');

    final tempMessage = MessageData(
      messageId: tempId,
      roomId: (_room?.roomId)!,
      senderId: currentUserId,
      senderName: '',
      senderAvatar: null,
      message: 'Đang gửi lại $mediaType...',
      createdAt: DateTime.now().toIso8601String(),
      isRead: true,
      messageType: storedMessageType.toString(),
      fileUrl: fileUrls,
      thumbnails: null,
    );

    // Xóa message cũ và thêm temp message mới
    setState(() {
      final idx = _messagesDesc.indexWhere((m) => m.messageId == oldMessageId);
      if (idx != -1) {
        _messagesDesc[idx] = tempMessage;
      }
      _failedMessageIds.remove(oldMessageId);
      _pendingMessageIds.add(tempId);
      _uploadProgress[tempId] = 0.0;
    });
    _scrollToBottom();

    // Simulate progress updates
    _simulateUploadProgress(tempId, files);

    try {
      // For videos, use compressed version if available
      List<File> filesToSend = files;
      if (storedMessageType == 3) {
        filesToSend = files.map((file) {
          return _compressedVideos[file.path] ?? file;
        }).toList();
      }

      // For videos, ensure and collect thumbnails one-to-one with filesToSend
      List<File>? thumbnailsToSend;
      if (storedMessageType == 3) {
        // Wait for any ongoing compression before retrying
        await _waitForVideoCompression(files);
        await _ensureThumbnailsForVideos(filesToSend);
        final tmp = <File>[];
        for (final file in filesToSend) {
          final tp = _videoThumbnails[file.path];
          if (tp == null) {
            tmp.clear();
            break;
          }
          tmp.add(File(tp));
        }
        thumbnailsToSend = tmp.isEmpty ? null : tmp;
      }

      // Gửi lại với files đã lưu
      final response = await MessagingServiceApi.sendMedia(
        roomId: (_room?.roomId)!,
        files: filesToSend,
        messageType: storedMessageType,
        thumbnails: thumbnailsToSend,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        // Tạo updated message
        final updatedMessage = MessageData(
          messageId: response.data!.messageId,
          roomId: response.data!.roomId,
          senderId: currentUserId,
          senderName: response.data!.senderName,
          senderAvatar: response.data!.senderAvatar,
          message: response.data!.message,
          createdAt: response.data!.createdAt,
          isRead: response.data!.isRead,
          messageType: response.data!.messageType,
          fileUrl: response.data!.fileUrl,
          thumbnails: response.data!.thumbnails,
          metadata: response.data!.metadata,
        );

        setState(() {
          final idx = _messagesDesc.indexWhere((m) => m.messageId == tempId);
          if (idx != -1) {
            _messagesDesc[idx] = updatedMessage;
          }
          _pendingMessageIds.remove(tempId);
          _failedMessageIds.remove(oldMessageId);
          _retryingMessageIds.remove(oldMessageId);
          _uploadProgress.remove(tempId);
          _failedMessageFiles.remove(oldMessageId);
          _failedMessageTypes.remove(oldMessageId);
        });
        _scrollToBottom();
      } else {
        if (!mounted) return;
        setState(() {
          // Giữ lại message failed cũ
          _messagesDesc.insert(0, message);
          _pendingMessageIds.remove(tempId);
          _failedMessageIds.add(oldMessageId);
          _uploadProgress.remove(tempId);
        });
        AppToastHelper.showError(context, message: 'Gửi lại thất bại. Vui lòng thử lại.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Giữ lại message failed cũ
        _messagesDesc.insert(0, message);
        _pendingMessageIds.remove(tempId);
        _failedMessageIds.add(oldMessageId);
        _uploadProgress.remove(tempId);
      });
      AppToastHelper.showError(context, message: 'Có lỗi xảy ra khi gửi lại.');
    }
  }

  String _formatCurrency(num value) {
    final digits = value.toInt().toString();
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      buffer.write(digits[i]);
      final nextPos = len - i - 1;
      final isThousandBreak = nextPos % 3 == 0 && i != len - 1;
      if (isThousandBreak) buffer.write('.');
    }
    return buffer.toString();
  }

  Future<void> _pickImages() async {
    try {
      final maxAssetsCount = 3 - _selectedImages.length;
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(requestType: RequestType.image, maxAssets: maxAssetsCount),
      );

      if (result != null && result.isNotEmpty) {
        for (final asset in result) {
          final file = await asset.file;
          if (file != null) {
            setState(() {
              _selectedImages.add(file);
            });
          }
        }
      }
    } catch (e) {
      AppToastHelper.showError(context, message: 'Không thể chọn ảnh');
    }
  }

  Future<void> _pickVideos() async {
    try {
      final maxAssetsCount = 3 - _selectedVideos.length;
      if (maxAssetsCount <= 0) return;

      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(requestType: RequestType.video, maxAssets: maxAssetsCount),
      );

      if (result != null && result.isNotEmpty) {
        for (final asset in result) {
          final file = await asset.file;
          if (file != null) {
            final videoFile = file;
            final videoPath = videoFile.path;

            // Add video to selected list immediately to show in preview
            setState(() {
              _selectedVideos.add(videoFile);
            });

            // Generate thumbnail asynchronously (runs in background)
            _generateVideoThumbnail(videoPath);

            // Check file size - if larger than 50MB, compress it in background
            final fileSizeMB = videoFile.lengthSync() / (1024 * 1024);
            DebugLogger.log('[ChatRoom] Picked video: path=$videoPath, sizeMB=${fileSizeMB.toStringAsFixed(1)}');
            if (fileSizeMB > 50) {
              DebugLogger.log('[ChatRoom] Video > 50MB → start background compression: $videoPath');
              // Compress in background without blocking UI
              _compressVideoInBackground(videoFile);
            } else {
              DebugLogger.log('[ChatRoom] Video <= 50MB → skip compression: $videoPath');
            }
          }
        }
      }
    } catch (e) {
      DebugLogger.log('[ChatRoom] Error picking videos: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('Permission')) {
        AppToastHelper.showError(context, message: 'Vui lòng cấp quyền truy cập thư viện ảnh và video trong Cài đặt');
      } else {
        AppToastHelper.showError(context, message: 'Không thể chọn video. Vui lòng thử lại.');
      }
    }
  }

  void _clearSelectedMedia() {
    setState(() {
      _selectedImages.clear();
      _selectedVideos.clear();
      _compressionProgress.clear();
      _isCompressing.clear();
      _compressedVideos.clear();
      _videoThumbnails.clear();
      _generatingThumbnails.clear();
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      final videoFile = _selectedVideos[index];
      _selectedVideos.removeAt(index);
      // Clean up compression state for this video
      _compressionProgress.remove(videoFile.path);
      _isCompressing.remove(videoFile.path);
      _compressedVideos.remove(videoFile.path);
      // Clean up thumbnail state
      _videoThumbnails.remove(videoFile.path);
      _generatingThumbnails.remove(videoFile.path);
    });
  }

  Future<void> _compressVideoInBackground(File videoFile) async {
    final videoPath = videoFile.path;

    setState(() {
      _isCompressing[videoPath] = true;
      _compressionProgress[videoPath] = 0.0;
    });

    try {
      DebugLogger.log('[ChatRoom] Start compressing video: $videoPath');
      // Compress video with medium quality in background
      final compressionResult = await _videoCompressor.compressVideo(
        videoPath,
        const VVideoCompressionConfig.medium(),
        onProgress: (progress) {
          final int bucket = (progress * 20).floor(); // 5% per bucket
          if (_compressionProgressBuckets[videoPath] != bucket) {
            _compressionProgressBuckets[videoPath] = bucket;
            if (mounted) {
              setState(() {
                _compressionProgress[videoPath] = progress;
              });
            }
          }
          DebugLogger.log('[ChatRoom] Compress progress for $videoPath: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (compressionResult != null && mounted) {
        final compressedPath = compressionResult.compressedFilePath;
        DebugLogger.log(
            '[ChatRoom] Compress done: $videoPath -> $compressedPath | original=${compressionResult.originalSizeFormatted}, compressed=${compressionResult.compressedSizeFormatted}');

        // Copy thumbnail from original video to compressed video
        final originalThumbnail = _videoThumbnails[videoPath];
        if (originalThumbnail != null) {
          setState(() {
            _videoThumbnails[compressedPath] = originalThumbnail;
            // Also keep the original thumbnail mapping for the original path
            _videoThumbnails[videoPath] = originalThumbnail;
          });
        }

        // Keep original file in selection to maintain stable keys; store compressed for sending/preview
        setState(() {
          _compressedVideos[videoPath] = File(compressedPath);
          _isCompressing[videoPath] = false;
          _compressionProgress[videoPath] = 1.0;
          _compressionProgressBuckets[videoPath] = 20;
        });

        // // Show success message
        // AppToastHelper.showSuccess(
        //   context,
        //   message:
        //       'Video đã được nén thành công! Giảm từ ${compressionResult.originalSizeFormatted} xuống ${compressionResult.compressedSizeFormatted}',
        // );
      } else {
        if (mounted) {
          setState(() {
            _isCompressing[videoPath] = false;
            _compressionProgress.remove(videoPath);
            _compressionProgressBuckets.remove(videoPath);
          });
        }
        DebugLogger.log('[ChatRoom] Compress returned null for: $videoPath');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressing[videoPath] = false;
          _compressionProgress.remove(videoPath);
          _compressionProgressBuckets.remove(videoPath);
        });
      }
      DebugLogger.log('[ChatRoom] Error compressing video: $e');
    }
  }

  // Silently wait for any selected videos' compression to finish before sending
  Future<void> _waitForVideoCompression(List<File> videos) async {
    final Set<String> pathsToWait = {};
    for (final file in videos) {
      final path = file.path;
      bool needsCompression = false;
      try {
        final sizeMb = file.lengthSync() / (1024 * 1024);
        needsCompression = sizeMb > 50;
      } catch (_) {}
      if (_isCompressing[path] == true || needsCompression) {
        pathsToWait.add(path);
      }
    }
    if (pathsToWait.isEmpty) return;

    DebugLogger.largeJson('[ChatRoom] Waiting for compression to finish', {
      'videoCount': videos.length,
      'paths': pathsToWait.toList(),
    });
    while (mounted) {
      bool allDone = true;
      for (final path in pathsToWait) {
        if (_isCompressing[path] == true) {
          allDone = false;
          break;
        }
      }
      if (allDone) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    DebugLogger.log('[ChatRoom] Compression finished for all pending videos');
  }

  Future<void> _generateVideoThumbnail(String videoPath) async {
    DebugLogger.log('[ChatRoom] Starting thumbnail generation for: $videoPath');

    // Skip if already has thumbnail
    if (_videoThumbnails.containsKey(videoPath)) {
      DebugLogger.log('[ChatRoom] Thumbnail already exists, skipping');
      // Make sure to clear generating flag
      if (mounted && _generatingThumbnails.containsKey(videoPath)) {
        setState(() {
          _generatingThumbnails[videoPath] = false;
        });
      }
      return;
    }

    // If already generating, wait for it to complete
    if (_generatingThumbnails[videoPath] == true) {
      DebugLogger.log('[ChatRoom] Already generating thumbnail, will wait...');
      return;
    }

    // Mark as generating
    setState(() {
      _generatingThumbnails[videoPath] = true;
    });

    try {
      DebugLogger.log('[ChatRoom] Calling getVideoThumbnail for: $videoPath');

      final thumbnail = await _videoCompressor.getVideoThumbnail(
        videoPath,
        const VVideoThumbnailConfig(
          timeMs: 100, // 0.1 second into video
          maxWidth: 300,
          maxHeight: 200,
          format: VThumbnailFormat.jpeg,
          quality: 50,
        ),
      );

      DebugLogger.log('[ChatRoom] Thumbnail result - path: ${thumbnail?.thumbnailPath}');
      DebugLogger.log('[ChatRoom] Thumbnail result - not null: ${thumbnail != null}');

      if (thumbnail != null && mounted) {
        setState(() {
          _videoThumbnails[videoPath] = thumbnail.thumbnailPath;
          _generatingThumbnails[videoPath] = false;
        });
        // Compute and cache aspect ratio based on thumbnail image
        _computeAndCacheThumbnailAspect(thumbnail.thumbnailPath, videoPath);
        DebugLogger.log('[ChatRoom] Thumbnail saved successfully');
      } else if (mounted) {
        DebugLogger.log('[ChatRoom] Thumbnail is null or widget not mounted');
        setState(() {
          _generatingThumbnails[videoPath] = false;
        });
      }
    } catch (e, stackTrace) {
      DebugLogger.log('[ChatRoom] Error generating thumbnail: $e');
      DebugLogger.log('[ChatRoom] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _generatingThumbnails[videoPath] = false;
        });
      }
    }
  }

  // Compute width/height ratio from thumbnail file and cache it for sizing
  Future<void> _computeAndCacheThumbnailAspect(String thumbnailPath, String videoPath) async {
    try {
      final image = Image.file(File(thumbnailPath)).image;
      final ImageStream stream = image.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      final completer = Completer<void>();
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          final width = info.image.width.toDouble();
          final height = info.image.height.toDouble();
          if (width > 0 && height > 0) {
            final ratio = width / height;
            if (mounted) {
              setState(() {
                _videoAspectRatios[videoPath] = ratio;
              });
            } else {
              _videoAspectRatios[videoPath] = ratio;
            }
          }
          stream.removeListener(listener);
          completer.complete();
        },
        onError: (dynamic _, __) {
          stream.removeListener(listener);
          completer.complete();
        },
      );
      stream.addListener(listener);
      await completer.future;
    } catch (_) {}
  }

  // Ensure thumbnails exist for provided videos (one-to-one with file list)
  Future<void> _ensureThumbnailsForVideos(List<File> files) async {
    for (final file in files) {
      final path = file.path;
      if (!_videoThumbnails.containsKey(path) || (_videoThumbnails[path] == null)) {
        await _generateVideoThumbnail(path);
      }
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(text: 'Chọn phương thức', textStyle: 'head', textSize: '16', textColor: 'primary'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MyButton(
                    text: _selectedImages.length >= 3 ? 'Đã đủ ảnh (3/3)' : 'Chọn ảnh (${_selectedImages.length}/3)',
                    onPressed: _selectedImages.length >= 3
                        ? null
                        : () {
                            Navigator.pop(context);
                            _pickImages();
                          },
                    buttonType: _selectedImages.length >= 3 ? ButtonType.disable : ButtonType.primary,
                    height: 40,
                    textStyle: 'label',
                    textSize: '14',
                    textColor: 'invert',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MyButton(
                    text:
                        _selectedVideos.length >= 3 ? 'Đã đủ video (3/3)' : 'Chọn video (${_selectedVideos.length}/3)',
                    onPressed: _selectedVideos.length >= 3
                        ? null
                        : () {
                            Navigator.pop(context);
                            _pickVideos();
                          },
                    buttonType: _selectedVideos.length >= 3 ? ButtonType.disable : ButtonType.secondary,
                    height: 40,
                    textStyle: 'label',
                    textSize: '14',
                    textColor: 'primary',
                  ),
                ),
              ],
            ),
            // Commented out: Combined image and video picker
            // const SizedBox(height: 12),
            // MyButton(
            //   text:
            //       _selectedImages.length >= 3 && _selectedVideos.length >= 3
            //           ? 'Đã đủ file'
            //           : 'Chọn cả ảnh và video',
            //   onPressed:
            //       (_selectedImages.length >= 3 && _selectedVideos.length >= 3)
            //           ? null
            //           : () {
            //             Navigator.pop(context);
            //             _pickImagesAndVideos();
            //           },
            //   buttonType:
            //       (_selectedImages.length >= 3 && _selectedVideos.length >= 3)
            //           ? ButtonType.disable
            //           : ButtonType.primary,
            //   height: 40,
            //   textStyle: 'label',
            //   textSize: '14',
            //   textColor: 'invert',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(String mediaUrl, MessageData message, bool isUploading, double progress, bool isMe) {
    final messageType = int.tryParse(message.messageType ?? '1') ?? 1;

    // Check if this is a local file (during upload)
    final isLocalFile = mediaUrl.isNotEmpty &&
        !mediaUrl.startsWith('http') &&
        !mediaUrl.startsWith('[') &&
        mediaUrl.contains('/') &&
        !mediaUrl.contains('storage.googleapis.com');

    if (isLocalFile) {
      // Hiển thị thumbnail local khi đang upload
      final filePaths = mediaUrl.split(',');
      return _buildLocalMediaThumbnails(filePaths, isUploading, progress, isMe);
    } else if (mediaUrl.isNotEmpty) {
      // Hiển thị thumbnail từ server
      try {
        final urls = _parseFileUrls(mediaUrl);
        if (urls.isNotEmpty) {
          return _buildServerMediaThumbnails(urls, message, isMe);
        }
      } catch (e) {
        // Fallback cho single URL
        if (messageType == 3) {
          return _buildVideoThumbnail(mediaUrl, isMe);
        } else {
          return Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: MyText(
                  text: 'Không tải được ảnh',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: isMe ? 'invert' : 'tertiary',
                ),
              );
            },
          );
        }
      }
    }

    // Fallback to text message
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MyText(text: message.message, textStyle: 'body', textSize: '14', textColor: isMe ? 'invert' : 'primary'),
    );
  }

  List<String> _parseFileUrls(String mediaUrl) {
    try {
      // Try to parse as JSON array first
      if (mediaUrl.startsWith('[') && mediaUrl.endsWith(']')) {
        final List<dynamic> urls = json.decode(mediaUrl);
        return urls.map((url) => url.toString()).toList();
      }
      // If not JSON, return as single URL
      return [mediaUrl];
    } catch (e) {
      // If parsing fails, return as single URL
      return [mediaUrl];
    }
  }

  /// Parse thumbnail URLs from server (JSON array or comma-separated)
  List<String> _parseThumbnailUrls(String? thumbnails) {
    if (thumbnails == null || thumbnails.isEmpty) return [];

    try {
      if (thumbnails.startsWith('[') && thumbnails.endsWith(']')) {
        final List<dynamic> parsed = json.decode(thumbnails);
        return parsed.map((e) => e.toString().trim()).toList();
      } else {
        return thumbnails.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    } catch (e) {
      DebugLogger.log('[ChatRoom] Error parsing thumbnail URLs: $e');
      return thumbnails.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }

  /// Build play icon overlay for video thumbnails
  Widget _buildPlayIconOverlay({double size = 24, double iconSize = 16}) {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
          child: Icon(Icons.play_arrow, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }

  /// Build video thumbnail with smart fallback
  Widget _buildVideoThumbnailWidget({
    String? thumbnailUrl,
    required String videoUrl,
    double? size,
    double? width,
    double? height,
    bool expand = false,
    bool showPlayIcon = true,
  }) {
    final double w = width ?? size ?? 60;
    final double h = height ?? size ?? 60;
    // If thumbnail URL exists, try to load it
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Stack(
        children: [
          // Try network image first
          if (thumbnailUrl.startsWith('http'))
            (expand
                ? Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultVideoIcon(size: (size ?? w)),
                  )
                : Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    width: w,
                    height: h,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultVideoIcon(size: (size ?? w)),
                  ))
          // Otherwise try file
          else
            (expand
                ? Image.file(
                    File(thumbnailUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultVideoIcon(size: (size ?? w)),
                  )
                : Image.file(
                    File(thumbnailUrl),
                    fit: BoxFit.cover,
                    width: w,
                    height: h,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultVideoIcon(size: (size ?? w)),
                  )),
          // Play icon overlay
          if (showPlayIcon) _buildPlayIconOverlay(),
        ],
      );
    }

    // Fallback: show default video icon
    return _buildDefaultVideoIcon(size: size ?? 60);
  }

  /// Build default video icon placeholder
  Widget _buildDefaultVideoIcon({double size = 60, String? fileSize}) {
    return Container(
      color: DesignTokens.surfaceSecondary,
      child: fileSize != null && fileSize.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_file, size: 20, color: DesignTokens.primaryBlue),
                const SizedBox(height: 2),
                MyText(text: fileSize, textStyle: 'body', textSize: '10', textColor: 'tertiary'),
              ],
            )
          : const Icon(Icons.video_file, size: 20, color: DesignTokens.primaryBlue),
    );
  }

  Widget _buildServerMediaThumbnails(List<String> urls, MessageData message, bool isMe) {
    final messageType = int.tryParse(message.messageType ?? '1') ?? 1;
    final isVideo = messageType == 3;

    // Parse thumbnail URLs once
    final thumbnailUrls = isVideo ? _parseThumbnailUrls(message.thumbnails) : <String>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth == double.infinity ? MediaQuery.of(context).size.width * 0.6 : constraints.maxWidth;
        final spacing = 4.0;
        final int columns = urls.length == 1 ? 1 : 2;
        // Trừ padding 8 hai bên của Container để tính đúng bề rộng khả dụng
        final contentWidth = (maxWidth - 16).clamp(0, double.infinity) as double;
        final itemWidth = ((contentWidth - spacing * (columns - 1)) / columns).toDouble();

        // Chuẩn bị danh sách FileInfo để mở fullscreen viewer
        final List<FileInfo> files = urls.take(4).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final url = entry.value;
          final name = url.split('/').isNotEmpty ? url.split('/').last : 'media_$i';
          return FileInfo(id: i, name: name, path: url, timeUpload: '', fileType: isVideo ? 'video' : 'image');
        }).toList();

        return Container(
          width: maxWidth,
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
            runAlignment: isMe ? WrapAlignment.end : WrapAlignment.start,
            children: urls.take(4).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              // Pick matching thumbnail by index when available; fallback to first if only one provided
              String? thumbnailUrl;
              if (isVideo && thumbnailUrls.isNotEmpty) {
                if (thumbnailUrls.length > index) {
                  thumbnailUrl = thumbnailUrls[index];
                } else if (thumbnailUrls.length == 1) {
                  thumbnailUrl = thumbnailUrls.first;
                } else {
                  thumbnailUrl = null;
                }
              }
              final child = isVideo
                  ? _buildVideoThumbnailWidget(thumbnailUrl: thumbnailUrl, videoUrl: url, size: itemWidth)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: itemWidth,
                      height: itemWidth,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: itemWidth,
                          height: itemWidth,
                          color: DesignTokens.surfaceSecondary,
                          child: const Icon(Icons.broken_image, size: 20),
                        );
                      },
                    );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FullscreenImageViewer(files: files, initialIndex: index)),
                  );
                },
                child: Container(
                  width: itemWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DesignTokens.borderSecondary),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildVideoThumbnail(String videoUrl, bool isMe) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth == double.infinity ? MediaQuery.of(context).size.width * 0.6 : constraints.maxWidth;
        return Container(
          padding: const EdgeInsets.all(8),
          width: maxWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_file, size: 40, color: DesignTokens.primaryBlue),
                      const SizedBox(height: 8),
                      MyText(text: 'Video', textStyle: 'body', textSize: '12', textColor: isMe ? 'invert' : 'tertiary'),
                    ],
                  ),
                ),
              ),
              // Play button overlay
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocalMediaThumbnails(List<String> filePaths, bool isUploading, double progress, bool isMe) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth == double.infinity ? MediaQuery.of(context).size.width * 0.6 : constraints.maxWidth;
        final spacing = 4.0;
        final int columns = filePaths.length == 1 ? 1 : 2;
        // Trừ padding 8 hai bên của Container để tính đúng bề rộng khả dụng
        final contentWidth = (maxWidth - 16).clamp(0, double.infinity);
        final itemWidth = (contentWidth - spacing * (columns - 1)) / columns;
        final isSingle = filePaths.length == 1;

        // Chuẩn bị danh sách FileInfo cho fullscreen viewer
        final List<FileInfo> files = filePaths.take(4).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final path = entry.value;
          final name = path.split('/').isNotEmpty ? path.split('/').last : 'media_$i';
          final lower = path.toLowerCase();
          final isVid =
              lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv');
          return FileInfo(id: i, name: name, path: path, timeUpload: '', fileType: isVid ? 'video' : 'image');
        }).toList();

        return Container(
          width: maxWidth,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                runAlignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                children: filePaths.take(4).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  final file = File(path);
                  final isVideo = path.toLowerCase().contains('.mp4') ||
                      path.toLowerCase().contains('.mov') ||
                      path.toLowerCase().contains('.avi');

                  final double? singleVideoHeight = (isVideo && isSingle)
                      ? (contentWidth / (_videoAspectRatios[file.path] ?? (16.0 / 9.0))).toDouble()
                      : null;

                  final mediaChild = isVideo
                      ? (isSingle
                          ? SizedBox(
                              width: contentWidth.toDouble(),
                              height: singleVideoHeight!,
                              child: _buildVideoThumbnailForLocalFile(
                                file,
                                width: contentWidth.toDouble(),
                                height: singleVideoHeight,
                                expand: true,
                              ),
                            )
                          : _buildVideoThumbnailForLocalFile(file, width: itemWidth, height: itemWidth))
                      : Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: (isSingle ? contentWidth : itemWidth).toDouble(),
                          height: isSingle ? (contentWidth * 9.0 / 16.0).toDouble() : itemWidth.toDouble(),
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: (isSingle ? contentWidth : itemWidth).toDouble(),
                              height: isSingle ? (contentWidth * 9.0 / 16.0).toDouble() : itemWidth.toDouble(),
                              color: DesignTokens.surfaceSecondary,
                              child: const Icon(Icons.broken_image, size: 20),
                            );
                          },
                        );

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(files: files, initialIndex: index),
                            ),
                          );
                        },
                        child: Container(
                          width: (isSingle ? contentWidth : itemWidth).toDouble(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: DesignTokens.borderSecondary),
                          ),
                          clipBehavior: Clip.none,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: (isSingle ? contentWidth : itemWidth).toDouble(),
                              height: (isVideo && isSingle)
                                  ? singleVideoHeight!
                                  : (isSingle ? (contentWidth * 9.0 / 16.0).toDouble() : itemWidth.toDouble()),
                              child: Stack(
                                children: [
                                  mediaChild,
                                  if (isUploading)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              value: progress,
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                                              backgroundColor: Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Remove button remains outside so it is not clipped
                      if (isUploading) const SizedBox.shrink(), // placeholder to keep structure stable
                    ],
                  );
                }).toList(),
              ),
              if (filePaths.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: MyText(
                    text: '+${filePaths.length - 4} file khác',
                    textStyle: 'body',
                    textSize: '10',
                    textColor: isMe ? 'invert' : 'tertiary',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Widget riêng để hiển thị thumbnail cho video local
  Widget _buildVideoThumbnailForLocalFile(File file, {double? width, double? height, bool expand = false}) {
    final videoPath = file.path;
    final thumbnailPath = _videoThumbnails[videoPath];
    final isGeneratingThumbnail = _generatingThumbnails[videoPath] ?? false;

    // Hiển thị loading khi đang tạo thumbnail
    if (isGeneratingThumbnail) {
      return Container(
        width: width,
        height: height,
        color: DesignTokens.surfaceSecondary,
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // Hiển thị thumbnail nếu có
    if (thumbnailPath != null) {
      return _buildVideoThumbnailWidget(
        thumbnailUrl: thumbnailPath,
        videoUrl: file.path,
        width: width,
        height: height,
        expand: expand,
      );
    }

    // Fallback: hiển thị icon video với thông tin file
    return _buildDefaultVideoIcon(fileSize: _getFileSize(file));
  }

  String _getFileSize(File file) {
    try {
      if (file.existsSync()) {
        return '${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      // File doesn't exist or can't be accessed
    }
    return 'N/A';
  }

  Widget _buildVideoThumbnailPreview(
    File file,
    String? thumbnailPath,
    bool isGeneratingThumbnail,
    File? compressedFile,
  ) {
    // Hiển thị loading khi đang tạo thumbnail
    if (isGeneratingThumbnail) {
      return Container(
        color: DesignTokens.surfaceSecondary,
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // Hiển thị thumbnail nếu có
    if (thumbnailPath != null) {
      return _buildVideoThumbnailWidget(thumbnailUrl: thumbnailPath, videoUrl: file.path);
    }

    // Fallback: hiển thị icon video với thông tin file
    return _buildDefaultVideoIcon(fileSize: _getFileSize(compressedFile ?? file));
  }

  Widget _buildMediaPreviewItem({required File file, required bool isVideo, required VoidCallback onRemove}) {
    final compressedFile = _compressedVideos[file.path];

    // Get thumbnail - check both current file path and compressed file path
    String? thumbnailPath = _videoThumbnails[file.path];
    if (thumbnailPath == null && compressedFile != null) {
      thumbnailPath = _videoThumbnails[compressedFile.path];
    }

    final isGeneratingThumbnail = _generatingThumbnails[file.path] ?? false;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DesignTokens.borderSecondary),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isVideo
                  ? _buildVideoThumbnailPreview(file, thumbnailPath, isGeneratingThumbnail, compressedFile)
                  : Image.file(file, fit: BoxFit.cover),
            ),
          ),
          // Remove button
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: DesignTokens.alertError,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onEditQuotation() {
    if (_room?.quotationInfo == null) return;
    if ((_room!.quotationInfo!.id) == 0) {
      AppToastHelper.showError(context, message: 'Thiếu ID báo giá, không thể sửa.');
      return;
    }
    _showEditQuotationBottomSheet(_room!.quotationInfo!);
  }

  // Bottom sheet: Sửa báo giá
  void _showEditQuotationBottomSheet(QuotationModel quotation) {
    final TextEditingController priceController = TextEditingController(text: _formatCurrency(quotation.price));
    final TextEditingController descriptionController = TextEditingController(text: quotation.description);
    bool isSubmitting = false;

    String formatPrice(String value) {
      final onlyDigits = value.replaceAll(RegExp(r'[^\d]'), '');
      if (onlyDigits.isEmpty) return '';
      final number = int.tryParse(onlyDigits) ?? 0;
      return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    }

    int parsePrice(String formatted) {
      final onlyDigits = formatted.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(onlyDigits) ?? 0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (isSubmitting) return;
              final price = parsePrice(priceController.text);
              final desc = descriptionController.text.trim();
              if (price <= 0) {
                AppToastHelper.showError(context, message: 'Vui lòng nhập giá hợp lệ');
                return;
              }
              if (desc.isEmpty) {
                AppToastHelper.showWarning(context, message: 'Vui lòng nhập mô tả');
                return;
              }
              setModalState(() {
                isSubmitting = true;
              });
              try {
                final res = await QuotationServiceApi.updateQuotation(
                  quotationId: quotation.id,
                  price: price,
                  description: desc,
                  status: quotation.status,
                );
                if (res.success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  AppToastHelper.showSuccess(context, message: 'Cập nhật báo giá thành công');
                  // Báo rooms dirty để danh sách hội thoại cập nhật khi cần
                  MessagingEventBus().emitRoomsDirty();
                  // Refresh room info
                  final id = _room?.roomId;
                  if (id != null) {
                    final detail = await MessagingServiceApi.getRoomDetailWithMessages(roomId: id, limit: _limit);
                    if (!mounted || detail == null) return;
                    setState(() {
                      _room = detail.roomInfo;
                      // Merge messages while preserving existing
                      final merged = [..._messagesDesc];
                      for (final m in detail.messages) {
                        if (!merged.any((e) => e.messageId == m.messageId)) {
                          merged.add(m);
                        }
                      }
                      _messagesDesc = _sortDesc(merged);
                      _startAfterOffset = _messagesDesc.length;
                    });
                  }
                } else {
                  if (!mounted) return;
                  AppToastHelper.showError(context, message: res.message);
                }
              } catch (_) {
                if (!mounted) return;
                AppToastHelper.showError(context, message: 'Không thể cập nhật báo giá');
              } finally {
                if (mounted)
                  setModalState(() {
                    isSubmitting = false;
                  });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MyText(text: 'Sửa báo giá', textStyle: 'title', textSize: '16', textColor: 'primary'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MyTextField(
                      controller: priceController,
                      label: 'Giá*',
                      hintText: 'Nhập giá (VND)',
                      obscureText: false,
                      hasError: false,
                      keyboardType: TextInputType.number,
                      onChange: (value) {
                        final formatted = formatPrice(value);
                        if (formatted != value) {
                          priceController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    MyTextField(
                      controller: descriptionController,
                      label: 'Mô tả',
                      hintText: 'Nhập mô tả',
                      height: 120,
                      obscureText: false,
                      hasError: false,
                      maxLines: 5,
                      minLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MyButton(
                            text: 'Hủy',
                            height: 40,
                            onPressed: () => Navigator.pop(context),
                            buttonType: ButtonType.secondary,
                            textStyle: 'label',
                            textSize: '14',
                            textColor: 'primary',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MyButton(
                            text: isSubmitting ? 'Đang lưu...' : 'Lưu',
                            height: 40,
                            onPressed: isSubmitting ? null : submit,
                            buttonType: isSubmitting ? ButtonType.disable : ButtonType.primary,
                            textStyle: 'label',
                            textSize: '14',
                            textColor: 'primary',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServiceInfoCard() {
    return GestureDetector(
      onTap: () {
        // Navigate to request detail screen
        if (_room?.requestServiceInfo != null) {
          Navigator.pushNamed(context, '/request-detail', arguments: _room!.requestServiceInfo);
        }
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: DesignEffects.medCardShadow,
        ),
        child: _loading
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.line(height: 20, margin: const EdgeInsets.only(bottom: 4)),
                  Skeleton.line(height: 20, width: 180),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: (_room?.carInfo != null && _room!.carInfo!.isNotEmpty)
                                    ? _room!.carInfo!
                                    : ((_room?.requestCode != null && _room!.requestCode!.isNotEmpty)
                                        ? _room!.requestCode!
                                        : '—'),
                                textStyle: 'head',
                                textSize: '16',
                                textColor: 'primary',
                              ),
                            ),
                            if (isGarageUser && _room?.quotationInfo != null) ...[
                              MyButton(
                                text: 'Sửa báo giá',
                                onPressed: _onEditQuotation,
                                buttonType: ButtonType.primary,
                                width: 93,
                                height: 30,
                                textStyle: 'label',
                                textSize: '12',
                                textColor: 'invert',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: (_room?.serviceDescription != null && _room!.serviceDescription!.isNotEmpty)
                                    ? _room!.serviceDescription!
                                    : ((_room?.statusText != null && _room!.statusText!.isNotEmpty)
                                        ? _room!.statusText!
                                        : '—'),
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'secondary',
                              ),
                            ),
                            if (isGarageUser && _room?.quotationInfo != null) ...[
                              const SizedBox(width: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  MyText(text: 'Giá:', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                                  const SizedBox(width: 6),
                                  MyText(
                                    text: '${_formatCurrency(_room!.quotationInfo!.price)} đ',
                                    textStyle: 'head',
                                    textSize: '16',
                                    textColor: 'brand',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right: edit button + price (when has quotation)
                ],
              ),
      ),
    );
  }

  Widget _buildListMessagesSkeleton() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // avatar skeleton removed per request
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DesignTokens.borderSecondary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.line(height: 14, width: 140),
                      const SizedBox(height: 6),
                      Skeleton.line(height: 10, width: 60),
                    ],
                  ),
                ),
              ),
              // avatar skeleton removed per request
            ],
          ),
        );
      },
    );
  }

  String _formatMessageTime(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inDays > 0) {
        return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timeString;
    }
  }

  Widget _buildLoadingItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          MyText(text: 'Đang tải thêm tin nhắn...', textStyle: 'body', textSize: '12', textColor: 'secondary'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: DesignTokens.surfacePrimary,
      body: KeyboardDismissWrapper(
        enableScroll: false,
        child: Stack(
          children: [
            // Background like Home: blue top and white bottom
            Column(
              children: [
                Container(
                  height: 105,
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceBrand,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(child: Container(decoration: BoxDecoration(color: DesignTokens.surfaceSecondary))),
                Container(height: 10, color: DesignTokens.surfaceSecondary),
              ],
            ),

            // Foreground content
            Column(
              children: [
                MyHeader(
                  title: _room?.otherUserName ?? 'Tin nhắn',
                  showLeftButton: true,
                  onLeftPressed: () => Navigator.pop(context),
                  customTitle: MyText(
                    text: _room?.otherUserName ?? 'Tin nhắn',
                    textStyle: 'head',
                    textSize: '16',
                    textColor: 'invert',
                  ),
                  leftIconColor: DesignTokens.textInvert,
                ),

                ServiceInfoCard(
                  loading: false,
                  room: _room,
                  isGarageUser: true,
                  onEditQuotation: () {},
                ),

                // Messages list
                Expanded(
                  child: _loading
                      ? _buildListMessagesSkeleton()
                      : _messagesDesc.isEmpty
                          ? Center(
                              child: MyText(
                                text: 'Chưa có tin nhắn nào',
                                textStyle: 'body',
                                textSize: '16',
                                textColor: 'placeholder',
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _messagesDesc.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Nếu đang loading và đây là item cuối cùng (tin nhắn cũ nhất)
                                if (_loadingMore && index == _messagesDesc.length) {
                                  return _buildLoadingItem();
                                }
                                final message = _messagesDesc[index];
                                return _buildMessageBubble(message);
                              },
                            ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceSecondary,
                    border: Border(top: BorderSide(color: DesignTokens.borderSecondary)),
                  ),
                  child: Column(
                    children: [
                      // Selected media preview
                      if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with clear all button
                              Row(
                                children: [
                                  MyText(
                                    text: 'Đã chọn ${_selectedImages.length + _selectedVideos.length} file',
                                    textStyle: 'body',
                                    textSize: '12',
                                    textColor: 'secondary',
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 28,
                                    child: MyButton(
                                      text: 'Xóa tất cả',
                                      onPressed: _clearSelectedMedia,
                                      buttonType: ButtonType.red,
                                      width: 100,
                                      height: 28,
                                      textStyle: 'label',
                                      textSize: '12',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Horizontal scrollable list
                              Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(vertical: 0),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // Images
                                    ..._selectedImages.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final file = entry.value;
                                      return _buildMediaPreviewItem(
                                        file: file,
                                        isVideo: false,
                                        onRemove: () => _removeImage(index),
                                      );
                                    }),
                                    // Videos
                                    ..._selectedVideos.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final file = entry.value;
                                      return _buildMediaPreviewItem(
                                        file: file,
                                        isVideo: true,
                                        onRemove: () => _removeVideo(index),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Input row
                      Row(
                        children: [
                          // Attachment button
                          GestureDetector(
                            onTap: _showMediaOptions,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: DesignTokens.primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Message input field
                          Expanded(
                            child: MyTextField(
                              controller: _messageController,
                              hintText: 'Message...',
                              height: 44,
                              maxLines: 1,
                              obscureText: false,
                              hasError: false,
                              focusNode: _inputFocusNode,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Send button
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: DesignTokens.primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Badge thông báo tin nhắn mới (nằm trên Stack)
            if (_newIncomingCount > 0 && !_isAtBottom)
              Positioned(
                bottom: 76,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _scrollToBottom();
                      setState(() {
                        _newIncomingCount = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: DesignEffects.medCardShadow,
                      ),
                      child: MyText(
                        text: '$_newIncomingCount tin nhắn mới',
                        textStyle: 'label',
                        textSize: '12',
                        textColor: 'invert',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageData message) {
    final isMe = message.senderId == currentUserId;
    final type = int.tryParse(message.messageType ?? '1') ?? 1;

    // Helper: status line centered (types 4,6,7)
    Widget buildCenterLine(String text, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [MyText(text: text, textStyle: 'label', textSize: '12', color: color ?? DesignTokens.textTertiary)],
        ),
      );
    }

    // Booking card (type 5)
    Widget buildBookingCard() {
      final md = message.metadata ?? const {};
      DebugLogger.largeJson('[ChatRoom] buildBookingCard metadata', {
        'messageId': message.messageId,
        'metadata': md,
        'metadataKeys': md.keys.toList(),
      });
      final garageName = (md['garage_name'] ?? md['garage'] ?? 'Smart Auto Care').toString();
      final time = (md['time'] ?? md['booking_time'] ?? md['schedule_time'] ?? '').toString();
      final priceNum = int.tryParse((md['price'] ?? md['quotation']?['price'] ?? '0').toString()) ?? 0;
      final statusString = (md['deposit_status'] ?? '').toString();
      final statusValue = int.tryParse(statusString) ?? 4;
      final quotationStatus = QuotationStatus.fromValue(statusValue);

      return Column(
        children: [
          // Centerline message above booking card
          if (message.message.isNotEmpty) buildCenterLine(message.message),

          // Booking card - always centered, no avatar
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.surfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: DesignEffects.medCardShadow,
                  border: Border.all(color: DesignTokens.borderBrandSecondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MyText(text: garageName, textStyle: 'head', textSize: '14', textColor: 'primary'),
                        ),
                        StatusWidget(status: quotationStatus, type: StatusType.quotation),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MyText(text: 'Thời gian:', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                        ),
                        MyText(
                          text: time.isNotEmpty ? time : '—',
                          textStyle: 'title',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: MyText(text: 'Giá:', textStyle: 'body', textSize: '14', textColor: 'tertiary')),
                        MyText(
                          text: '${_formatCurrency(priceNum)}đ',
                          textStyle: 'head',
                          textSize: '16',
                          textColor: 'brand',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Image bubble (type 2)
    Widget buildImageBubble() {
      final imageUrl = message.fileUrl ?? '';
      final isUploading = _pendingMessageIds.contains(message.messageId);
      final progress = _uploadProgress[message.messageId] ?? 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: DesignTokens.primaryBlue, borderRadius: BorderRadius.circular(20)),
                    child: (_room?.otherUserAvatar != null && _room!.otherUserAvatar!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _room!.otherUserAvatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: SvgIcon(
                                    svgPath: 'assets/icons_final/profile.svg',
                                    size: 20,
                                    color: Colors.white,
                                    fit: BoxFit.scaleDown,
                                  ),
                                );
                              },
                            ),
                          )
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/profile.svg',
                              size: 20,
                              color: Colors.white,
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Builder(
                    builder: (context) {
                      final maxWidth = MediaQuery.of(context).size.width * 0.6;
                      // Khi là isMe: không có nền, chỉ hiển thị thumbnail, cố định bề rộng = 70% màn hình
                      if (isMe) {
                        return SizedBox(
                          width: maxWidth,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildMediaContent(imageUrl, message, isUploading, progress, isMe),
                          ),
                        );
                      }
                      // Không phải isMe: giữ nền xám như cũ, nhưng cũng giới hạn bề rộng = 70%
                      return SizedBox(
                        width: maxWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: DesignTokens.surfaceSecondary,
                            child: _buildMediaContent(imageUrl, message, isUploading, progress, isMe),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Removed avatar for current user (isMe) as per requirement
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: isMe ? 0 : 48 + 12), // align time with media, not avatar
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (isMe && _failedMessageIds.contains(message.messageId)) ...[
                    GestureDetector(
                      onTap: () => _retrySendMedia(message, 2),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            padding: const EdgeInsets.all(2),
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/reload.svg',
                              size: 12,
                              color: DesignTokens.primaryBlue,
                            ),
                          ),
                          MyText(text: "Thử lại", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (isMe && _retryingMessageIds.contains(message.messageId)) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 4),
                        MyText(text: "Đang thử lại...", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                      ],
                    ),
                    const SizedBox(width: 6),
                  ],
                  MyText(
                    text: _formatMessageTime(message.createdAt),
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'placeholder',
                  ),
                  if (isMe && _pendingMessageIds.contains(message.messageId)) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Video bubble (type 3)
    Widget buildVideoBubble() {
      final videoUrl = message.fileUrl ?? '';
      final isUploading = _pendingMessageIds.contains(message.messageId);
      final progress = _uploadProgress[message.messageId] ?? 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: (_room?.otherUserAvatar != null && _room!.otherUserAvatar!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _room!.otherUserAvatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: SvgIcon(
                                    svgPath: 'assets/icons_final/profile.svg',
                                    size: 20,
                                    color: Colors.white,
                                    fit: BoxFit.scaleDown,
                                  ),
                                );
                              },
                            ),
                          )
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/profile.svg',
                              size: 20,
                              color: Colors.white,
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Builder(
                    builder: (context) {
                      final maxWidth = MediaQuery.of(context).size.width * 0.6;
                      if (isMe) {
                        return SizedBox(
                          width: maxWidth,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildMediaContent(videoUrl, message, isUploading, progress, isMe),
                          ),
                        );
                      }
                      return SizedBox(
                        width: maxWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: DesignTokens.surfaceSecondary,
                            child: _buildMediaContent(videoUrl, message, isUploading, progress, isMe),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Removed avatar for current user (isMe) as per requirement
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: isMe ? 0 : 48), // align time with media, not avatar
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (isMe && _failedMessageIds.contains(message.messageId)) ...[
                    GestureDetector(
                      onTap: () => _retrySendMedia(message, 3),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            padding: const EdgeInsets.all(2),
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/reload.svg',
                              size: 12,
                              color: DesignTokens.primaryBlue,
                            ),
                          ),
                          MyText(text: "Thử lại", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (isMe && _retryingMessageIds.contains(message.messageId)) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 4),
                        MyText(text: "Đang thử lại...", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                      ],
                    ),
                    const SizedBox(width: 6),
                  ],
                  MyText(
                    text: _formatMessageTime(message.createdAt),
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'placeholder',
                  ),
                  if (isMe && _pendingMessageIds.contains(message.messageId)) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For status-only messages
    if (type == 4 || type == 6) {
      return buildCenterLine(message.message);
    }
    if (type == 7) {
      return buildCenterLine(message.message, color: DesignTokens.alertError);
    }
    if (type == 5) {
      return buildBookingCard();
    }
    if (type == 2) {
      return buildImageBubble();
    }
    if (type == 3) {
      return buildVideoBubble();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Avatar for other user - use roomData.otherUserAvatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: DesignTokens.primaryBlue, borderRadius: BorderRadius.circular(20)),
              child: (_room?.otherUserAvatar != null && _room!.otherUserAvatar!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _room!.otherUserAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/profile.svg',
                              size: 20,
                              color: Colors.white,
                              fit: BoxFit.scaleDown,
                            ),
                          );
                        },
                      ),
                    )
                  : SizedBox(
                      width: 20,
                      height: 20,
                      child: SvgIcon(
                        svgPath: 'assets/icons_final/profile.svg',
                        size: 20,
                        color: Colors.white,
                        fit: BoxFit.scaleDown,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? DesignTokens.surfaceBrand : DesignTokens.surfacePrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: !isMe ? Border.all(color: DesignTokens.borderSecondary) : null,
                  ),
                  child: MyText(
                    text: message.message,
                    textStyle: 'body',
                    textSize: '14',
                    textColor: isMe ? 'invert' : 'primary',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (isMe && _failedMessageIds.contains(message.messageId)) ...[
                      GestureDetector(
                        onTap: () => _retrySend(message.messageId),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              padding: const EdgeInsets.all(2),
                              child: SvgIcon(
                                svgPath: 'assets/icons_final/reload.svg',
                                size: 12,
                                color: DesignTokens.primaryBlue,
                              ),
                            ),
                            MyText(text: "Thử lại", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (isMe && _retryingMessageIds.contains(message.messageId)) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                            ),
                          ),
                          const SizedBox(width: 4),
                          MyText(text: "Đang thử lại...", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                        ],
                      ),
                      const SizedBox(width: 6),
                    ],
                    MyText(
                      text: _formatMessageTime(message.createdAt),
                      textStyle: 'body',
                      textSize: '12',
                      textColor: 'placeholder',
                    ),
                    if (isMe && _pendingMessageIds.contains(message.messageId)) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                        ),
                      ),
                    ],
                    if (!isMe && _failedMessageIds.contains(message.messageId)) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _retrySend(message.messageId),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              padding: const EdgeInsets.all(2),
                              child: SvgIcon(
                                svgPath: 'assets/icons_final/reload.svg',
                                size: 12,
                                color: DesignTokens.alertError,
                              ),
                            ),
                            const SizedBox(width: 4),
                            MyText(text: "Thử lại", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                          ],
                        ),
                      ),
                    ],
                    if (!isMe && _retryingMessageIds.contains(message.messageId)) ...[
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                            ),
                          ),
                          const SizedBox(width: 4),
                          MyText(text: "Đang thử lại...", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Removed avatar for current user (isMe) as per requirement
        ],
      ),
    );
  }
}
