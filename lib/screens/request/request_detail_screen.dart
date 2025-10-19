import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gara/models/request/request_service_model.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/utils/url.dart';
import 'package:provider/provider.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/messaging/messaging_service.dart';
import 'package:gara/services/quotation/quotation_service.dart';
import 'package:gara/services/messaging/messaging_event_bus.dart';
import 'package:gara/widgets/text_field.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestServiceModel item;

  const RequestDetailScreen({super.key, required this.item});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  bool get isGarageUser {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.isGarageUser;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onMessagePressed() async {
    final item = widget.item;
    try {
      final res = await MessagingServiceApi.createRoomFromRequest(
        requestServiceId: item.id,
      );
      if (!mounted) return;
      if (res.success && res.data != null && res.data!.roomId.isNotEmpty) {
        Navigator.pushNamed(context, '/chat-room', arguments: res.data!.roomId);
      } else {
        AppToastHelper.showError(context, message: 'Không thể mở phòng chat.');
      }
    } catch (_) {
      if (!mounted) return;
      AppToastHelper.showError(context, message: 'Không thể mở phòng chat.');
    }
  }

  void _onQuotationPressed() {
    final item = widget.item;
    if (isGarageUser) {
      _showQuotationBottomSheet(item);
    } else {
      Navigator.pushNamed(context, '/quotation-list', arguments: item);
    }
  }

  void _showQuotationBottomSheet(RequestServiceModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuotationBottomSheet(
        item: item,
        onSuccess: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFiles = widget.item.listImageAttachment.where((f) => f.isImage).toList();

    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: MyButton(
                text: 'Nhắn tin',
                height: 36,
                onPressed: _onMessagePressed,
                buttonType: ButtonType.secondary,
                textStyle: 'label',
                textSize: '14',
                textColor: 'primary',
                startIcon: 'assets/icons_final/message-text.svg',
                sizeStartIcon: const Size(18, 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MyButton(
                text: isGarageUser ? 'Báo giá' : 'Danh sách báo giá',
                height: 36,
                onPressed: _onQuotationPressed,
                buttonType: ButtonType.primary,
                textStyle: 'label',
                textSize: '14',
                textColor: 'primary',
                startIcon: 'assets/icons_final/money-2.svg',
                colorStartIcon: DesignTokens.surfacePrimary,
                sizeStartIcon: const Size(18, 18),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Vùng ảnh full-bleed với nút back overlay
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: imageFiles.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    final url = resolveImageUrl(imageFiles[index].path);
                    if (url == null) {
                      return Container(
                        color: DesignTokens.gray100,
                        child: Center(
                          child: SvgIcon(
                            svgPath: 'assets/icons_final/car.svg',
                            size: 48,
                            color: DesignTokens.gray400,
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/image-viewer',
                          arguments: {
                            'files': imageFiles,
                            'initialIndex': index,
                          },
                        );
                      },
                      child: Image.network(url, fit: BoxFit.cover),
                    );
                  },
                ),
                // Dots indicators (xanh/trắng) ở dưới giữa
                if (imageFiles.length > 1)
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
                            color: _currentIndex == index ? DesignTokens.surfaceBrand : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 20,
                  child: SafeArea(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: SvgIcon(
                              svgPath: 'assets/icons_final/arrow-left.svg',
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hàng thumbnail dưới carousel
          if (imageFiles.isNotEmpty)
            Container(
              color: DesignTokens.surfacePrimary,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                height: 56,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(imageFiles.length, (index) {
                      final file = imageFiles[index];
                      final url = resolveImageUrl(file.path);
                      return Padding(
                        padding: EdgeInsets.only(right: index == imageFiles.length - 1 ? 0 : 8),
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 70,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _currentIndex == index ? DesignTokens.surfaceBrand : DesignTokens.borderSecondary,
                                width: _currentIndex == index ? 2 : 1,
                              ),
                              color: DesignTokens.gray100,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: url == null
                                ? SvgIcon(
                                    svgPath: 'assets/icons_final/car.svg',
                                    size: 24,
                                    color: DesignTokens.gray400,
                                  )
                                : Image.network(url, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Tiêu đề xe + thời gian
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: MyText(
                        text: widget.item.carInfo != null
                            ? '${widget.item.carInfo!.typeCar} ${widget.item.carInfo!.yearModel}'
                            : 'Thông tin xe',
                        textStyle: 'head',
                        textSize: '18',
                        textColor: 'primary',
                      ),
                    ),
                    SvgIcon(
                      svgPath: 'assets/icons_final/clock.svg',
                      size: 16,
                      color: DesignTokens.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    MyText(
                      text: widget.item.timeAgo ?? widget.item.createdAt.replaceFirst('T', ' ').split('.').first,
                      textStyle: 'body',
                      textSize: '12',
                      textColor: 'tertiary',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Mã đơn nhạt màu
                MyText(
                  text: widget.item.requestCode.isNotEmpty ? widget.item.requestCode : '${widget.item.id}',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: 'tertiary',
                ),
                const SizedBox(height: 16),
                // Vị trí + icon map
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MyText(
                      text: 'Vị trí: ',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'tertiary',
                    ),
                    MyText(
                      text: widget.item.address,
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),
                    const SizedBox(width: 8),
                    SvgIcon(
                      svgPath: 'assets/icons_final/map.svg',
                      size: 20,
                      color: DesignTokens.surfaceBrand,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MyText(
                  text: 'Mô tả yêu cầu',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
                const SizedBox(height: 4),
                if ((widget.item.description ?? '').isNotEmpty)
                  MyText(
                    text: widget.item.description ?? '',
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'secondary',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotationBottomSheet extends StatefulWidget {
  final RequestServiceModel item;
  final VoidCallback onSuccess;

  const _QuotationBottomSheet({required this.item, required this.onSuccess});

  @override
  State<_QuotationBottomSheet> createState() => _QuotationBottomSheetState();
}

class _QuotationBottomSheetState extends State<_QuotationBottomSheet> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;

  String formatPrice(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return '';
    final number = int.tryParse(digitsOnly) ?? 0;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.'
    );
    return formatted;
  }

  int getNumericPrice(String formattedPrice) {
    final digitsOnly = formattedPrice.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  Future<void> createQuotation() async {
    if (isLoading) return;
    final price = getNumericPrice(priceController.text);
    final description = descriptionController.text.trim();
    if (price <= 0) {
      AppToastHelper.showError(context, message: 'Vui lòng nhập giá dự kiến');
      return;
    }
    if (description.isEmpty) {
      AppToastHelper.showWarning(context, message: 'Vui lòng nhập mô tả chi tiết');
      return;
    }
    setState(() => isLoading = true);
    try {
      final response = await QuotationServiceApi.createQuotation(
        requestServiceId: widget.item.id,
        price: price,
        description: description,
      );
      if (!mounted) return;
      if (response.success) {
        Navigator.pop(context);
        AppToastHelper.showSuccess(context, message: 'Gửi báo giá thành công!');
        // Thông báo danh sách phòng chat có thể thay đổi để màn Tin nhắn cập nhật
        MessagingEventBus().emitRoomsDirty();
        widget.onSuccess();
      } else {
        AppToastHelper.showError(context, message: 'Không thể gửi báo giá. Vui lòng thử lại sau.');
      }
    } catch (_) {
      if (!mounted) return;
      AppToastHelper.showError(context, message: 'Không thể gửi báo giá. Vui lòng thử lại sau.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 376,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        ),
        child: Column(
          children: [
            // Header giống màn RequestScreen
            Row(
              children: [
                Expanded(
                  child: MyText(
                    text: 'Gửi báo giá',
                    textStyle: 'title',
                    textSize: '16',
                    textColor: 'primary',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price input field (MyTextField như RequestScreen)
                  MyTextField(
                    controller: priceController,
                    label: 'Giá dự kiến*',
                    hintText: 'Nhập giá dự kiến (VND)',
                    obscureText: false,
                    hasError: false,
                    keyboardType: TextInputType.number,
                    onChange: (value) {
                      final formatted = formatPrice(value);
                      if (formatted != value) {
                        priceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Description input field
                  MyTextField(
                    controller: descriptionController,
                    label: 'Mô tả',
                    hintText: 'Nhập mô tả',
                    height: 144,
                    obscureText: false,
                    hasError: false,
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Hủy',
                          height: 36,
                          onPressed: () => Navigator.pop(context),
                          buttonType: ButtonType.secondary,
                          textStyle: 'label',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyButton(
                          text: isLoading ? 'Đang gửi...' : 'Gửi báo giá',
                          height: 36,
                          onPressed: isLoading ? null : createQuotation,
                          buttonType: isLoading ? ButtonType.disable : ButtonType.primary,
                          textStyle: 'label',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



