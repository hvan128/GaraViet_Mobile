import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:gara/widgets/app_dialog.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/utils/status/status_library.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin {
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

  // Multi-select state
  bool _isSelectionMode = false;
  Set<String> _selectedRooms = <String>{};

  // Filter state
  final GlobalKey _filterKey = GlobalKey();
  final Set<int> _selectedStatuses = <int>{};

  // Animation controllers for press effects
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _scaleAnimations = {};
  final Map<String, bool> _isLongPressing = {};
  final Map<String, Timer> _selectionTimers = {};

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

    // Dispose animation controllers
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _scaleAnimations.clear();
    _isLongPressing.clear();

    // Cancel selection timers
    for (var timer in _selectionTimers.values) {
      timer.cancel();
    }
    _selectionTimers.clear();

    super.dispose();
  }

  /// Phương thức để reload từ bên ngoài (được gọi từ MainNavigationScreen)
  void reloadFromExternal() {
    if (mounted) {
      _hasError = false; // Reset error state khi reload từ bên ngoài
      _fetch(refresh: true);
    }
  }

  void _createAnimationController(String roomId) {
    if (!_animationControllers.containsKey(roomId)) {
      final controller = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
      final scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _animationControllers[roomId] = controller;
      _scaleAnimations[roomId] = scaleAnimation;
    }
  }

  void _startPressAnimation(String roomId) {
    _createAnimationController(roomId);
    _animationControllers[roomId]?.forward();

    // Haptic feedback ngay khi bắt đầu press down
    HapticFeedback.lightImpact();
  }

  void _endPressAnimation(String roomId) {
    // Chỉ kết thúc animation nếu không phải đang long press
    if (_animationControllers.containsKey(roomId) && !(_isLongPressing[roomId] ?? false)) {
      _animationControllers[roomId]?.reverse();
    }
  }

  void _startLongPressAnimation(String roomId) {
    _isLongPressing[roomId] = true;
    _createAnimationController(roomId);
    _animationControllers[roomId]?.forward();

    // Bắt đầu timer để hiển thị selection sau 200ms
    _selectionTimers[roomId] = Timer(const Duration(milliseconds: 200), () {
      if (mounted && _isLongPressing[roomId] == true) {
        setState(() {
          if (!_isSelectionMode) {
            _isSelectionMode = true;
          }
          _selectedRooms.add(roomId);
        });

        // Reset animation về trạng thái ban đầu khi được chọn
        _resetAnimation(roomId);

        // Haptic feedback khi chuyển sang trạng thái selected
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _endLongPressAnimation(String roomId) {
    _isLongPressing[roomId] = false;

    // Cancel timer nếu chưa hoàn thành
    _selectionTimers[roomId]?.cancel();
    _selectionTimers.remove(roomId);

    if (_animationControllers.containsKey(roomId)) {
      _animationControllers[roomId]?.reverse();
    }
  }

  void _toggleRoomSelection(String roomId) {
    setState(() {
      if (_selectedRooms.contains(roomId)) {
        _selectedRooms.remove(roomId);
        if (_selectedRooms.isEmpty) {
          _isSelectionMode = false;
        }
        // Reset animation về trạng thái ban đầu khi unselect
        _resetAnimation(roomId);
      } else {
        _selectedRooms.add(roomId);
      }
    });
  }

  void _resetAnimation(String roomId) {
    if (_animationControllers.containsKey(roomId)) {
      _animationControllers[roomId]?.reset();
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedRooms.clear();
      _isSelectionMode = false;
    });

    // Reset tất cả animation khi clear selection
    for (String roomId in _animationControllers.keys) {
      _resetAnimation(roomId);
    }
  }

  void _openStatusFilter() async {
    // Định nghĩa các trạng thái tin nhắn có thể filter
    final Map<int, String> statusLabels = {
      1: 'Chờ báo giá',
      2: 'Chờ lên lịch',
      3: 'Chưa cọc',
      4: 'Đã cọc',
      5: 'Đang thực hiện',
      6: 'Hoàn thành',
      7: 'Đã hủy',
    };

    // Tính vị trí của nút lọc để neo menu ngay bên dưới
    final RenderBox? button = _filterKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset buttonOffset = button?.localToGlobal(Offset.zero) ?? const Offset(0, 0);
    final Size buttonSize = button?.size ?? const Size(0, 0);

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(buttonOffset.dx, buttonOffset.dy + buttonSize.height, buttonSize.width, 0),
      Offset.zero & overlay.size,
    );

    final int? selected = await showMenu<int>(
      context: context,
      position: position,
      color: Colors.white,
      items: [
        for (final entry in statusLabels.entries)
          PopupMenuItem<int>(
            value: entry.key,
            height: 36,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: SizedBox(
                height: 32,
                child: Center(
                  child: StatusWidget(
                    status: entry.key,
                    type: StatusType.message,
                    isSelected: _selectedStatuses.contains(entry.key),
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (selected != null) {
      setState(() {
        if (_selectedStatuses.contains(selected)) {
          _selectedStatuses.remove(selected);
        } else {
          _selectedStatuses.add(selected);
        }
      });
      _fetch(refresh: true);
    }
  }

  void _showDeleteConfirmation() {
    if (_selectedRooms.isEmpty) return;

    AppDialogHelper.confirm(
      context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa ${_selectedRooms.length} phòng chat đã chọn?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
      type: AppDialogType.warning,
      confirmButtonType: ButtonType.delete,
      cancelButtonType: ButtonType.secondary,
      showIconHeader: true,
      onConfirm: _deleteSelectedRooms,
    );
  }

  Future<void> _deleteSelectedRooms() async {
    if (_selectedRooms.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final response = await MessagingServiceApi.deleteRooms(roomIds: _selectedRooms.toList());

      if (!mounted) return;

      // Cập nhật UI dựa trên kết quả xóa
      if (response.hasDataChanged && response.deletedCount > 0) {
        // Có room được xóa thành công - chỉ xóa những room đã xóa thành công
        final deletedRoomIds = _selectedRooms.toList();
        final failedRoomIds = response.failedRooms.map((f) => f.roomId).toSet();

        setState(() {
          // Chỉ xóa những room đã xóa thành công (không phải failed rooms)
          _rooms.removeWhere((room) => deletedRoomIds.contains(room.roomId) && !failedRoomIds.contains(room.roomId));

          // Clear selection
          _selectedRooms.clear();
          _isSelectionMode = false;
        });
      } else {
        // Không có room nào được xóa - chỉ clear selection
        setState(() {
          _selectedRooms.clear();
          _isSelectionMode = false;
        });
      }

      // Reset tất cả animation sau khi delete
      for (String roomId in _animationControllers.keys) {
        _resetAnimation(roomId);
      }

      // Hiển thị thông báo kết quả dựa trên loại kết quả
      if (response.isFullySuccessful) {
        // 3/3 - Xóa thành công hoàn toàn
        AppToastHelper.showSuccess(context, message: 'Xóa thành công ${response.deletedCount} phòng chat');
      } else if (response.isPartiallySuccessful) {
        // 2/3 hoặc 3/4 - Xóa thành công một phần
        final failedCount = response.failedRooms.length;
        AppToastHelper.showWarning(
          context,
          message:
              'Xóa thành công ${response.deletedCount}/${response.totalCount} phòng chat. $failedCount phòng không thể xóa do chưa hoàn thành.',
        );
      } else if (response.isBusinessRuleFailure) {
        // 0/3 - Xóa thất bại do ràng buộc nghiệp vụ
        AppToastHelper.showError(
          context,
          message: 'Không thể xóa phòng chat. Chỉ có thể xóa khi đã hoàn thành hoặc báo giá đã bị hủy.',
        );
      } else if (response.isApiFailure) {
        // API error (token, mạng, server)
        AppToastHelper.showError(context, message: 'Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại.');
      } else {
        // Fallback - trường hợp không xác định được
        AppToastHelper.showError(context, message: response.message);
      }
    } catch (e) {
      if (!mounted) return;
      AppToastHelper.showError(context, message: 'Lỗi xóa phòng chat. Vui lòng thử lại sau.');
      DebugLogger.largeJson('[MessagesScreen.deleteSelectedRooms] error', {'error': e.toString()});
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
        statusCsv: _selectedStatuses.isEmpty ? null : _selectedStatuses.join(','),
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
      AppToastHelper.showError(context, message: 'Không thể tải danh sách tin nhắn. Vui lòng thử lại sau.');
    }
  }

  Future<void> _loadMore() async {
    if (_pagination == null || _currentPage >= _pagination!.totalPages || _loadingMore) {
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
              title: _isSelectionMode ? 'Đã chọn ${_selectedRooms.length}' : 'Tin nhắn',
              showLeftButton: _isSelectionMode,
              leftIcon: _isSelectionMode
                  ? SvgIcon(svgPath: 'assets/icons_final/close.svg', size: 24, color: DesignTokens.textPrimary)
                  : null,
              onLeftPressed: _isSelectionMode ? _clearSelection : null,
              showRightButton: true,
              rightIcon: _isSelectionMode
                  ? SvgIcon(
                      svgPath: 'assets/icons_final/trash.svg',
                      size: 24,
                      color: _selectedRooms.isNotEmpty ? DesignTokens.alertError : DesignTokens.textTertiary,
                    )
                  : SvgIcon(svgPath: 'assets/icons_final/more.svg', size: 24, color: DesignTokens.textPrimary),
              onRightPressed: _isSelectionMode
                  ? (_selectedRooms.isNotEmpty ? _showDeleteConfirmation : null)
                  : () {
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
                suffixIcon: _searchQuery.isNotEmpty
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
            // Filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _openStatusFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      key: _filterKey,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: Row(
                        children: [
                          SvgIcon(svgPath: 'assets/icons_final/filter.svg', size: 16, color: DesignTokens.textBrand),
                          const SizedBox(width: 6),
                          const MyText(text: 'Lọc', textStyle: 'label', textSize: '12', textColor: 'brand'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: false,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final st in _selectedStatuses)
                              Padding(
                                padding: EdgeInsets.only(left: st == _selectedStatuses.first ? 0 : 6),
                                child: StatusWidget(
                                  status: st,
                                  type: StatusType.message,
                                  isSelected: true,
                                  height: 24,
                                  onRemove: () {
                                    setState(() {
                                      _selectedStatuses.remove(st);
                                    });
                                    _fetch(refresh: true);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _fetch(refresh: true),
                      child: _hasError && _rooms.isEmpty
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
                                  onNotification: (ScrollNotification scrollInfo) {
                                    final threshold = 200.0;
                                    if (!_loadingMore &&
                                        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - threshold) {
                                      _loadMore();
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 12,
                                      bottom: 50 + kBottomNavigationBarHeight,
                                    ),
                                    itemCount: _rooms.length + (_loadingMore ? 1 : 0),
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      if (index == _rooms.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(child: CircularProgressIndicator()),
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
    final isSelected = _selectedRooms.contains(room.roomId);
    final roomId = room.roomId;

    // Kiểm tra xem có room nào khác đã được chọn chưa
    final hasOtherSelectedRooms = _selectedRooms.isNotEmpty && !_selectedRooms.contains(roomId);
    final isInteractionDisabled = hasOtherSelectedRooms;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleRoomSelection(roomId);
        } else {
          _onRoomPressed(room);
        }
      },
      onTapDown: (_) {
        // Chỉ bắt đầu animation nếu không bị vô hiệu hóa
        if (!isInteractionDisabled) {
          _startPressAnimation(roomId);
        }
      },
      onTapUp: (_) {
        // Chỉ kết thúc animation nếu không bị vô hiệu hóa
        if (!isInteractionDisabled) {
          _endPressAnimation(roomId);
        }
      },
      onTapCancel: () {
        // Chỉ kết thúc animation nếu không bị vô hiệu hóa
        if (!isInteractionDisabled) {
          _endPressAnimation(roomId);
        }
      },
      onLongPressStart: (_) {
        if (!_isSelectionMode && !isInteractionDisabled) {
          _startLongPressAnimation(roomId);
        }
      },
      onLongPressEnd: (_) {
        if (!_isSelectionMode && !isInteractionDisabled) {
          _endLongPressAnimation(roomId);
          // Không cần toggle selection nữa vì đã được thực hiện trong timer
        }
      },
      onLongPressCancel: () {
        if (!_isSelectionMode && !isInteractionDisabled) {
          _endLongPressAnimation(roomId);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimations[roomId] ?? const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          final scale = _scaleAnimations[roomId]?.value ?? 1.0;
          return Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSelected ? DesignTokens.surfaceBrand.withOpacity(0.1) : DesignTokens.surfacePrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: DesignTokens.surfaceBrand, width: 2)
                        : hasUnread
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
                              text: '${room.carInfo ?? 'Thông tin xe'} - ${room.serviceDescription ?? 'Dịch vụ'}',
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

                      // Last message preview
                      if ((room.lastMessage ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        MyText(
                          text: room.lastMessage!.trim(),
                          textStyle: hasUnread ? 'title' : 'body',
                          textSize: '14',
                          textColor: 'secondary',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Optional legacy price field
                      if (room.price != null && room.price!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(color: DesignTokens.borderBrandSecondary, thickness: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Spacer(),
                            MyText(text: 'Báo giá: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
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
                if (isSelected)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceBrand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignTokens.surfacePrimary, width: 2),
                      ),
                      child: Center(
                        child: SvgIcon(
                          svgPath: 'assets/icons_final/Check.svg',
                          size: 14,
                          color: DesignTokens.surfacePrimary,
                        ),
                      ),
                    ),
                  )
                else if (hasUnread)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: DesignTokens.textBrand, borderRadius: BorderRadius.circular(12)),
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
        },
      ),
    );
  }
}
