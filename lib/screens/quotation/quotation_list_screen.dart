import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/services/quotation/quotation_service.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/models/request/request_service_model.dart';
import 'package:gara/utils/status/status_library.dart';

class QuotationListScreen extends StatefulWidget {
  final RequestServiceModel? requestItem;

  const QuotationListScreen({super.key, this.requestItem});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  bool _loading = true;
  List<QuotationModel> _quotations = [];
  String _errorMessage = '';

  String _normalizeSingleLine(String? input) {
    final String value = input ?? '';
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  void initState() {
    super.initState();
    _fetchQuotations();
    // Set status bar color to surfaceBrand with light icons
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: DesignTokens.surfaceBrand,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  String _buildRoomId(QuotationModel quotation) {
    DebugLogger.log('quotation.inforGarage: ${quotation.inforGarage?.toJson().toString()}');
    DebugLogger.log('widget.requestItem?.inforUser: ${widget.requestItem?.inforUser?.toJson().toString()}');
    final int requestId = quotation.requestServiceId;
    // Gara id: ưu tiên userId; nếu = 0 thì fallback sang id
    final int garaUserId = (quotation.inforGarage?.userId ?? 0) != 0
        ? (quotation.inforGarage?.userId ?? 0)
        : (quotation.inforGarage?.id ?? 0);
    // User id: ưu tiên userId; nếu = 0 thì fallback sang id
    final int userId = (widget.requestItem?.inforUser?.userId ?? 0) != 0
        ? (widget.requestItem?.inforUser?.userId ?? 0)
        : (widget.requestItem?.inforUser?.id ?? 0);
    return 'room_req${requestId}_${garaUserId}_$userId';
  }

  @override
  void dispose() {
    // Restore default status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: DesignTokens.surfacePrimary,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  Future<void> _fetchQuotations() async {
    if (widget.requestItem == null) {
      setState(() {
        _errorMessage = 'Không có thông tin yêu cầu dịch vụ';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final response = await QuotationServiceApi.getQuotationsByRequestId(
        requestServiceId: widget.requestItem!.id,
      );

      if (mounted) {
        setState(() {
          _quotations = response.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải danh sách báo giá: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: false,
              expandedHeight: 350,
              automaticallyImplyLeading: false,
              toolbarHeight: 80,
              title: Padding(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 20,
                  top: 4,
                  bottom: 4,
                ),
                child: SizedBox(
                  height: 56,
                  child: _buildHeader(),
                ),
              ),
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
                          child: Container(color: DesignTokens.surfacePrimary),
                        ),
                        Container(
                          height: 10,
                          color: DesignTokens.surfacePrimary,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: _buildRequestInfoCard(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SvgIcon(
                svgPath: 'assets/icons_final/arrow-left.svg',
                size: 24,
                color: DesignTokens.textInvert,
              ),
            ),
            const SizedBox(width: 8),
            MyText(
              text: 'Danh sách báo giá',
              textStyle: 'head',
              textSize: '16',
              textColor: 'invert',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestInfoCard() {
    if (widget.requestItem == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: DesignEffects.smallCardShadow,
        ),
        child: _buildRequestCard(widget.requestItem!),
      ),
    );
  }

  Widget _buildRequestCard(RequestServiceModel item) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ảnh hoặc placeholder
          _buildImageSection(item),
          // Nội dung dưới ảnh
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row: Type xe + đời xe, mã đơn
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: MyText(
                              text:
                                  item.carInfo != null
                                      ? '${item.carInfo!.typeCar} ${item.carInfo!.yearModel}'
                                      : 'Thông tin xe',
                              textStyle: 'head',
                              textSize: '16',
                              textColor: 'primary',
                            ),
                          ),
                          Flexible(
                            child: MyText(
                              text: _normalizeSingleLine(
                                item.requestCode.isNotEmpty
                                    ? item.requestCode
                                    : 'Mã đơn #${item.id}',
                              ),
                              textStyle: 'body',
                              textSize: '12',
                              textColor: 'tertiary',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Mô tả
                if ((item.description ?? '').isNotEmpty) ...[
                  MyText(
                    text: item.description ?? '',
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'secondary',
                  ),
                ],
                const SizedBox(height: 12),
                // Row: Thời gian, nút Danh sách báo giá
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgIcon(
                            svgPath: 'assets/icons_final/clock.svg',
                            size: 16,
                            color: DesignTokens.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          MyText(
                            text:
                                item.timeAgo ??
                                item.createdAt
                                    .replaceFirst('T', ' ')
                                    .split('.')
                                    .first,
                            textStyle: 'body',
                            textSize: '12',
                            textColor: 'tertiary',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(RequestServiceModel item) {
    return Stack(
      children: [
        // Ảnh hoặc placeholder
        if (item.listImageAttachment.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: 159,
              width: double.infinity,
              decoration: BoxDecoration(color: DesignTokens.gray100),
              child: Image.network(
                resolveImageUrl(item.listImageAttachment.first.path) ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              ),
            ),
          )
        else
          _buildImagePlaceholder(),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 159,
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

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: DesignTokens.surfacePrimary,
      child: Column(
        children: [
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ] else if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(
                    svgPath: 'assets/icons_final/close-circle.svg',
                    size: 48,
                    color: DesignTokens.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  MyText(
                    text: _errorMessage,
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'tertiary',
                  ),
                  const SizedBox(height: 16),
                  MyButton(
                    text: 'Thử lại',
                    onPressed: _fetchQuotations,
                    buttonType: ButtonType.primary,
                    textStyle: 'label',
                    textSize: '14',
                    textColor: 'primary',
                  ),
                ],
              ),
            ),
          ] else if (_quotations.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(
                    svgPath: 'assets/icons_final/document-text.svg',
                    size: 48,
                    color: DesignTokens.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  MyText(
                    text: 'Chưa có báo giá nào',
                    textStyle: 'head',
                    textSize: '16',
                    textColor: 'secondary',
                  ),
                  const SizedBox(height: 8),
                  MyText(
                    text: 'Các gara sẽ gửi báo giá cho yêu cầu của bạn',
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'tertiary',
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                MyText(
                  text: 'Danh sách báo giá',
                  textStyle: 'head',
                  textSize: '16',
                  textColor: 'primary',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quotations.length,
              itemBuilder: (context, index) {
                final quotation = _quotations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuotationCard(quotation),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          if (_quotations.length > 1) ...[
            Builder(
              builder: (context) {
                final double remainingHeight =
                    MediaQuery.of(context).size.height -
                    _quotations.length * 160 - 64;
                if (remainingHeight > 0) {
                  return SizedBox(height: remainingHeight);
                }
                return const SizedBox.shrink();
              },
            ),
          ] else ...[
            const SizedBox.shrink(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotationCard(QuotationModel quotation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with garage info and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    MyText(
                      text:
                            quotation.inforGarage?.nameGarage ??
                          'Gara #${quotation.inforGarage?.id ?? ''}',
                      textStyle: 'head',
                      textSize: '16',
                      textColor: 'primary',
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        SvgIcon(
                          svgPath: 'assets/icons_final/location.svg',
                          size: 16,
                          color: DesignTokens.textPlaceholder,
                        ),
                        const SizedBox(width: 4),
                        MyText(
                          text: '8.3 km',
                          textStyle: 'body',
                          textSize: '12',
                          textColor: 'tertiary',
                        ),
                      ],
                    ),
                  ],
                ),
                StatusWidget(
                  status: quotation.status,
                  type: StatusType.quotation,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // if (quotation.codeQuotation != null) ...[
            //   Row(
            //     children: [
            //       MyText(
            //         text: 'Mã báo giá: ',
            //         textStyle: 'label',
            //         textSize: '12',
            //         textColor: 'secondary',
            //       ),
            //       MyText(
            //         text: quotation.codeQuotation!,
            //         textStyle: 'label',
            //         textSize: '12',
            //         textColor: 'primary',
            //       ),
            //     ],
            //   ),
            //   const SizedBox(height: 8),
            // ],
            // Description
            MyText(
              text:
                  quotation.warranty != null
                      ? '${quotation.description}, bảo hành ${quotation.warranty} tháng'
                      : quotation.description,
              textStyle: 'body',
              textSize: '14',
              textColor: 'secondary',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Created time
            // Row(
            //   children: [
            //     SvgIcon(
            //       svgPath: 'assets/icons_final/clock.svg',
            //       size: 16,
            //       color: DesignTokens.textTertiary,
            //     ),
            //     const SizedBox(width: 6),
            //     MyText(
            //       text: quotation.timeAgo ?? _formatDateTime(quotation.createdAt),
            //       textStyle: 'body',
            //       textSize: '12',
            //       textColor: 'tertiary',
            //     ),
            //   ],
            // ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyText(
                  text: 'Giá: ',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
                MyText(
                  text: quotation.formattedPrice,
                  textStyle: 'title',
                  textSize: '16',
                  textColor: 'brand',
                ),
                MyText(
                  text: 'đ',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: 'secondary',
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Action buttons
            Builder(
              builder: (context) {
                final bool isCancelled =
                    quotation.status == QuotationModel.cancelled;
                final bool hideBooking = quotation.status == QuotationModel.noDeposit ||
                    quotation.status == QuotationModel.depositPaid ||
                    quotation.status == QuotationModel.notYetCharge ||
                    quotation.status == QuotationModel.chargePaid ||
                    quotation.status == QuotationModel.cancelled;
                final bool showChat = !isCancelled;

                if (!showChat && hideBooking) {
                  return const SizedBox.shrink();
                }

                if (showChat && hideBooking) {
                  return Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Nhắn tin',
                          height: 30,
                          onPressed: () {
                            final String roomId = _buildRoomId(quotation);
                            Navigator.pushNamed(
                              context,
                              '/chat-room',
                              arguments: roomId,
                            );
                          },
                          buttonType: ButtonType.secondary,
                          textStyle: 'label',
                          textSize: '12',
                          textColor: 'primary',
                          startIcon: 'assets/icons_final/message-text.svg',
                          sizeStartIcon: const Size(16, 16),
                        ),
                      ),
                    ],
                  );
                }

                if (showChat && !hideBooking) {
                  return Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Nhắn tin',
                          height: 30,
                          onPressed: () {
                            final String roomId = _buildRoomId(quotation);
                            Navigator.pushNamed(
                              context,
                              '/chat-room',
                              arguments: roomId,
                            );
                          },
                          buttonType: ButtonType.secondary,
                          textStyle: 'label',
                          textSize: '12',
                          textColor: 'primary',
                          startIcon: 'assets/icons_final/message-text.svg',
                          sizeStartIcon: const Size(16, 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyButton(
                          text: 'Đặt lịch',
                          height: 30,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/booking',
                              arguments: quotation,
                            );
                          },
                          buttonType: ButtonType.primary,
                          textStyle: 'label',
                          textSize: '12',
                          textColor: 'primary',
                          startIcon: 'assets/icons_final/calendar.svg',
                          colorStartIcon: DesignTokens.surfacePrimary,
                          sizeStartIcon: const Size(16, 16),
                        ),
                      ),
                    ],
                  );
                }

                // Fallback: only booking (shouldn't happen per rules)
                return Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: 'Đặt lịch',
                        height: 30,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/booking',
                            arguments: quotation,
                          );
                        },
                        buttonType: ButtonType.primary,
                        textStyle: 'label',
                        textSize: '12',
                        textColor: 'primary',
                        startIcon: 'assets/icons_final/calendar.svg',
                        colorStartIcon: DesignTokens.surfacePrimary,
                        sizeStartIcon: const Size(16, 16),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // (đã bỏ dùng)

  // (đã bỏ dùng)
}
