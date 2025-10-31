import 'package:flutter/material.dart';
import 'package:gara/components/home/top_gara.dart';
import 'package:gara/components/home/top_product.dart';
import 'package:gara/components/home/reputable_products.dart';
import 'package:gara/components/home/recent_reviews.dart';
import 'package:gara/models/reputable_product/reputable_product_model.dart';
import 'package:gara/models/review/review_model.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/widgets/app_dialog.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/widgets/cached_image_widget.dart';
import 'package:gara/widgets/garage_status_notification.dart';
import 'package:gara/services/messaging/navigation_event_bus.dart';
import 'package:gara/services/messaging/fcm_token_service.dart';
import 'package:gara/services/messaging/push_notification_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showRequestSection = true;
  String? _selectedLocation = 'hanoi'; // Giá trị mặc định

  // Data giả định cho danh sách sản phẩm uy tín
  final List<ReputableProductModel> _reputableProducts = [
    ReputableProductModel(
      id: '1',
      name: 'Phim cách nhiệt photosync',
      description: 'Phim cách nhiệt cao cấp từ Photosync',
      rating: 5,
      customerCount: 1250,
      isVerified: true,
    ),
    ReputableProductModel(
      id: '2',
      name: 'Camera hành trình icar',
      description: 'Camera hành trình chất lượng cao',
      rating: 4,
      customerCount: 890,
      isVerified: true,
    ),
    ReputableProductModel(
      id: '3',
      name: 'Phần mềm dẫn đường vietmaps',
      description: 'Phần mềm dẫn đường Việt Nam',
      rating: 5,
      customerCount: 2100,
      isVerified: true,
    ),
  ];

  // Data giả định cho đánh giá gần đây
  final List<ReviewModel> _recentReviews = [
    ReviewModel(
      id: '1',
      userName: 'Quách Tường B',
      userAvatar: null, // Sẽ hiển thị icon mặc định
      serviceName: 'Độ cốp điện VF8',
      comment: 'tuyệt vời sẽ quay lại lần 2',
      rating: 5,
      context: 'Vietnam car',
    ),
    ReviewModel(
      id: '2',
      userName: 'LNB Lâm',
      userAvatar: null,
      serviceName: 'Độ cốp điện VF8',
      comment: 'tuyệt vời sẽ quay lại lần 2',
      rating: 3,
      context: 'Vietnam car',
    ),
    ReviewModel(
      id: '3',
      userName: 'A2 CNTT',
      userAvatar: null,
      serviceName: 'Độ cốp điện VF8',
      comment: 'tuyệt vời sẽ quay lại lần 2',
      rating: 2,
      context: 'Vietnam car',
    ),
  ];

  // Danh sách các địa điểm
  final List<DropdownItem> _locationItems = [
    DropdownItem(
      value: 'hanoi',
      label: 'Hà Nội',
      description: 'Thủ đô Việt Nam',
      icon: SvgIcon(svgPath: 'assets/icons_final/location.svg'),
    ),
    DropdownItem(
      value: 'hcm',
      label: 'TP. Hồ Chí Minh',
      description: 'Thành phố lớn nhất',
      icon: SvgIcon(svgPath: 'assets/icons_final/location.svg'),
    ),
    DropdownItem(
      value: 'danang',
      label: 'Đà Nẵng',
      description: 'Thành phố biển',
      icon: SvgIcon(svgPath: 'assets/icons_final/location.svg'),
    ),
    DropdownItem(
      value: 'haiphong',
      label: 'Hải Phòng',
      description: 'Thành phố cảng',
      icon: SvgIcon(svgPath: 'assets/icons_final/location.svg'),
    ),
    DropdownItem(
      value: 'cantho',
      label: 'Cần Thơ',
      description: 'Thủ phủ miền Tây',
      icon: SvgIcon(svgPath: 'assets/icons_final/location.svg'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Listen to user info reload events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupUserInfoReloadListener();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildAuthActions() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userInfo = userProvider.userInfo;
        final userDisplayName = userProvider.userDisplayName;
        final userAvatar = userInfo?.avatarPath;
        final isLoggedIn = userProvider.isLoggedIn;
        final isGarage = userProvider.isGarageUser;
        final isVerifiedGarage = userInfo?.isVerifiedGarage;
        if (isLoggedIn) {
          debugPrint(
            'UserProvider: isLoggedIn=$isLoggedIn, isGarage=$isGarage, isVerifiedGarage=$isVerifiedGarage, userDisplayName=$userDisplayName, userAvatar=$userAvatar',
          );

          // Kiểm tra nếu là tài khoản gara và có trạng thái cần hiển thị thông báo
          if (isGarage && isVerifiedGarage != null && (isVerifiedGarage == 0 || isVerifiedGarage == 2)) {
            return GarageStatusNotification(isVerifiedGarage: isVerifiedGarage, garageName: userDisplayName);
          }

          // User is logged in - show profile header (cho user thường hoặc gara đã active)
          // Fallback: Nếu không có userInfo, hiển thị loading
          if (userInfo == null) {
            return Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          print('DEBUG: Hiển thị profile header bình thường');
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Profile picture
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.borderSecondary),
                    ),
                    child: CachedAvatarWidget(
                      imageUrl: userAvatar != null && userAvatar.isNotEmpty ? resolveImageUrl(userAvatar) : null,
                      radius: 20,
                      fallbackText: userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : 'U',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Greeting text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(text: 'Xin chào,', textStyle: 'body', textSize: '12', textColor: 'invert'),
                      const SizedBox(height: 2),
                      MyText(text: userDisplayName, textStyle: 'title', textSize: '14', textColor: 'invert'),
                    ],
                  ),

                  // Notification icon
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigate.pushNamed('/announcements');
                    },
                    child: SvgIcon(svgPath: 'assets/icons_final/notification.svg', width: 24, height: 24),
                  ),

                  const SizedBox(width: 8),

                  // Profile icon
                  GestureDetector(
                    onTap: _showAccountMenu,
                    child: SvgIcon(svgPath: 'assets/icons_final/profile.svg', width: 24, height: 24),
                  ),
                ],
              ),
            ],
          );
        } else {
          // User is not logged in - show login/register buttons
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MyButton(
                text: 'Đăng nhập',
                buttonType: ButtonType.transparent,
                color: MyColors.white['c900'],
                height: 48,
                width: 100,
                onPressed: () {
                  Navigate.pushNamed('/login');
                },
              ),
              const SizedBox(width: 16),
              MyButton(
                text: 'Đăng ký',
                buttonType: ButtonType.secondary,
                height: 48,
                width: 100,
                onPressed: () {
                  Navigate.pushNamed('/register');
                },
              ),
            ],
          );
        }
      },
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final userInfo = userProvider.userInfo;
            final userDisplayName = userProvider.userDisplayName;
            final userAvatar = userInfo?.avatarPath;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: DesignTokens.surfacePrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),

                  // User info
                  Row(
                    children: [
                      CachedAvatarWidget(
                        imageUrl: userAvatar != null && userAvatar.isNotEmpty ? resolveImageUrl(userAvatar) : null,
                        radius: 25,
                        fallbackText: userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : 'U',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(text: userDisplayName, textStyle: 'title', textSize: '16', textColor: 'primary'),
                            MyText(
                              text: userInfo?.phone ?? '',
                              textStyle: 'body',
                              textSize: '12',
                              textColor: 'secondary',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Menu items (use SVG icons + global text styles)
                  ListTile(
                    leading: SvgIcon(svgPath: 'assets/icons_final/personalcard.svg', width: 24, height: 24),
                    title: const MyText(
                      text: 'Thông tin tài khoản',
                      textStyle: 'title',
                      textSize: '14',
                      textColor: 'primary',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigate.pushNamed('/user-info');
                    },
                  ),
                  ListTile(
                    leading: SvgIcon(svgPath: 'assets/icons_final/setting.svg', width: 24, height: 24),
                    title: const MyText(text: 'Cài đặt', textStyle: 'title', textSize: '14', textColor: 'primary'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigate.pushNamed('/settings');
                    },
                  ),
                  // Debug FCM Token button
                  ListTile(
                    leading: SvgIcon(svgPath: 'assets/icons_final/notification.svg', width: 24, height: 24),
                    title: const MyText(
                      text: 'Test FCM Token',
                      textStyle: 'title',
                      textSize: '14',
                      textColor: 'primary',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _testFcmToken();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: SvgIcon(svgPath: 'assets/icons_final/logout.svg', width: 24, height: 24),
                    title: const MyText(text: 'Đăng xuất', textStyle: 'title', textSize: '14', textColor: 'primary'),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog() {
    AppDialogHelper.confirm(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất không?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      iconBgColor: Colors.transparent,
      confirmButtonType: ButtonType.primary,
      cancelButtonType: ButtonType.secondary,
      showIconHeader: true,
      onConfirm: () async {
        await _logout();
      },
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      AppToastHelper.showSuccess(context, message: 'Đã đăng xuất thành công');
    } catch (e) {
      AppToastHelper.showError(context, message: 'Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 100) {
      if (_showRequestSection) {
        setState(() {
          _showRequestSection = false;
        });
      }
    } else {
      if (!_showRequestSection) {
        setState(() {
          _showRequestSection = true;
        });
      }
    }
  }

  void _setupUserInfoReloadListener() {
    NavigationEventBus().onReloadUserInfo.listen((event) async {
      if (event.reason == 'announcement:activatedGarage') {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.forceRefreshUserInfo();

        // Show status notification if needed
        if (mounted) {
          _showGarageActivationNotification(userProvider);
        }
      }
    });
  }

  void _showGarageActivationNotification(UserProvider userProvider) {
    final userInfo = userProvider.userInfo;
    if (userInfo == null || !userProvider.isGarageUser) return;

    final isVerifiedGarage = userInfo.isVerifiedGarage;

    if (isVerifiedGarage == 1) {
      // Garage đã được activate
      AppToastHelper.showSuccess(context, message: 'Tài khoản gara của bạn đã được kích hoạt thành công!');
    } else if (isVerifiedGarage == 2) {
      // Garage bị từ chối
      AppToastHelper.showError(
        context,
        message: 'Tài khoản gara của bạn đã bị từ chối. Vui lòng liên hệ admin để biết thêm chi tiết.',
      );
    }
  }

  Future<void> _onRefresh() async {
    // Force refresh user info
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.forceRefreshUserInfo();
  }

  Future<void> _testFcmToken() async {
    try {
      AppToastHelper.showInfo(context, message: 'Đang test FCM token...');

      // Kiểm tra permission status trước
      await PushNotificationService.checkNotificationPermissionStatus();

      // Lấy và đăng ký FCM token
      final token = await FcmTokenService.getAndRegisterFcmToken();

      if (token != null) {
        AppToastHelper.showSuccess(context, message: 'FCM Token thành công!\nToken: ${token.substring(0, 20)}...');
      } else {
        AppToastHelper.showError(context, message: 'Không thể lấy FCM token');
      }
    } catch (e) {
      AppToastHelper.showError(context, message: 'Lỗi test FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    final isGarage = Provider.of<UserProvider>(context, listen: false).isGarageUser;
    return Scaffold(
      backgroundColor: DesignTokens.surfaceBrand,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                expandedHeight: !isLoggedIn || !isGarage ? 270 : 214,

                automaticallyImplyLeading: false,
                toolbarHeight: 80, // Tăng chiều cao của toolbar
                actions: [
                  Expanded(
                    child: Container(
                      height: 56, // Đặt chiều cao cố định cho container chứa actions
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 4),
                      child: _buildAuthActions(),
                    ),
                  ),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.5,
                  background: Stack(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: DesignTokens.surfaceBrand,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              height: 140,
                            ),
                          ),
                          Expanded(child: Container(color: DesignTokens.surfaceSecondary)),
                          Container(height: 10, color: DesignTokens.surfaceSecondary),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 64), child: _buildRequestSection()),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: DesignTokens.surfaceSecondary,
      child: Column(
        children: [
          TopProduct(),
          const SizedBox(height: 20),
          TopGara(),
          const SizedBox(height: 20),
          ReputableProducts(
            products: _reputableProducts,
            onSeeMorePressed: () {
              // TODO: Navigate to reputable products page
              AppToastHelper.showInfo(context, message: 'Tính năng đang được phát triển');
            },
          ),
          const SizedBox(height: 20),
          TopGara(),
          const SizedBox(height: 20),
          RecentReviews(
            reviews: _recentReviews,
            onSeeMorePressed: () {
              // TODO: Navigate to reviews page
              AppToastHelper.showInfo(context, message: 'Tính năng đang được phát triển');
            },
          ),
          const SizedBox(height: 20),
          TopProduct(),
          const SizedBox(height: 20),
          TopProduct(),
        ],
      ),
    );
  }

  Widget _buildRequestSection() {
    final isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
    final isGarage = Provider.of<UserProvider>(context, listen: false).isGarageUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyColors.white['c900'],
          borderRadius: BorderRadius.circular(20),
          boxShadow: DesignEffects.smallCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Dropdown
            MyDropdown(
              items: _locationItems,
              selectedValue: _selectedLocation ?? 'hanoi',
              hintText: 'Chọn địa điểm',
              title: 'Chọn địa điểm',
              label: 'Địa điểm',
              icon: SvgIcon(svgPath: 'assets/icons_final/location.svg'),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
              backgroundColor: MyColors.white['c900'],
            ),
            const SizedBox(height: 8),

            // Button đăng yêu cầu
            !isLoggedIn || !isGarage
                ? GestureDetector(
                    onTap: () {
                      if (!isLoggedIn) {
                        AppDialogHelper.confirm(
                          context,
                          title: 'Đăng nhập',
                          message: 'Vui lòng đăng nhập để đăng yêu cầu',
                          confirmText: 'Đăng nhập',
                          cancelText: 'Hủy',
                          confirmButtonType: ButtonType.primary,
                          cancelButtonType: ButtonType.secondary,
                          onConfirm: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        );
                        return;
                      }
                      Navigator.pushNamed(context, '/create-request');
                    },
                    child: Container(
                      width: double.infinity,
                      // height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignTokens.borderBrandPrimary),
                      ),
                      child: Row(
                        children: [
                          SvgIcon(svgPath: 'assets/icons_final/add-square.svg', width: 24, height: 24),
                          const SizedBox(width: 8),
                          MyText(
                            text: 'Đăng yêu cầu ngay và nhận báo giá',
                            textStyle: 'title',
                            textSize: '14',
                            textColor: 'brand',
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
