import 'package:flutter/material.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'dart:async';
import 'dart:io';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
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
  File? _selectedImage;
  File? _selectedVideo;
  final ImagePicker _imagePicker = ImagePicker();

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
    _newMessageSub = MessagingEventBus().onNewMessage.listen(
      _onNewMessageEvent,
    );
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
    if (extentAfter < 200 && 
        !_loadingMore && 
        (_room?.roomId) != null && 
        _messagesDesc.isNotEmpty) {
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
    );
    setState(() {
      // Tránh trùng lặp
      final exists = _messagesDesc.any((m) => m.messageId == newMsg.messageId);
      if (!exists) {
        // Insert vào đầu danh sách DESC
        _messagesDesc.insert(0, newMsg);
        DebugLogger.largeJson('[ChatRoom] message inserted at head', {
          'listLength': _messagesDesc.length,
          'firstId':
              _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
        });
        if (_isAtBottom) {
          // Nếu đang ở đáy thì tự cuộn xuống để thấy tin mới
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        } else {
          _newIncomingCount += 1;
        }
      } else {
        DebugLogger.log(
          '[ChatRoom] message already exists in list, skip append',
        );
      }
    });

    // Fallback đồng bộ nhẹ nếu vì lý do nào đó chưa thấy trong danh sách
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final stillMissing =
          !_messagesDesc.any((m) => m.messageId == event.messageId);
      if (stillMissing && (_room?.roomId) != null) {
        DebugLogger.log(
          '[ChatRoom] fallback fetch latest messages due to missing new message',
        );
        try {
          final detail = await MessagingServiceApi.getRoomDetailWithMessages(
            roomId: _room!.roomId,
            limit: _limit,
          );
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
      DebugLogger.largeJson('[ChatRoomScreen] init args', {
        'args': args?.toString(),
        'roomId': id,
      });
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
        DebugLogger.largeJson(
          '[ChatRoomScreen] call getRoomDetailWithMessages',
          {
            'roomId': id,
            'limit': _limit,
            'startAfter': _startAfterOffset,
            'state_len': _messagesDesc.length,
            'state_firstId':
                _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
            'state_lastId':
                _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
            'isAtBottom': _isAtBottom,
            'newIncoming': _newIncomingCount,
          },
        );
        final detail = await MessagingServiceApi.getRoomDetailWithMessages(
          roomId: id,
          limit: _limit,
          startAfterOffset: _startAfterOffset,
        );
        DebugLogger.largeJson('[ChatRoomScreen] fetch completed', {
          'detail_null': detail == null,
          'mounted': mounted,
        });
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
            'firstId':
                _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
            'firstCreatedAt':
                _messagesDesc.isNotEmpty ? _messagesDesc.first.createdAt : null,
            'lastId':
                _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
            'lastCreatedAt':
                _messagesDesc.isNotEmpty ? _messagesDesc.last.createdAt : null,
          });
          _ensureInitialScrollToBottom();
          // _markOpponentMessagesRead();
          return;
        }
        DebugLogger.log(
          '[ChatRoomScreen] getRoomDetailWithMessages returned null',
        );
      }
    } catch (e, st) {
      DebugLogger.largeJson('[ChatRoomScreen] init error', {
        'error': e.toString(),
        'stack': st.toString(),
      });
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
      DebugLogger.largeJson(
        '[ChatRoomScreen] call getRoomDetailWithMessages (loadMore)',
        {
          'roomId': id,
          'limit': _limit,
          'startAfter': _startAfterOffset,
          'state_len': _messagesDesc.length,
          'state_firstId':
              _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
          'state_lastId':
              _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
          'isAtBottom': _isAtBottom,
          'newIncoming': _newIncomingCount,
        },
      );
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
          final toAppend = newMessages.where(
            (m) => !_messagesDesc.any((e) => e.messageId == m.messageId),
          );
          _messagesDesc.addAll(toAppend);
          appendedCount = _messagesDesc.length - oldLen;
          // Không jump; Flutter giữ vị trí ổn với reverse:true
          DebugLogger.log(
            '[ChatRoom] appended older messages: +$appendedCount',
          );
        }
        // Offset tăng theo tổng số item đã có
        _startAfterOffset = _messagesDesc.length;
        _loading = false;
        _loadingMore = false;
      });
      DebugLogger.largeJson('[ChatRoomScreen] after loadMore append', {
        'len': _messagesDesc.length,
        'firstId':
            _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null,
        'firstCreatedAt':
            _messagesDesc.isNotEmpty ? _messagesDesc.first.createdAt : null,
        'lastId':
            _messagesDesc.isNotEmpty ? _messagesDesc.last.messageId : null,
        'lastCreatedAt':
            _messagesDesc.isNotEmpty ? _messagesDesc.last.createdAt : null,
        'startAfter_next': _startAfterOffset,
      });

      // Fallback: nếu server trả về trùng trang (bỏ qua start_after) → thử dịch cursor 1 lần
      try {
        if (!initial &&
            appendedCount == 0 &&
            detail.messages.isNotEmpty &&
            !_loadMoreRetrying) {
          final serverFirstId = detail.messages.first.messageId;
          final currentFirstId =
              _messagesDesc.isNotEmpty ? _messagesDesc.first.messageId : null;
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
      AppToastHelper.showError(
        context,
        message: 'Không thể tải tin nhắn. Vui lòng thử lại sau.',
      );
    }
  }


  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final hasMedia = _selectedImage != null || _selectedVideo != null;

    if (content.isEmpty && !hasMedia) return;

    // Build a temporary local message for optimistic UI
    final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
    final messageType =
        _selectedImage != null ? '2' : (_selectedVideo != null ? '3' : '1');
    final tempMessage = MessageData(
      messageId: tempId,
      roomId: (_room?.roomId)!,
      senderId: currentUserId,
      senderName: '',
      senderAvatar: null,
      message: content,
      createdAt: DateTime.now().toIso8601String(),
      isRead: true,
      messageType: messageType,
    );

    setState(() {
      // Chèn vào đầu danh sách DESC
      _messagesDesc.insert(0, tempMessage);
      _pendingMessageIds.add(tempId);
      _localMessageContentById[tempId] = content;
      _messageController.clear();
      // Clear selected media after sending
      _selectedImage = null;
      _selectedVideo = null;
    });
    _scrollToBottom();

    // Fire the API call without blocking UI
    try {
      final response = await MessagingServiceApi.sendMessage(
        roomId: (_room?.roomId)!,
        message: content,
        messageType: int.parse(messageType),
        // TODO: Add file upload support when API is ready
        // file: _selectedImage ?? _selectedVideo,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        // Replace temp message with server message
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
      DebugLogger.largeJson('[ChatRoomScreen] send error', {
        'error': e.toString(),
      });
      setState(() {
        _pendingMessageIds.remove(tempId);
        _failedMessageIds.add(tempId);
      });
    }
  }

  Future<void> _retrySend(String localMessageId) async {
    final content = _localMessageContentById[localMessageId];
    if (content == null || (_room?.roomId) == null) return;

    DebugLogger.log('[ChatRoom] _retrySend started for message: $localMessageId');

    // Ngay lập tức chuyển sang trạng thái retrying để hiển thị phản hồi
    setState(() {
      _failedMessageIds.remove(localMessageId);
      _retryingMessageIds.add(localMessageId);
    });
    
    DebugLogger.log('[ChatRoom] Message moved to retrying state: $localMessageId');
    DebugLogger.log('[ChatRoom] Current retrying set: $_retryingMessageIds');

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
          final idx = _messagesDesc.indexWhere(
            (m) => m.messageId == localMessageId,
          );
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
        AppToastHelper.showError(
          context,
          message: 'Gửi tin nhắn thất bại. Vui lòng thử lại.',
        );
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
      AppToastHelper.showError(
        context,
        message: 'Có lỗi xảy ra. Vui lòng thử lại.',
      );
      setState(() {
        _retryingMessageIds.remove(localMessageId);
        _failedMessageIds.add(localMessageId);
      });
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedVideo = null;
        });
      }
    } catch (e) {
      AppToastHelper.showError(context, message: 'Không thể chọn ảnh');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          _selectedImage = null;
        });
      }
    } catch (e) {
      AppToastHelper.showError(context, message: 'Không thể chọn video');
    }
  }

  void _clearSelectedMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(
                  text: 'Chọn phương thức',
                  textStyle: 'head',
                  textSize: '16',
                  textColor: 'primary',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: 'Chọn ảnh',
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage();
                        },
                        buttonType: ButtonType.primary,
                        height: 40,
                        textStyle: 'label',
                        textSize: '14',
                        textColor: 'invert',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MyButton(
                        text: 'Chọn video',
                        onPressed: () {
                          Navigator.pop(context);
                          _pickVideo();
                        },
                        buttonType: ButtonType.secondary,
                        height: 40,
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
  }

  void _onEditQuotation() {
    if (_room?.quotationInfo == null) return;
    if ((_room!.quotationInfo!.id) == 0) {
      AppToastHelper.showError(
        context,
        message: 'Thiếu ID báo giá, không thể sửa.',
      );
      return;
    }
    _showEditQuotationBottomSheet(_room!.quotationInfo!);
  }

  // Bottom sheet: Sửa báo giá
  void _showEditQuotationBottomSheet(QuotationModel quotation) {
    final TextEditingController priceController = TextEditingController(
      text: _formatCurrency(quotation.price),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: quotation.description,
    );
    bool isSubmitting = false;

    String formatPrice(String value) {
      final onlyDigits = value.replaceAll(RegExp(r'[^\d]'), '');
      if (onlyDigits.isEmpty) return '';
      final number = int.tryParse(onlyDigits) ?? 0;
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
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
                AppToastHelper.showError(
                  context,
                  message: 'Vui lòng nhập giá hợp lệ',
                );
                return;
              }
              if (desc.isEmpty) {
                AppToastHelper.showWarning(
                  context,
                  message: 'Vui lòng nhập mô tả',
                );
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
                  AppToastHelper.showSuccess(
                    context,
                    message: 'Cập nhật báo giá thành công',
                  );
                  // Báo rooms dirty để danh sách hội thoại cập nhật khi cần
                  MessagingEventBus().emitRoomsDirty();
                  // Refresh room info
                  final id = _room?.roomId;
                  if (id != null) {
                    final detail =
                        await MessagingServiceApi.getRoomDetailWithMessages(
                          roomId: id,
                          limit: _limit,
                        );
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
                AppToastHelper.showError(
                  context,
                  message: 'Không thể cập nhật báo giá',
                );
              } finally {
                if (mounted)
                  setModalState(() {
                    isSubmitting = false;
                  });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MyText(
                            text: 'Sửa báo giá',
                            textStyle: 'title',
                            textSize: '16',
                            textColor: 'primary',
                          ),
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
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
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
                            buttonType:
                                isSubmitting
                                    ? ButtonType.disable
                                    : ButtonType.primary,
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
          Navigator.pushNamed(
            context,
            '/request-detail',
            arguments: _room!.requestServiceInfo,
          );
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
        child:
            _loading
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.line(
                      height: 20,
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
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
                                  text:
                                      (_room?.carInfo != null &&
                                              _room!.carInfo!.isNotEmpty)
                                          ? _room!.carInfo!
                                          : ((_room?.requestCode != null &&
                                                  _room!
                                                      .requestCode!
                                                      .isNotEmpty)
                                              ? _room!.requestCode!
                                              : '—'),
                                  textStyle: 'head',
                                  textSize: '16',
                                  textColor: 'primary',
                                ),
                              ),
                              if (isGarageUser &&
                                  _room?.quotationInfo != null) ...[
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
                                  text:
                                      (_room?.serviceDescription != null &&
                                              _room!
                                                  .serviceDescription!
                                                  .isNotEmpty)
                                          ? _room!.serviceDescription!
                                          : ((_room?.statusText != null &&
                                                  _room!.statusText!.isNotEmpty)
                                              ? _room!.statusText!
                                              : '—'),
                                  textStyle: 'body',
                                  textSize: '14',
                                  textColor: 'secondary',
                                ),
                              ),
                              if (isGarageUser &&
                                  _room?.quotationInfo != null) ...[
                                const SizedBox(width: 12),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    MyText(
                                      text: 'Giá:',
                                      textStyle: 'body',
                                      textSize: '14',
                                      textColor: 'tertiary',
                                    ),
                                    const SizedBox(width: 6),
                                    MyText(
                                      text:
                                          '${_formatCurrency(_room!.quotationInfo!.price)} đ',
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
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // avatar skeleton removed per request
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          MyText(
            text: 'Đang tải thêm tin nhắn...',
            textStyle: 'body',
            textSize: '12',
            textColor: 'secondary',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
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
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceSecondary,
                    ),
                  ),
                ),
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
                  showRightButton: true,
                  customTitle: MyText(
                    text: _room?.otherUserName ?? 'Tin nhắn',
                    textStyle: 'head',
                    textSize: '16',
                    textColor: 'invert',
                  ),
                  leftIconColor: DesignTokens.textInvert,
                ),

                _buildServiceInfoCard(),

                // Messages list
                Expanded(
                  child:
                      _loading
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceSecondary,
                    border: Border(
                      top: BorderSide(color: DesignTokens.borderSecondary),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Selected media preview
                      if (_selectedImage != null || _selectedVideo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Media preview
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: DesignTokens.borderSecondary,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      _selectedImage != null
                                          ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          )
                                          : _selectedVideo != null
                                          ? Container(
                                            color:
                                                DesignTokens.surfaceSecondary,
                                            child: const Icon(
                                              Icons.video_file,
                                              size: 24,
                                            ),
                                          )
                                          : Container(
                                            color:
                                                DesignTokens.surfaceSecondary,
                                            child: const Icon(Icons.video_file),
                                          ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Media info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText(
                                      text:
                                          _selectedImage != null
                                              ? 'Ảnh đã chọn'
                                              : 'Video đã chọn',
                                      textStyle: 'body',
                                      textSize: '12',
                                      textColor: 'secondary',
                                    ),
                                    if (_selectedVideo != null)
                                      MyText(
                                        text:
                                            '${(_selectedVideo!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                                        textStyle: 'body',
                                        textSize: '10',
                                        textColor: 'tertiary',
                                      ),
                                  ],
                                ),
                              ),
                              // Remove button
                              GestureDetector(
                                onTap: _clearSelectedMedia,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: DesignTokens.alertError,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
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
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
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
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 20,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: DesignEffects.medCardShadow,
                      ),
                      child: MyText(
                        text: '${_newIncomingCount} tin nhắn mới',
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
    
    // Debug log để kiểm tra trạng thái
    if (isMe) {
      DebugLogger.log('[ChatRoom] Message ${message.messageId} states: failed=${_failedMessageIds.contains(message.messageId)}, retrying=${_retryingMessageIds.contains(message.messageId)}, pending=${_pendingMessageIds.contains(message.messageId)}');
    }

    // Helper: status line centered (types 4,6,7)
    Widget buildCenterLine(String text, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyText(
              text: text,
              textStyle: 'label',
              textSize: '12',
              color: color ?? DesignTokens.textTertiary,
            ),
          ],
        ),
      );
    }

    // Booking card (type 5)
    Widget buildBookingCard() {
      final md = message.metadata ?? const {};
      final garageName =
          (md['garage_name'] ?? md['garage'] ?? 'Smart Auto Care').toString();
      final time =
          (md['time'] ?? md['booking_time'] ?? md['schedule_time'] ?? '')
              .toString();
      final priceNum =
          int.tryParse(
            (md['price'] ?? md['quotation']?['price'] ?? '0').toString(),
          ) ??
          0;
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
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
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
                          child: MyText(
                            text: garageName,
                            textStyle: 'head',
                            textSize: '14',
                            textColor: 'primary',
                          ),
                        ),
                        StatusWidget(
                          status: quotationStatus,
                          type: StatusType.quotation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MyText(
                            text: 'Thời gian:',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'tertiary',
                          ),
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
                        Expanded(
                          child: MyText(
                            text: 'Giá:',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'tertiary',
                          ),
                        ),
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    (_room?.otherUserAvatar != null &&
                            _room!.otherUserAvatar!.isNotEmpty)
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color:
                      isMe
                          ? DesignTokens.primaryBlue
                          : DesignTokens.surfaceSecondary,
                  child:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
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
                          )
                          : Padding(
                            padding: const EdgeInsets.all(12),
                            child: MyText(
                              text: message.message,
                              textStyle: 'body',
                              textSize: '14',
                              textColor: isMe ? 'invert' : 'primary',
                            ),
                          ),
                ),
              ),
            ),
            // Removed avatar for current user (isMe) as per requirement
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Avatar for other user - use roomData.otherUserAvatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  (_room?.otherUserAvatar != null &&
                          _room!.otherUserAvatar!.isNotEmpty)
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
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? DesignTokens.surfaceBrand
                            : DesignTokens.surfacePrimary,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        !isMe
                            ? Border.all(color: DesignTokens.borderSecondary)
                            : null,
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
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (isMe &&
                        _failedMessageIds.contains(message.messageId)) ...[
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
                            MyText(
                              text: "Thử lại",
                              textStyle: 'body',
                              textSize: '12',
                              textColor: 'placeholder',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (isMe &&
                        _retryingMessageIds.contains(message.messageId)) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DesignTokens.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          MyText(
                            text: "Đang thử lại...",
                            textStyle: 'body',
                            textSize: '12',
                            textColor: 'placeholder',
                          ),
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
                    if (isMe &&
                        _pendingMessageIds.contains(message.messageId)) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DesignTokens.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                    if (!isMe &&
                        _failedMessageIds.contains(message.messageId)) ...[
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
                            MyText(
                              text: "Thử lại",
                              textStyle: 'body',
                              textSize: '12',
                              textColor: 'placeholder',
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!isMe &&
                        _retryingMessageIds.contains(message.messageId)) ...[
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DesignTokens.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          MyText(
                            text: "Đang thử lại...",
                            textStyle: 'body',
                            textSize: '12',
                            textColor: 'placeholder',
                          ),
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
