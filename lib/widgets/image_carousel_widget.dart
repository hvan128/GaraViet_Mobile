import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/utils/status/status_library.dart';

class ImageCarouselWidget extends StatefulWidget {
  final List<FileInfo> files;
  final bool isGarageUser;
  final int? status;
  final StatusType? statusType;
  final VoidCallback? onMorePressed;
  final double height;
  final bool showPageIndicators;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const ImageCarouselWidget({
    super.key,
    required this.files,
    this.isGarageUser = false,
    this.status,
    this.statusType,
    this.onMorePressed,
    this.height = 159,
    this.showPageIndicators = true,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  int _currentIndex = 0;

  Widget _buildImagePlaceholder() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.gray100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: SvgIcon(
          svgPath: 'assets/icons_final/car.svg',
          size: 32,
          color: DesignTokens.gray400,
        ),
      ),
    );
  }

  Widget _buildImageItem(FileInfo file) {
    return Image.network(
      resolveImageUrl(file.path)!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter only image files
    final imageFiles = widget.files.where((file) => file.isImage).toList();
    
    return Stack(
      children: [
        // Ảnh hoặc placeholder
        if (imageFiles.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(color: DesignTokens.gray100),
              child: CarouselSlider.builder(
                itemCount: imageFiles.length,
                itemBuilder: (context, index, realIndex) {
                  return _buildImageItem(imageFiles[index]);
                },
                options: CarouselOptions(
                  height: widget.height,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: imageFiles.length > 1,
                  autoPlay: widget.autoPlay && imageFiles.length > 1,
                  autoPlayInterval: widget.autoPlayInterval,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: false,
                  scrollDirection: Axis.horizontal,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
            ),
          )
        else
          _buildImagePlaceholder(),

        // Page indicators
        if (widget.showPageIndicators && imageFiles.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageFiles.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: _currentIndex == index ? null : Border.all(color: DesignTokens.borderPrimary),
                    color: _currentIndex == index 
                        ? DesignTokens.surfaceBrand 
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

        // Trạng thái ở góc trái trên
        if (!widget.isGarageUser && widget.status != null && widget.statusType != null) ...[
          Positioned(
            top: 8,
            left: 8,
            child: StatusWidget(
              status: widget.status!,
              type: widget.statusType!,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              borderRadius: 12,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],

        // Nút more ở góc phải trên
        if (!widget.isGarageUser && widget.onMorePressed != null) ...[
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: widget.onMorePressed,
                icon: SvgIcon(
                  svgPath: 'assets/icons_final/more.svg',
                  size: 16,
                  color: DesignTokens.textPrimary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
