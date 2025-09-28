import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/components/home/recent_reviews.dart';
import 'package:gara/constant/constant.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:provider/provider.dart';

import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/utils/url.dart';

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
  bool get _isGarageUser {
    final info = _userInfo;
    if (info == null) return false;
    final code = info.roleCode.toUpperCase();
    return info.roleId == 3 ||
        code == 'GARA' ||
        code == 'GARAGE' ||
        code.contains('GARAGE');
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
        print('userInfo (refreshed): ${refreshedUserInfo?.toJson()}');
        setState(() {
          _userInfo = refreshedUserInfo;
          _isLoading = false;
        });
      } else {
        print('userInfo: ${userInfo.toJson()}');
        setState(() {
          _userInfo = userInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceSecondary,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserInfo,
              child: const Text('Thử lại'),
            ),
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
            srcRightIcon: 'assets/icons_final/pen.svg',
            rightIconColor: DesignTokens.textInvert,
            leftIconColor: DesignTokens.textInvert,
            customTitle: MyText(
              text: 'Hồ sơ',
              textStyle: 'head',
              textSize: '16',
              textColor: 'invert',
            ),
            onRightPressed: () async {
              if (_userInfo != null) {
                final result = await Navigator.of(
                  context,
                ).pushNamed('/user-info/edit', arguments: _userInfo);
                if (!mounted) return;
                if (result == true) {
                  // Refresh UserProvider và cập nhật UI
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  await userProvider.refreshUserInfo();
                  _loadUserInfo();
                }
              }
            },
          ),
          Container(height: 12, color: DesignTokens.surfaceBrand),
          _buildHeroSection(),
          Container(
            decoration: const BoxDecoration(
              color: DesignTokens.surfaceSecondary,
            ),
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
                    RecentReviews(reviews: Constant.recentReviews),
                    const SizedBox(height: 20),
                  ],
                  _buildSettingsCard(),
                  const SizedBox(height: 20),
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildSessionCard(),
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
                  child: MyText(
                    text: 'Thông báo',
                    textStyle: 'title',
                    textSize: '16',
                    textColor: 'primary',
                  ),
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
                  child: MyText(
                    text: 'Ngôn ngữ',
                    textStyle: 'title',
                    textSize: '16',
                    textColor: 'primary',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: mở modal chọn ngôn ngữ
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.borderSecondary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText(
                          text: _languageCode,
                          textStyle: 'title',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                        const SizedBox(width: 4),
                        SvgIcon(
                          svgPath: 'assets/icons_final/arrow-down.svg',
                          size: 16,
                        ),
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
                  SvgIcon(
                    svgPath: 'assets/icons_final/arrow-right.svg',
                    size: 24,
                    color: DesignTokens.textBrand,
                  ),
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildUserCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      width: double.infinity,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: CircleAvatar(
                backgroundColor: DesignTokens.surfaceBrand,
                backgroundImage:
                    (_userInfo?.avatar != null && _userInfo!.avatar!.isNotEmpty)
                        ? (resolveImageUrl(_userInfo!.avatar!) != null
                            ? NetworkImage(resolveImageUrl(_userInfo!.avatar!)!)
                            : null)
                        : null,
                child:
                    (_userInfo?.avatar == null || _userInfo!.avatar!.isEmpty)
                        ? MyText(
                          text:
                              _userInfo!.name.isNotEmpty
                                  ? _userInfo!.name[0].toUpperCase()
                                  : 'U',
                          textColor: 'invert',
                        )
                        : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          MyText(
            text: _userInfo!.name,
            textStyle: 'title',
            textSize: '16',
            textColor: 'primary',
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    final addressText =
        (_userInfo?.address ?? '').isNotEmpty
            ? _userInfo!.address!
            : 'Chưa có địa chỉ';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _pill(
                icon: SvgIcon(
                  svgPath: 'assets/icons_final/document-text.svg',
                  size: 16,
                ),
                label: 'Đơn hoàn thành',
                value: '1200',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pill(
                icon: SvgIcon(
                  svgPath: 'assets/icons_final/star_outline.svg',
                  size: 16,
                ),
                label: 'Tiêu chuẩn',
                value: '1200',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_userInfo?.activeFrom != null &&
                _userInfo!.activeFrom!.isNotEmpty) ...[
              Expanded(
                child: _pill(
                  icon: SvgIcon(svgPath: 'assets/icons_final/award.svg'),
                  label: 'Hoạt động từ',
                  value: _userInfo!.activeFrom!,
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
  }

  Widget _buildDescription() {
    final desc =
        (_userInfo?.descriptionGarage ?? '').isNotEmpty
            ? _userInfo!.descriptionGarage!
            : 'Chưa có mô tả.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Mô tả',
          textStyle: 'body',
          textSize: '12',
          textColor: 'secondary',
        ),
        const SizedBox(height: 4),
        MyText(
          text: desc,
          textStyle: 'body',
          textSize: '12',
          textColor: 'primary',
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final images =
        _userInfo?.listFileAvatar?.map((e) => e.path).toList() ??
        const <String>[];
    final certificateImages =
        _userInfo?.listFileCertificate?.map((e) => e.path).toList() ??
        const <String>[];
    
    debugPrint('[UserInfoScreen] _buildServicesSection called');
    debugPrint('[UserInfoScreen] listFileAvatar: ${_userInfo?.listFileAvatar}');
    debugPrint('[UserInfoScreen] listFileCertificate: ${_userInfo?.listFileCertificate}');
    debugPrint('[UserInfoScreen] images.length: ${images.length}');
    debugPrint('[UserInfoScreen] certificateImages.length: ${certificateImages.length}');
    
    for (int i = 0; i < images.length; i++) {
      debugPrint('[UserInfoScreen] Service image $i: ${images[i]}');
    }
    
    for (int i = 0; i < certificateImages.length; i++) {
      debugPrint('[UserInfoScreen] Certificate image $i: ${certificateImages[i]}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Dịch vụ cung cấp và chuyên môn',
          textStyle: 'title',
          textSize: '1162',
          textColor: 'primary',
        ),
        const SizedBox(height: 8),
        if (_userInfo?.servicesProvided != null &&
            _userInfo!.servicesProvided!.isNotEmpty) ...[
          MyText(
            text: _userInfo!.servicesProvided!,
            textStyle: 'body',
            textSize: '12',
            textColor: 'tertiary',
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(color: DesignTokens.surfaceSecondary),
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder:
                (ctx, i) => _serviceItem(
                  images.isNotEmpty ? images[i % images.length] : null,
                ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: images.isEmpty ? 3 : images.length.clamp(3, 10),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: 'Chứng chỉ',
              textStyle: 'body',
              textSize: '12',
              textColor: 'tertiary',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder:
                    (ctx, i) => _certificateItem(
                      certificateImages.isNotEmpty
                          ? certificateImages[i]
                          : null,
                    ),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount:
                    certificateImages.isEmpty
                        ? 1
                        : certificateImages.length.clamp(1, 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _certificateItem(String? imageUrl) {
    final resolvedUrl = imageUrl != null ? resolveImageUrl(imageUrl) : null;
    debugPrint('[UserInfoScreen] _certificateItem: imageUrl=$imageUrl, resolvedUrl=$resolvedUrl');
    
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
        child:
            resolvedUrl != null
                ? Image.network(
                    resolvedUrl, 
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        debugPrint('[UserInfoScreen] Certificate image loaded: $resolvedUrl');
                        return child;
                      }
                      debugPrint('[UserInfoScreen] Certificate image loading: $resolvedUrl');
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('[UserInfoScreen] Certificate image error: $resolvedUrl, error: $error');
                      return Center(
                        child: SvgIcon(
                          svgPath: 'assets/icons_final/document-text.svg',
                          size: 20,
                        ),
                      );
                    },
                  )
                : Center(
                  child: SvgIcon(
                    svgPath: 'assets/icons_final/document-text.svg',
                    size: 20,
                  ),
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
        child:
            imageUrl != null
                ? Image.network(resolveImageUrl(imageUrl)!, fit: BoxFit.cover)
                : Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: SvgIcon(
                      svgPath: 'assets/icons_final/car.svg',
                      size: 20,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _pill({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            if (label.isNotEmpty)
              MyText(
                text: label,
                textStyle: 'body',
                textSize: '12',
                textColor: 'secondary',
              ),
          ],
        ),
        const SizedBox(height: 4),
        MyText(
          text: value,
          textStyle: 'title',
          textSize: '14',
          textColor: 'brand',
        ),
      ],
    );
  }

  String _extractYear(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return dt.year.toString();
    } catch (_) {
      return '';
    }
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin cơ bản',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID', _userInfo!.id.toString()),
            _buildInfoRow('User ID', _userInfo!.userId.toString()),
            _buildInfoRow('Tên', _userInfo!.name),
            _buildInfoRow('Số điện thoại', _userInfo!.phone),
            _buildInfoRow('Vai trò', _userInfo!.roleName),
            _buildInfoRow('Mã vai trò', _userInfo!.roleCode),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái tài khoản',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Trạng thái hoạt động',
              _userInfo!.isActive ? 'Đang hoạt động' : 'Không hoạt động',
              _userInfo!.isActive ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Xác thực số điện thoại',
              _userInfo!.isPhoneVerified ? 'Đã xác thực' : 'Chưa xác thực',
              _userInfo!.isPhoneVerified ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin phiên đăng nhập',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device ID', _userInfo!.deviceId),
            _buildInfoRow('Session ID', _userInfo!.sessionId),
            _buildInfoRow('Ngày tạo', _formatDateTime(_userInfo!.createdAt)),
            _buildInfoRow(
              'Cập nhật lần cuối',
              _formatDateTime(_userInfo!.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w400, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
