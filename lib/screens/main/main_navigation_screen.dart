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
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';

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

  // Khởi tạo tất cả màn hình ngay từ đầu để tránh delay
  List<Widget>? _screens;
  bool? _isGarageUser;

  // Flag để đảm bảo chỉ set tab từ arguments một lần
  bool _hasSetInitialTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachReloadMessagesListener();
    _attachReloadRequestsListener();

    // Thông báo focus ban đầu cho tab hiện tại
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TabFocusBus.instance.notifyFocused(_currentIndex);
        setState(() {});
      }
    });
  }

  // Khởi tạo danh sách màn hình dựa trên user role
  List<Widget> _buildScreens(bool isGarage) {
    if (_screens != null && _isGarageUser == isGarage) {
      // Đã khởi tạo và role không thay đổi
      return _screens!;
    }

    // Tạo mới hoặc cập nhật danh sách màn hình
    final screens = <Widget>[
      const HomeScreen(),
      RequestScreen(key: _requestScreenKey),
      const ScheduleScreen(),
      MessagesScreen(key: _messagesScreenKey),
    ];

    // Chỉ thêm MyCarScreen nếu không phải garage
    if (!isGarage) {
      screens.add(const MyCarScreen());
    }

    _screens = screens;
    _isGarageUser = isGarage;

    return screens;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra arguments để set tab được chọn - chỉ một lần duy nhất
    if (!_hasSetInitialTab) {
      final args = ModalRoute.of(context)?.settings.arguments;
      print('[MainNavigationScreen] didChangeDependencies called - args: $args, currentIndex: $_currentIndex');

      if (args is Map && args.containsKey('selectedTab')) {
        final selectedTab = args['selectedTab'] as int?;
        print('[MainNavigationScreen] Found selectedTab in args: $selectedTab');

        if (selectedTab != null && selectedTab >= 0 && selectedTab < 5) {
          print('[MainNavigationScreen] Setting currentIndex to: $selectedTab');
          _hasSetInitialTab = true; // Đánh dấu đã set tab từ arguments

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
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
            final parsedRequest = (_requestScreenKey.currentState as dynamic).parseRequestFromNotification(
              event.notificationData!,
            );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isLoggedIn = userProvider.isLoggedIn;
        final isGarage = userProvider.isGarageUser;
        final isVerifiedGarage = userProvider.userInfo?.isVerifiedGarage;

        // Nếu chưa đăng nhập, chỉ hiển thị HomeScreen mà không có bottom navigation
        if (!isLoggedIn) {
          return const Scaffold(body: HomeScreen());
        }

        // Nếu là tài khoản gara nhưng chưa được duyệt (0) hoặc bị từ chối (2),
        // ẩn bottom navigation và chỉ hiển thị HomeScreen
        if (isGarage && isVerifiedGarage != null && (isVerifiedGarage == 0 || isVerifiedGarage == 2)) {
          return const Scaffold(body: HomeScreen());
        }

        // Khởi tạo màn hình dựa trên role của user
        final screens = _buildScreens(isGarage);

        // Nếu đã đăng nhập, hiển thị đầy đủ với bottom navigation
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Nội dung màn hình hiển thị đầy đủ
              IndexedStack(index: _currentIndex, children: screens),
              // Bottom navigation nổi lên trên
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(100)),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: DesignTokens.surfacePrimary,
                          borderRadius: const BorderRadius.all(Radius.circular(100)),
                          boxShadow: [DesignEffects.largeCard],
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(100)),
                          border: Border.all(color: DesignTokens.borderBrandSecondary, width: 2),
                        ),
                        child: _buildBottomNavigation(isGarage),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(bool isGarage) {
    if (isGarage) {
      // Garage user: không có tab "Xe bạn"
      return Row(
        children: [
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/home.svg', label: 'Trang chủ', index: 0)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/document-text.svg', label: 'Yêu cầu', index: 1)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/calendar.svg', label: 'Đơn hàng', index: 2)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/message-text.svg', label: 'Tin nhắn', index: 3)),
        ],
      );
    } else {
      // Non-garage user: có đầy đủ tabs bao gồm "Xe bạn"
      return Row(
        children: [
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/home.svg', label: 'Trang chủ', index: 0)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/document-text.svg', label: 'Yêu cầu', index: 1)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/calendar.svg', label: 'Đơn hàng', index: 2)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/message-text.svg', label: 'Tin nhắn', index: 3)),
          Expanded(child: _buildNavItem(icon: 'assets/icons_final/car.svg', label: 'Xe bạn', index: 4)),
        ],
      );
    }
  }

  Widget _buildNavItem({required String icon, required String label, required int index}) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Haptic feedback ngay lập tức để phản hồi nhanh
        HapticUtils.selection();

        // Cập nhật UI ngay lập tức - không cần khởi tạo gì thêm
        setState(() {
          _currentIndex = index;
        });

        // Thông báo tab đang được focus để các màn hình tự quyết định refresh
        print('[MainNavigationScreen] Tab tapped: $index, notifying focus');
        TabFocusBus.instance.notifyFocused(index);
      },
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(svgPath: icon, size: 24, color: isActive ? DesignTokens.textBrand : DesignTokens.textPlaceholder),
            const SizedBox(height: 4),
            MyText(text: label, textStyle: 'title', textSize: '12', textColor: isActive ? 'brand' : 'placeholder'),
          ],
        ),
      ),
    );
  }
}
