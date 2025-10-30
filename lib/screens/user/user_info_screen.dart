import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/components/home/recent_reviews.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/models/review/garage_review_response_model.dart';
import 'package:gara/models/review/review_model.dart';
import 'package:gara/services/review/review_service.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:provider/provider.dart';

import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/cached_image_widget.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/widgets/skeleton.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  UserInfoResponse? _userInfo;
  bool _isLoading = true;
  String? _errorMessage;
  bool _notificationsEnabled = true;
  String _languageCode = 'VN';

  // Thêm state cho reviews
  GarageReviewResponse? _garageReviews;
  bool _isLoadingReviews = false;
  String? _reviewsErrorMessage;

  bool get _isGarageUser {
    final info = _userInfo;
    if (info == null) return false;
    final code = info.roleCode.toUpperCase();
    return info.roleId == 3 || code == 'GARA' || code == 'GARAGE' || code.contains('GARAGE');
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Set status bar (system notification area) color to surfaceBrand with light icons
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: DesignTokens.surfaceBrand,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: DesignTokens.surfacePrimary,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userInfo = userProvider.userInfo;

      if (userInfo == null) {
        // Nếu chưa có user info, refresh từ provider
        await userProvider.refreshUserInfo();
        final refreshedUserInfo = userProvider.userInfo;
        // print('userInfo (refreshed): ${refreshedUserInfo?.toJson()}');
        setState(() {
          _userInfo = refreshedUserInfo;
          _isLoading = false;
        });
      } else {
        // print('userInfo: ${userInfo.toJson()}');
        setState(() {
          _userInfo = userInfo;
          _isLoading = false;
        });
      }

      // Load reviews nếu là garage user
      if (_isGarageUser && _userInfo != null) {
        await _loadGarageReviews();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGarageReviews() async {
    if (_userInfo == null) return;

    setState(() {
      _isLoadingReviews = true;
      _reviewsErrorMessage = null;
    });

    try {
      final reviews = await ReviewService.getReviewsByGarage(_userInfo!.id);
      setState(() {
        _garageReviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() {
        _reviewsErrorMessage = e.toString();
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: DesignTokens.surfaceSecondary, body: SafeArea(child: _buildBody()));
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header giả
            Container(height: 56, color: DesignTokens.surfaceBrand),
            Container(height: 12, color: DesignTokens.surfaceBrand),
            // Hero section skeleton
            Container(
              color: DesignTokens.surfaceSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Skeleton.circle(size: 64),
                  const SizedBox(height: 12),
                  Skeleton.line(width: 120, height: 16),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Card settings skeleton
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [Skeleton.box(height: 120), const SizedBox(height: 12), Skeleton.box(height: 160)],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Có lỗi xảy ra', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadUserInfo, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_userInfo == null) {
      return const Center(child: Text('Không có thông tin người dùng'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tùy chỉnh
          MyHeader(
            height: 56,
            backgroundColor: DesignTokens.surfaceBrand,
            title: 'Hồ sơ',
            showRightButton: true,
            rightIcon: SvgIcon(svgPath: 'assets/icons_final/edit-2.svg', size: 24, color: DesignTokens.textInvert),
            rightIconColor: DesignTokens.textInvert,
            leftIconColor: DesignTokens.textInvert,
            customTitle: MyText(text: 'Hồ sơ', textStyle: 'head', textSize: '16', textColor: 'invert'),
            onRightPressed: () async {
              if (_userInfo != null) {
                final result = await Navigator.of(context).pushNamed('/user-info/edit', arguments: _userInfo);
                if (!mounted) return;
                if (result == true) {
                  // Refresh UserProvider - Consumer sẽ tự động cập nhật UI
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  await userProvider.refreshUserInfo();
                  // Không cần setState vì Consumer sẽ tự động rebuild
                }
              }
            },
          ),
          Container(height: 12, color: DesignTokens.surfaceBrand),
          _buildHeroSection(),
          Container(
            decoration: const BoxDecoration(color: DesignTokens.surfaceSecondary),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isGarageUser) ...[
                    _buildHighlights(),
                    const SizedBox(height: 20),
                    _buildDescription(),
                    const SizedBox(height: 20),
                    _buildServicesSection(),
                    const SizedBox(height: 20),
                    _buildReviewsSection(),
                    const SizedBox(height: 20),
                  ],
                  _buildSettingsCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Thông báo
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Row(
              children: [
                const Expanded(
                  child: MyText(text: 'Thông báo', textStyle: 'title', textSize: '16', textColor: 'primary'),
                ),
                Switch.adaptive(
                  value: _notificationsEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: DesignTokens.textBrand,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Ngôn ngữ
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Row(
              children: [
                const Expanded(
                  child: MyText(text: 'Ngôn ngữ', textStyle: 'title', textSize: '16', textColor: 'primary'),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: mở modal chọn ngôn ngữ
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.borderSecondary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText(text: _languageCode, textStyle: 'title', textSize: '14', textColor: 'primary'),
                        const SizedBox(width: 4),
                        SvgIcon(svgPath: 'assets/icons_final/arrow-down.svg', size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Quyền riêng tư & bảo mật
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              // TODO: điều hướng đến màn cài đặt quyền riêng tư
            },
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: MyText(
                      text: 'Quyền riêng tư & bảo mật',
                      textStyle: 'title',
                      textSize: '16',
                      textColor: 'primary',
                    ),
                  ),
                  SvgIcon(svgPath: 'assets/icons_final/arrow-right.svg', size: 24, color: DesignTokens.textBrand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      color: DesignTokens.surfaceSecondary,
      height: 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: DesignTokens.surfaceBrand,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildUserCard()),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      height: 132,
      decoration: BoxDecoration(color: DesignTokens.surfacePrimary, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      width: double.infinity,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final currentUserInfo = userProvider.userInfo ?? _userInfo;
                  if (currentUserInfo == null) return const SizedBox();
                  final String? avatarPath = currentUserInfo.avatarPath;
                  return CachedAvatarWidget(
                    imageUrl: (avatarPath != null && avatarPath.isNotEmpty) ? resolveImageUrl(avatarPath) : null,
                    radius: 50,
                    fallbackText: currentUserInfo.name.isNotEmpty ? currentUserInfo.name[0].toUpperCase() : 'U',
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final currentUserInfo = userProvider.userInfo ?? _userInfo;
              return MyText(text: currentUserInfo!.name, textStyle: 'title', textSize: '16', textColor: 'primary');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUserInfo = userProvider.userInfo ?? _userInfo;
        final addressText = (currentUserInfo?.address ?? '').isNotEmpty ? currentUserInfo!.address! : 'Chưa có địa chỉ';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _pill(
                    icon: SvgIcon(svgPath: 'assets/icons_final/document-text.svg', size: 16),
                    label: 'Tổng đánh giá',
                    value: _garageReviews?.total.toString() ?? '0',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pill(
                    icon: SvgIcon(svgPath: 'assets/icons_final/star_outline.svg', size: 16),
                    label: 'Đánh giá TB',
                    value: _garageReviews?.averageRating.toStringAsFixed(1) ?? '0.0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (currentUserInfo?.activeFrom != null && currentUserInfo!.activeFrom!.isNotEmpty) ...[
                  Expanded(
                    child: _pill(
                      icon: SvgIcon(svgPath: 'assets/icons_final/award.svg'),
                      label: 'Hoạt động từ',
                      value: currentUserInfo.activeFrom!,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _pill(
                    icon: SvgIcon(svgPath: 'assets/icons_final/location.svg', color: DesignTokens.textPrimary),
                    label: 'Vị trí',
                    value: addressText,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescription() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUserInfo = userProvider.userInfo ?? _userInfo;
        final desc = (currentUserInfo?.descriptionGarage ?? '').isNotEmpty
            ? currentUserInfo!.descriptionGarage!
            : 'Chưa có mô tả.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: 'Mô tả', textStyle: 'body', textSize: '12', textColor: 'secondary'),
            const SizedBox(height: 4),
            MyText(text: desc, textStyle: 'body', textSize: '12', textColor: 'primary'),
          ],
        );
      },
    );
  }

  Widget _buildServicesSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUserInfo = userProvider.userInfo ?? _userInfo;
        final images = currentUserInfo?.listFileAvatar?.map((e) => e.path).toList() ?? const <String>[];
        final certificateImages = currentUserInfo?.listFileCertificate?.map((e) => e.path).toList() ?? const <String>[];

        // debugPrint('[UserInfoScreen] _buildServicesSection called');
        // debugPrint('[UserInfoScreen] listFileAvatar: ${currentUserInfo?.listFileAvatar}');
        // debugPrint('[UserInfoScreen] listFileCertificate: ${currentUserInfo?.listFileCertificate}');
        // debugPrint('[UserInfoScreen] images.length: ${images.length}');
        // debugPrint('[UserInfoScreen] certificateImages.length: ${certificateImages.length}');

        for (int i = 0; i < images.length; i++) {
          // debugPrint('[UserInfoScreen] Service image $i: ${images[i]}');
        }

        for (int i = 0; i < certificateImages.length; i++) {
          // debugPrint('[UserInfoScreen] Certificate image $i: ${certificateImages[i]}');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: 'Dịch vụ cung cấp và chuyên môn', textStyle: 'title', textSize: '1162', textColor: 'primary'),
            const SizedBox(height: 8),
            if (currentUserInfo?.servicesProvided != null && currentUserInfo!.servicesProvided!.isNotEmpty) ...[
              MyText(text: currentUserInfo.servicesProvided!, textStyle: 'body', textSize: '12', textColor: 'tertiary'),
              const SizedBox(height: 4),
            ],
            Container(
              decoration: BoxDecoration(color: DesignTokens.surfaceSecondary),
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (ctx, i) => _serviceItem(images[i]),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: images.length,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: 'Chứng chỉ', textStyle: 'body', textSize: '12', textColor: 'tertiary'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (ctx, i) =>
                        _certificateItem(certificateImages.isNotEmpty ? certificateImages[i] : null),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: certificateImages.isEmpty ? 1 : certificateImages.length.clamp(1, 10),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _certificateItem(String? imageUrl) {
    final resolvedUrl = imageUrl != null ? resolveImageUrl(imageUrl) : null;
    // debugPrint('[UserInfoScreen] _certificateItem: imageUrl=$imageUrl, resolvedUrl=$resolvedUrl');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: DesignTokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.borderSecondary),
        ),
        child: CachedImageWidget(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          placeholder: Center(child: Skeleton.box(height: 80)),
          errorWidget: Center(child: SvgIcon(svgPath: 'assets/icons_final/document-text.svg', size: 20)),
        ),
      ),
    );
  }

  Widget _serviceItem(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: DesignTokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.borderSecondary),
        ),
        child: CachedImageWidget(
          imageUrl: imageUrl != null ? resolveImageUrl(imageUrl) : null,
          fit: BoxFit.cover,
          errorWidget: Center(
            child: SizedBox(width: 20, height: 20, child: SvgIcon(svgPath: 'assets/icons_final/car.svg', size: 20)),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.line(width: 150, height: 16),
          const SizedBox(height: 12),
          Skeleton.box(height: 100),
        ],
      );
    }

    if (_reviewsErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.borderSecondary),
        ),
        child: Column(
          children: [
            MyText(text: 'Đánh giá gần đây', textStyle: 'title', textSize: '16', textColor: 'primary'),
            const SizedBox(height: 8),
            MyText(text: 'Không thể tải đánh giá', textStyle: 'body', textSize: '12', textColor: 'secondary'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadGarageReviews,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_garageReviews == null || _garageReviews!.reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.borderSecondary),
        ),
        child: Column(
          children: [
            MyText(text: 'Đánh giá gần đây', textStyle: 'title', textSize: '16', textColor: 'primary'),
            const SizedBox(height: 8),
            MyText(text: 'Chưa có đánh giá nào', textStyle: 'body', textSize: '12', textColor: 'secondary'),
          ],
        ),
      );
    }

    // Convert GarageReview to ReviewModel for RecentReviews component
    final reviewModels = _garageReviews!.reviews.take(5).map((garageReview) {
      return ReviewModel(
        id: garageReview.id.toString(),
        userName: garageReview.createdBy.name,
        userAvatar: null, // API không trả về avatar
        serviceName: 'Dịch vụ garage', // Có thể cần lấy từ quotation hoặc request service
        comment: garageReview.comment,
        rating: garageReview.starRating.round(),
        createdAt: DateTime.tryParse(garageReview.createdAt),
        context: 'Vietnam car',
      );
    }).toList();

    return RecentReviews(
      reviews: reviewModels,
      onSeeMorePressed: () {
        // TODO: Navigate to full reviews screen
      },
    );
  }

  Widget _pill({required Widget icon, required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            if (label.isNotEmpty) MyText(text: label, textStyle: 'body', textSize: '12', textColor: 'secondary'),
          ],
        ),
        const SizedBox(height: 4),
        MyText(text: value, textStyle: 'title', textSize: '14', textColor: 'brand'),
      ],
    );
  }
}
