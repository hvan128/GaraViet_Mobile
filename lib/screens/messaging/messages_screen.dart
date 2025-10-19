import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gara/models/messaging/messaging_models.dart' as msg;
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/messaging/messaging_service.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/services/messaging/messaging_event_bus.dart';
import 'package:gara/services/messaging/tab_focus_bus.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/utils/status/status_library.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  List<msg.RoomData> _rooms = [];
  msg.PaginationInfo? _pagination;
  int _currentPage = 1;
  final int _pageSize = 10;
  String _searchQuery = '';
  StreamSubscription<NewChatMessageEvent>? _newMsgSub;
  StreamSubscription? _roomsDirtySub;
  bool _shouldRefreshOnFocus = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _hasError = false; // Thêm flag để track lỗi

  @override
  void initState() {
    super.initState();
    // Test debug logger
    _fetch();
    _attachNewMessageListener();
    _attachRoomsDirtyListener();
    _attachFocusListener();
    _setupNetworkListener();
  }

  void _setupNetworkListener() {
    // Có thể thêm listener để detect khi có mạng trở lại
    // và tự động retry nếu đang có lỗi
  }

  void _attachNewMessageListener() {
    _newMsgSub = MessagingEventBus().onNewMessage.listen((event) {
      // Cập nhật UI cục bộ: move room lên đầu, cập nhật last message/time, tăng unread
      final idx = _rooms.indexWhere((r) => r.roomId == event.roomId);
      if (idx == -1) {
        // Không có phòng trong trang hiện tại: chọn cách nhẹ nhàng là refetch trang đầu
        // để đảm bảo thứ tự và badge chính xác
        _currentPage = 1;
        _fetch(refresh: true);
        return;
      }

      final old = _rooms[idx];
      final updated = msg.RoomData(
        roomId: old.roomId,
        requestServiceId: old.requestServiceId,
        requestCode: old.requestCode,
        carInfo: old.carInfo,
        serviceDescription: old.serviceDescription,
        lastMessage: event.content,
        lastMessageTime: event.createdAt,
        unreadCount: old.unreadCount + 1,
        status: old.status,
        statusText: old.statusText,
        price: old.price,
        otherUserName: old.otherUserName,
        otherUserAvatar: old.otherUserAvatar,
        requestServiceInfo: old.requestServiceInfo,
        quotationInfo: old.quotationInfo,
      );

      setState(() {
        _rooms.removeAt(idx);
        _rooms.insert(0, updated);
      });
    });
  }

  void _attachRoomsDirtyListener() {
    _roomsDirtySub = MessagingEventBus().onRoomsDirty.listen((_) {
      final isFocused = TabFocusBus.instance.currentIndex.value == 3; // tab Messages index
      if (isFocused) {
        _fetch(refresh: true);
      } else {
        _shouldRefreshOnFocus = true;
      }
    });
  }

  void _attachFocusListener() {
    TabFocusBus.instance.currentIndex.addListener(_onFocusChange);
    TabFocusBus.instance.focusTick.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final isFocused = TabFocusBus.instance.currentIndex.value == 3;
    if (isFocused && _shouldRefreshOnFocus) {
      _shouldRefreshOnFocus = false;
      _fetch(refresh: true);
    }
  }

  @override
  void dispose() {
    _newMsgSub?.cancel();
    _roomsDirtySub?.cancel();
    TabFocusBus.instance.currentIndex.removeListener(_onFocusChange);
    TabFocusBus.instance.focusTick.removeListener(_onFocusChange);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Phương thức để reload từ bên ngoài (được gọi từ MainNavigationScreen)
  void reloadFromExternal() {
    if (mounted) {
      _hasError = false; // Reset error state khi reload từ bên ngoài
      _fetch(refresh: true);
    }
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _rooms = []; // Thay vì clear(), tạo danh sách mới
    }

    setState(() {
      _loading = refresh || _rooms.isEmpty;
      _loadingMore = !refresh && _rooms.isNotEmpty;
      _hasError = false; // Reset error state khi bắt đầu fetch
    });

    try {
      final response = await MessagingServiceApi.getRooms(
        pageNum: _currentPage,
        pageSize: _pageSize,
        keyword: (_searchQuery.trim().isEmpty) ? null : _searchQuery.trim(),
      );

      if (!mounted) return;

      setState(() {
        if (refresh || _currentPage == 1) {
          _rooms = List<msg.RoomData>.from(response.rooms); // Đảm bảo tạo mutable list
        } else {
          _rooms.addAll(response.rooms);
        }
        _pagination = response.pagination;
        _loading = false;
        _loadingMore = false;
        _hasError = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _hasError = true; // Set error state
      });
      DebugLogger.largeJson('[MessagesScreen] error', {'error': e.toString()});
      AppToastHelper.showError(
        context,
        message: 'Không thể tải danh sách tin nhắn. Vui lòng thử lại sau.',
      );
    }
  }

  Future<void> _loadMore() async {
    if (_pagination == null ||
        _currentPage >= _pagination!.totalPages ||
        _loadingMore) {
      return;
    }

    _currentPage++;
    await _fetch();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _searchQuery = value;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _currentPage = 1;
      _fetch(refresh: true);
    });
  }

  void _onRoomPressed(msg.RoomData room) {
    Navigator.pushNamed(context, '/chat-room', arguments: room.roomId).then((_) {
      if (!mounted) return;
      _fetch(refresh: true);
    });
  }

  // Đã thay bằng messageStatus từ API

  String _formatTimeAgo(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';

    try {
      final now = DateTime.now();
      final time = DateTime.parse(timeString);
      final difference = now.difference(time);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${time.day}/${time.month}/${time.year}';
      }
    } catch (e) {
      return timeString;
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '';
    num? number;
    if (value is num) {
      number = value;
    } else {
      final digitsOnly = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) return value.toString();
      number = int.tryParse(digitsOnly);
    }
    if (number == null) return value.toString();

    final str = number.toString();
    final reversed = str.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write('.');
      buffer.write(reversed[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              title: 'Tin nhắn',
              showLeftButton: false,
              showRightButton: true,
              rightIcon: SvgIcon(
                svgPath: 'assets/icons_final/more.svg',
                size: 24,
                color: DesignTokens.textPrimary,
              ),
              onRightPressed: () {
                // TODO: Show more options
              },
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 12),
              child: MyTextField(
                hintText: 'Tìm kiếm...',
                controller: _searchController,
                prefixIcon: SvgIcon(
                  svgPath: 'assets/icons_final/search-normal.svg',
                  size: 20,
                  color: DesignTokens.textPrimary,
                ),
                
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchDebounce?.cancel();
                              setState(() {
                                _searchQuery = '';
                              });
                              _searchController.text = '';
                              _currentPage = 1;
                              _fetch(refresh: true);
                            },
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/close.svg',
                              size: 20,
                              color: DesignTokens.textTertiary,
                            ),
                          )
                        : null,
                onChange: _onSearchChanged,
                obscureText: false,
                hasError: false,
              ),
            ),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: () => _fetch(refresh: true),
                        child:
                            _hasError && _rooms.isEmpty
                                ? ListView(
                                  padding: EdgeInsets.only(
                                    top: 80,
                                    left: 12,
                                    right: 12,
                                    bottom: 50 + kBottomNavigationBarHeight,
                                  ),
                                  children: [
                                    Center(
                                      child: Column(
                                        children: [
                                          MyText(
                                            text: 'Không thể tải danh sách tin nhắn',
                                            textStyle: 'body',
                                            textSize: '16',
                                            textColor: 'placeholder',
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () => _fetch(refresh: true),
                                            child: MyText(
                                              text: 'Thử lại',
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'invert',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                                : _rooms.isEmpty
                                    ? ListView(
                                      padding: EdgeInsets.only(
                                        top: 80,
                                        left: 12,
                                        right: 12,
                                        bottom: 50 + kBottomNavigationBarHeight,
                                      ),
                                      children: [
                                        Center(
                                          child: MyText(
                                            text: 'Chưa có tin nhắn nào',
                                            textStyle: 'body',
                                            textSize: '16',
                                            textColor: 'placeholder',
                                          ),
                                        ),
                                      ],
                                    )
                                : NotificationListener<ScrollNotification>(
                                  onNotification: (
                                    ScrollNotification scrollInfo,
                                  ) {
                                    final threshold = 200.0;
                                    if (!_loadingMore &&
                                        scrollInfo.metrics.pixels >=
                                            scrollInfo.metrics.maxScrollExtent -
                                                threshold) {
                                      _loadMore();
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 0,
                                      bottom: 50 + kBottomNavigationBarHeight,
                                    ),
                                    itemCount:
                                        _rooms.length + (_loadingMore ? 1 : 0),
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      if (index == _rooms.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final room = _rooms[index];
                                      return _buildRoomCard(room);
                                    },
                                  ),
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(msg.RoomData room) {
    final hasUnread = room.unreadCount > 0;

    return GestureDetector(
      onTap: () => _onRoomPressed(room),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border:
                  hasUnread
                      ? Border.all(color: DesignTokens.surfaceBrand, width: 1)
                      : Border.all(color: DesignTokens.borderSecondary),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Name, ID, status pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        MyText(
                          text: room.otherUserName ?? 'Người dùng',
                          textStyle: 'head',
                          textSize: '16',
                          textColor: 'brand',
                        ),
                        const SizedBox(width: 8),
                        MyText(
                          text: room.requestCode ?? '#${room.requestServiceId}',
                          textStyle: 'body',
                          textSize: '12',
                          textColor: 'tertiary',
                        ),
                      ],
                    ),
                    StatusWidget(
                      status: room.messageStatus ?? int.tryParse((room.status ?? '').toString()) ?? 1,
                      type: StatusType.message,
                      height: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Car info and service + time
                Row(
                  children: [
                    Expanded(
                      child: MyText(
                        text:
                            '${room.carInfo ?? 'Thông tin xe'} - ${room.serviceDescription ?? 'Dịch vụ'}',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),
                    ),
                    MyText(
                      text: _formatTimeAgo(room.lastMessageTime),
                      textStyle: 'body',
                      textSize: '12',
                      textColor: 'tertiary',
                    ),
                  ],
                ),

                // Optional legacy price field
                if (room.price != null && room.price!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(
                    color: DesignTokens.borderBrandSecondary,
                    thickness: 1,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      MyText(
                        text: 'Báo giá: ',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'tertiary',
                      ),
                      MyText(
                        text: '${_formatCurrency(room.quotationInfo?.price)}đ',
                        textStyle: 'title',
                        textSize: '16',
                        textColor: 'brand',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasUnread)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: DesignTokens.textBrand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: MyText(
                    text: room.unreadCount.toString(),
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'invert',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
