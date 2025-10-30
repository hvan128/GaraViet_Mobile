import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/components/home/recent_reviews.dart';
import 'package:gara/constant/constant.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/theme/design_tokens.dart';

import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/cached_image_widget.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/widgets/skeleton.dart';

class GarageInfoScreen extends StatefulWidget {
  final UserInfoResponse garageInfo;

  const GarageInfoScreen({super.key, required this.garageInfo});

  @override
  State<GarageInfoScreen> createState() => _GarageInfoScreenState();
}

class _GarageInfoScreenState extends State<GarageInfoScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
            // Content skeleton
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
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tùy chỉnh
          MyHeader(
            height: 56,
            backgroundColor: DesignTokens.surfaceBrand,
            title: 'Thông tin gara',
            showRightButton: false,
            leftIconColor: DesignTokens.textInvert,
            customTitle: MyText(text: 'Thông tin gara', textStyle: 'head', textSize: '16', textColor: 'invert'),
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
                  _buildHighlights(),
                  const SizedBox(height: 20),
                  _buildDescription(),
                  const SizedBox(height: 20),
                  _buildServicesSection(),
                  const SizedBox(height: 20),
                  RecentReviews(reviews: Constant.recentReviews),
                  const SizedBox(height: 20),
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
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildGarageCard()),
        ],
      ),
    );
  }

  Widget _buildGarageCard() {
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
              child: CachedAvatarWidget(
                imageUrl:
                    (widget.garageInfo.avatarPath != null && widget.garageInfo.avatarPath!.isNotEmpty)
                        ? resolveImageUrl(widget.garageInfo.avatarPath!)
                        : null,
                radius: 50,
                fallbackText: widget.garageInfo.name.isNotEmpty ? widget.garageInfo.name[0].toUpperCase() : 'G',
              ),
            ),
          ),
          const SizedBox(height: 12),
          MyText(
            text: widget.garageInfo.nameGarage ?? widget.garageInfo.name,
            textStyle: 'title',
            textSize: '16',
            textColor: 'primary',
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    final addressText = (widget.garageInfo.address ?? '').isNotEmpty ? widget.garageInfo.address! : 'Chưa có địa chỉ';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _pill(
                icon: SvgIcon(svgPath: 'assets/icons_final/document-text.svg', size: 16),
                label: 'Đơn hoàn thành',
                value: '1200',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pill(
                icon: SvgIcon(svgPath: 'assets/icons_final/star_outline.svg', size: 16),
                label: 'Đánh giá',
                value: '4.8',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.garageInfo.activeFrom != null && widget.garageInfo.activeFrom!.isNotEmpty) ...[
              Expanded(
                child: _pill(
                  icon: SvgIcon(svgPath: 'assets/icons_final/award.svg'),
                  label: 'Hoạt động từ',
                  value: widget.garageInfo.activeFrom!,
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
        (widget.garageInfo.descriptionGarage ?? '').isNotEmpty
            ? widget.garageInfo.descriptionGarage!
            : 'Chưa có mô tả.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(text: 'Mô tả', textStyle: 'body', textSize: '12', textColor: 'secondary'),
        const SizedBox(height: 4),
        MyText(text: desc, textStyle: 'body', textSize: '12', textColor: 'primary'),
      ],
    );
  }

  Widget _buildServicesSection() {
    final images = widget.garageInfo.listFileAvatar?.map((e) => e.path).toList() ?? const <String>[];
    final certificateImages = widget.garageInfo.listFileCertificate?.map((e) => e.path).toList() ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(text: 'Dịch vụ cung cấp và chuyên môn', textStyle: 'title', textSize: '16', textColor: 'primary'),
        const SizedBox(height: 8),
        if (widget.garageInfo.servicesProvided != null && widget.garageInfo.servicesProvided!.isNotEmpty) ...[
          MyText(text: widget.garageInfo.servicesProvided!, textStyle: 'body', textSize: '12', textColor: 'tertiary'),
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
                itemBuilder: (ctx, i) => _certificateItem(certificateImages.isNotEmpty ? certificateImages[i] : null),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: certificateImages.isEmpty ? 1 : certificateImages.length.clamp(1, 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _certificateItem(String? imageUrl) {
    final resolvedUrl = imageUrl != null ? resolveImageUrl(imageUrl) : null;

    return GestureDetector(
      onTap: () {
        if (resolvedUrl != null) {
          _showFullscreenImage([resolvedUrl], 0);
        }
      },
      child: ClipRRect(
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
      ),
    );
  }

  Widget _serviceItem(String? imageUrl) {
    return GestureDetector(
      onTap: () {
        if (imageUrl != null) {
          _showFullscreenImage([imageUrl], 0);
        }
      },
      child: ClipRRect(
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
      ),
    );
  }

  void _showFullscreenImage(List<String> imageUrls, int initialIndex) {
    // Convert string URLs to FileInfo objects for the fullscreen viewer
    final fileInfos =
        imageUrls
            .map(
              (url) => FileInfo(
                id: 0,
                path: url,
                name: 'image',
                timeUpload: DateTime.now().toIso8601String(),
                fileType: 'image',
                fileSize: 0,
                mimeType: 'image/jpeg',
              ),
            )
            .toList();

    Navigator.pushNamed(context, '/image-viewer', arguments: {'files': fileInfos, 'initialIndex': initialIndex});
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
