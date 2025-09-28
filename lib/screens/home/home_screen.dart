import 'package:flutter/material.dart';
import 'package:gara/components/home/top_gara.dart';
import 'package:gara/components/home/top_product.dart';
import 'package:gara/components/home/reputable_products.dart';
import 'package:gara/components/home/recent_reviews.dart';
import 'package:gara/models/reputable_product/reputable_product_model.dart';
import 'package:gara/models/review/review_model.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/services/auth/auth_state_manager.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showRequestSection = true;
  late AuthStateManager _authStateManager;
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
    _authStateManager = AuthStateManager();
    _authStateManager.addListener(_onAuthStateChanged);

    // Load user info if logged in
    if (_authStateManager.isLoggedIn) {
      _authStateManager.loadUserInfo();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authStateManager.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {
      // Rebuild when auth state changes
    });

    // Load user info if user just logged in and doesn't have user info yet
    if (_authStateManager.isLoggedIn && 
        (_authStateManager.userName == null || _authStateManager.userPhone == null)) {
      _authStateManager.loadUserInfo();
    }
  }

  Widget _buildAuthActions() {
    if (_authStateManager.isLoggedIn) {
      // User is logged in - show profile header
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
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withAlpha(20),
                  backgroundImage:
                      _authStateManager.userAvatar != null &&
                              _authStateManager.userAvatar!.isNotEmpty
                          ? NetworkImage(resolveImageUrl(_authStateManager.userAvatar!)!)
                          : null,
                  child:
                      _authStateManager.userAvatar == null ||
                              _authStateManager.userAvatar!.isEmpty
                          ? Text(
                            _authStateManager.userName?.isNotEmpty == true
                                ? _authStateManager.userName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 8),

              // Greeting text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Xin chào,',
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'invert',
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    text: _authStateManager.userName ?? 'Người dùng',
                    textStyle: 'title',
                    textSize: '14',
                    textColor: 'invert',
                  ),
                ],
              ),

              // Notification icon
            ],
          ),
        
          Row(
            children: [
              SvgIcon(
                svgPath: 'assets/icons_final/notification.svg',
                width: 24,
                height: 24,
              ),

              const SizedBox(width: 8),

              // Profile icon
              GestureDetector(
                onTap: _showAccountMenu,
                child: SvgIcon(
                  svgPath: 'assets/icons_final/profile.svg',
                  width: 24,
                  height: 24,
                ),
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
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue[600],
                    child: Text(
                      _authStateManager.userName?.isNotEmpty == true
                          ? _authStateManager.userName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _authStateManager.userName ?? 'Người dùng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _authStateManager.userPhone ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Menu items
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('Thông tin tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  Navigate.pushNamed('/user-info');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Cài đặt'),
                onTap: () {
                  Navigator.pop(context);
                  _showErrorSnackBar('Tính năng đang được phát triển');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất'),
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
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              child: Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      _showSuccessSnackBar('Đã đăng xuất thành công');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceBrand,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: false,
              expandedHeight: 270,
              
              automaticallyImplyLeading: false,
              toolbarHeight: 80, // Tăng chiều cao của toolbar
              actions: [
                Expanded(
                  child: Container(
                    height:
                        56, // Đặt chiều cao cố định cho container chứa actions
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 4,
                      bottom: 4,
                    ),
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
                        Expanded(
                          child: Container(
                            color: DesignTokens.surfaceSecondary,
                          ),
                        ),
                        Container(
                          height: 10,
                          color: DesignTokens.surfaceSecondary,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: _buildRequestSection(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildBody()),
          ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
          ),
          const SizedBox(height: 20),
          TopGara(),
          const SizedBox(height: 20),
          RecentReviews(
            reviews: _recentReviews,
            onSeeMorePressed: () {
              // TODO: Navigate to reviews page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tính năng đang được phát triển')),
              );
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
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/create-request');
              },
              child: Container(
                width: double.infinity,
                // height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DesignTokens.borderBrandPrimary),
                ),
                child: Row(
                  children: [
                    SvgIcon(
                      svgPath: 'assets/icons_final/add-square.svg',
                      width: 24,
                      height: 24,
                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
