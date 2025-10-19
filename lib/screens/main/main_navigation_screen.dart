import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gara/screens/home/home_screen.dart';
import 'package:gara/screens/messaging/messages_screen.dart';
import 'package:gara/screens/request/request_screen.dart';
import 'package:gara/screens/schedule/schedule_screen.dart';
import 'package:gara/screens/my_car/my_car_screen.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/theme/effects.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/utils/haptic_utils.dart';
import 'package:gara/services/messaging/navigation_event_bus.dart';
import 'package:gara/services/messaging/tab_focus_bus.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription<ReloadMessagesEvent>? _reloadMessagesSub;
  StreamSubscription<ReloadRequestsEvent>? _reloadRequestsSub;
  final GlobalKey _messagesScreenKey = GlobalKey();
  final GlobalKey _requestScreenKey = GlobalKey();
  
  // Lazy loading: chỉ khởi tạo màn hình khi cần
  final Map<int, Widget> _initializedScreens = {};

  void _ensureScreenInitialized(int index) {
    if (!_initializedScreens.containsKey(index)) {
      _getScreen(index);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachReloadMessagesListener();
    _attachReloadRequestsListener();
    // Thông báo focus ban đầu cho tab hiện tại (mặc định 0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureScreenInitialized(_currentIndex);
        TabFocusBus.instance.notifyFocused(_currentIndex);
        setState(() {});
        
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra arguments để set tab được chọn
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('selectedTab')) {
      final selectedTab = args['selectedTab'] as int?;
      if (selectedTab != null && selectedTab >= 0 && selectedTab < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _ensureScreenInitialized(selectedTab);
            setState(() {
              _currentIndex = selectedTab;
            });
            // Sau khi set tab từ arguments, phát focus để các màn hình đồng bộ
            TabFocusBus.instance.notifyFocused(_currentIndex);
          }
        });
      }
    }
  }

  void _attachReloadMessagesListener() {
    _reloadMessagesSub = NavigationEventBus().onReloadMessages.listen((event) {
      // Chỉ reload khi không đang ở tab messages để tránh conflict với realtime update
      if (_currentIndex != 3 && _messagesScreenKey.currentState != null) {
        // Cast về dynamic để gọi method reloadFromExternal
        (_messagesScreenKey.currentState as dynamic).reloadFromExternal();
      }
    });
  }

  void _attachReloadRequestsListener() {
    _reloadRequestsSub = NavigationEventBus().onReloadRequests.listen((event) {
      // Nếu màn Request đã được khởi tạo
      if (_requestScreenKey.currentState != null) {
        final isRequestTabFocused = _currentIndex == 1; // Request tab index
        
        if (isRequestTabFocused) {
          // User đang ở tab Request - thêm request mới vào list thay vì reload
          if (event.notificationData != null) {
            // Parse notification data thành RequestServiceModel
            final parsedRequest = (_requestScreenKey.currentState as dynamic).parseRequestFromNotification(event.notificationData!);
            if (parsedRequest != null) {
              (_requestScreenKey.currentState as dynamic).addNewRequestToTop(parsedRequest);
            }
          }
        } else {
          // User không ở tab Request - reload bình thường
          (_requestScreenKey.currentState as dynamic).reloadFromExternal();
        }
      }
    });
  }

  @override
  void dispose() {
    _reloadMessagesSub?.cancel();
    _reloadRequestsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi app quay lại, thông báo tab hiện tại để các màn tự kiểm refresh
      TabFocusBus.instance.notifyFocused(_currentIndex);
    }
  }

  // Lazy loading: chỉ khởi tạo màn hình khi cần
  Widget _getScreen(int index) {
    if (!_initializedScreens.containsKey(index)) {
      switch (index) {
        case 0:
          _initializedScreens[index] = const HomeScreen();
          break;
        case 1:
          _initializedScreens[index] = RequestScreen(key: _requestScreenKey);
          break;
        case 2:
          _initializedScreens[index] = const ScheduleScreen();
          break;
        case 3:
          _initializedScreens[index] = MessagesScreen(key: _messagesScreenKey);
          break;
        case 4:
          _initializedScreens[index] = const MyCarScreen();
          break;
        default:
          _initializedScreens[index] = const HomeScreen();
      }
    }
    return _initializedScreens[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Nội dung màn hình hiển thị đầy đủ với lazy loading
          IndexedStack(
            index: _currentIndex,
            children: List.generate(5, (i) => _initializedScreens[i] ?? const SizedBox.shrink()),
          ),
          // Bottom navigation nổi lên trên
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(100)),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: DesignTokens.surfacePrimary,
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    border: Border.all(
                      color: DesignTokens.borderBrandSecondary,
                      width: 1,
                    ),
                    boxShadow: [
                      DesignEffects.largeCard,
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          icon: 'assets/icons_final/home.svg',
                          label: 'Trang chủ',
                          index: 0,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: 'assets/icons_final/document-text.svg',
                          label: 'Yêu cầu',
                          index: 1,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: 'assets/icons_final/calendar.svg',
                          label: 'Đơn hàng',
                          index: 2,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: 'assets/icons_final/message-text.svg',
                          label: 'tin nhắn',
                          index: 3,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: 'assets/icons_final/car.svg',
                          label: 'Xe bạn',
                          index: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        // Thêm haptic feedback khi chuyển tab
        HapticUtils.selection();
        // Khởi tạo màn hình nếu chưa có
        if (!_initializedScreens.containsKey(index)) {
          _getScreen(index);
        }
        setState(() {
          _currentIndex = index;
        });
        // Thông báo tab đang được focus để các màn hình tự quyết định refresh
        TabFocusBus.instance.notifyFocused(index);
      },
      child: Container(
        height: 64,
        width: double.infinity,
        // Tô màu tạm thời để xem vùng ấn
        decoration: BoxDecoration(
          color: DesignTokens.surfacePrimary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(
              svgPath: icon,
              size: 24,
              color: isActive ? DesignTokens.textBrand : DesignTokens.textPlaceholder,
            ),
            const SizedBox(height: 4),
            MyText(
              text: label,
              textStyle: 'title',
              textSize: '12',
              textColor: isActive ? 'brand' : 'placeholder',
            ),
          ],
        ),
      ),
    );
  }
}
