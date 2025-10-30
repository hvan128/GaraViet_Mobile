import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/services/api/auth_http_client.dart';
import 'package:gara/config.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/widgets/date_picker.dart';
import 'package:gara/widgets/time_picker.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/components/payment/deposit_modal.dart';
import 'package:gara/widgets/app_toast.dart';

class BookingScreen extends StatefulWidget {
  final QuotationModel quotation;

  const BookingScreen({super.key, required this.quotation});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _dateController = TextEditingController();
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  bool _dateError = false;
  bool _timeError = false;
  List<Map<String, dynamic>> _activeVouchers = [];
  bool _isLoadingVouchers = false;
  String? _voucherError;
  Map<String, dynamic>? _selectedVoucher;
  bool _isCreatingBooking = false;

  @override
  void initState() {
    super.initState();
    // Set status bar color to surfaceBrand with light icons
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: DesignTokens.surfaceBrand,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _fetchActiveVouchers();
  }

  @override
  void dispose() {
    _dateController.dispose();
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

  Future<void> _fetchActiveVouchers() async {
    setState(() {
      _isLoadingVouchers = true;
      _voucherError = null;
    });
    try {
      final totalAmount = widget.quotation.price;
      final response = await BaseApiService.get('/admin/vouchers/active?minorder=$totalAmount', includeAuth: false);
      final data = response['data'];
      if (data is List) {
        setState(() {
          _activeVouchers = data.whereType<Map<String, dynamic>>().toList(growable: false);
        });
      } else {
        setState(() {
          _voucherError = 'Không có dữ liệu voucher';
        });
      }
    } catch (e) {
      setState(() {
        _voucherError = 'Lỗi tải voucher: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVouchers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: false,
                    expandedHeight: 253,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 80,
                    actions: [
                      Expanded(
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 4),
                          child: _buildHeader(),
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
                              Expanded(child: Container(color: DesignTokens.surfacePrimary)),
                              Container(height: 10, color: DesignTokens.surfacePrimary),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 64), child: _buildQuotationInfoCard()),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildContent()),
                ],
              ),
            ),
            // Fixed payment summary and button at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: DesignTokens.surfacePrimary),
              child: Column(children: [_buildPaymentSummary(), const SizedBox(height: 16), _buildBookNowButton()]),
            ),
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
              child: SvgIcon(svgPath: 'assets/icons_final/arrow-left.svg', size: 24, color: DesignTokens.textInvert),
            ),
            const SizedBox(width: 8),
            MyText(text: 'Lên lịch', textStyle: 'head', textSize: '16', textColor: 'invert'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuotationInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: DesignEffects.smallCardShadow,
        ),
        child: _buildQuotationCard(widget.quotation),
      ),
    );
  }

  Widget _buildQuotationCard(QuotationModel quotation) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garage name and distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  text: quotation.inforGarage?.nameGarage ?? 'Gara #${quotation.inforGarage?.id ?? ''}',
                  textStyle: 'title',
                  textSize: '18',
                  textColor: 'primary',
                ),
                Row(
                  children: [
                    SvgIcon(svgPath: 'assets/icons_final/location.svg', size: 16, color: DesignTokens.textPlaceholder),
                    const SizedBox(width: 4),
                    MyText(text: '8.3 km', textStyle: 'body', textSize: '12', textColor: 'tertiary'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Service details
            Row(
              children: [
                MyText(text: 'Đơn hàng: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                MyText(text: 'Độ cốp điện VF8, hãng icar', textStyle: 'body', textSize: '14', textColor: 'secondary'),
              ],
            ),

            // Warranty
            if (quotation.warranty != null) ...[
              Row(
                children: [
                  MyText(text: 'Bảo hành: ', textStyle: 'body', textSize: '14', textColor: 'secondary'),
                  MyText(text: '${quotation.warranty}', textStyle: 'title', textSize: '14', textColor: 'brand'),
                  MyText(text: ' tháng', textStyle: 'body', textSize: '14', textColor: 'secondary'),
                ],
              ),
            ],

            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: 'Mô tả: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                Expanded(
                  child: MyText(
                    text: quotation.description,
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'secondary',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: DesignTokens.borderBrandSecondary, height: 1),
            const SizedBox(height: 8),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyText(text: 'Giá: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                MyText(
                  text: _formatPriceWithDots(quotation.price),
                  textStyle: 'title',
                  textSize: '18',
                  textColor: 'brand',
                ),
                MyText(text: 'đ', textStyle: 'body', textSize: '14', textColor: 'secondary'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: DesignTokens.surfacePrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Time Selection
          _buildDateTimeSection(),

          const SizedBox(height: 20),

          // Deposit and Voucher Section
          _buildDepositVoucherSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyDatePicker(
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                        _dateController.text = date.toString();
                        _dateError = false;
                      });
                    },
                    label: 'Ngày',
                    defaultValue: _selectedDate,
                    hasError: _dateError,
                    errorText: _dateError ? 'Vui lòng chọn ngày' : null,
                  ),
                  if (!_dateError && _timeError) ...[
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: 0,
                      child: MyText(
                        text: 'Vui lòng chọn giờ',
                        textStyle: 'label',
                        textSize: '12',
                        textColor: 'error',
                        lineHeight: 1.38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyTimePicker(
                    onTimeSelected: (time) {
                      setState(() {
                        _selectedTime = time;
                        _timeError = false;
                      });
                    },
                    label: 'Giờ',
                    defaultValue: _selectedTime,
                    hasError: _timeError,
                    errorText: _timeError ? 'Vui lòng chọn giờ' : null,
                  ),
                  if (!_timeError && _dateError) ...[
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: 0,
                      child: MyText(
                        text: 'Vui lòng chọn ngày',
                        textStyle: 'label',
                        textSize: '12',
                        textColor: 'error',
                        lineHeight: 1.38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepositVoucherSection() {
    final depositAmount = (widget.quotation.price * 0.03).round(); // 3% deposit

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MyText(text: 'Đặt cọc ngay ', textStyle: 'title', textSize: '16', textColor: 'primary'),
            MyText(
              text: '${_formatPriceWithDots(depositAmount)}đ',
              textStyle: 'head',
              textSize: '16',
              textColor: 'brand',
            ),
            MyText(text: ' để nhận voucher', textStyle: 'title', textSize: '16', textColor: 'primary'),
          ],
        ),
        const SizedBox(height: 8),

        // Voucher options (from API)
        if (_isLoadingVouchers) ...[
          const SizedBox(height: 4),
          (MyText(text: 'Đang tải voucher...', textStyle: 'body', textSize: '14', textColor: 'secondary')),
        ] else if (_voucherError != null) ...[
          const SizedBox(height: 4),
          (MyText(text: _voucherError!)),
        ] else if (_activeVouchers.isEmpty) ...[
          const SizedBox(height: 4),
          (MyText(text: 'Chưa có voucher đang hoạt động', textStyle: 'body', textSize: '14', textColor: 'secondary')),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final v in _activeVouchers) ...[
                _buildVoucherOptionWidget(_formatVoucherText(v), v),
                if (v != _activeVouchers.last) const SizedBox(height: 4),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // New: Build voucher option directly from MyText (with number highlight)
  Widget _buildVoucherOptionWidget(Widget widget, Map<String, dynamic> voucher) {
    final bool isSelected = _selectedVoucher != null && _selectedVoucher!['id'] == voucher['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedVoucher = null; // Bỏ chọn
            // print('Voucher deselected');
          } else {
            _selectedVoucher = voucher; // Chọn voucher này
            // print('Voucher selected: ${voucher['id']}');
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DesignTokens.primaryBlue4,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DesignTokens.borderBrandPrimary : DesignTokens.borderSecondary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(svgPath: 'assets/icons_final/discount-shape.svg', size: 20, color: DesignTokens.textBrand),
            const SizedBox(width: 4),
            widget,
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final totalAmount = widget.quotation.price;
    final depositAmount =
        _selectedVoucher != null ? (totalAmount * 0.03).round() : 0; // 3% deposit chỉ khi chọn voucher
    final voucherDiscount = _calculateVoucherDiscount(totalAmount);
    final finalAmount = totalAmount - voucherDiscount;

    // print(
    //   'Payment Summary - Total: $totalAmount, Voucher Discount: $voucherDiscount, Deposit: $depositAmount, Final: $finalAmount',
    // );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderBrandSecondary),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Voucher', '${voucherDiscount > 0 ? '- ' : ''}${_formatPriceWithDots(voucherDiscount)} đ'),
          const SizedBox(height: 8),
          _buildPaymentRow('Tiền cọc', '${depositAmount > 0 ? '- ' : ''}${_formatPriceWithDots(depositAmount)} đ'),
          const SizedBox(height: 8),
          _buildPaymentRow('Tiền cần thanh toán', '${_formatPriceWithDots(finalAmount)} đ'),
          const SizedBox(height: 8),
          Container(height: 1, color: DesignTokens.borderSecondary),
          const SizedBox(height: 8),
          _buildPaymentRow('Tổng tiền phải thanh toán', '${_formatPriceWithDots(finalAmount)} đ', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: label,
          textStyle: isTotal ? 'head' : 'body',
          textSize: isTotal ? '16' : '14',
          textColor: isTotal ? 'primary' : 'secondary',
        ),
        MyText(
          text: amount,
          textStyle: isTotal ? 'head' : 'head',
          textSize: isTotal ? '18' : '14',
          textColor: isTotal ? 'brand' : 'secondary',
        ),
      ],
    );
  }

  Widget _buildBookNowButton() {
    return SizedBox(
      width: double.infinity,
      child: MyButton(
        text: _isCreatingBooking ? 'Đang xử lý...' : 'Đặt lịch ngay',
        onPressed: _isCreatingBooking
            ? null
            : () {
                // Validate date & time
                final bool missingDate = _selectedDate == null;
                final bool missingTime = _selectedTime == null;

                if (missingDate || missingTime) {
                  setState(() {
                    _dateError = missingDate;
                    _timeError = missingTime;
                  });
                  return;
                }

                if (_selectedVoucher != null) {
                  // Nếu có voucher được chọn, mở modal đặt cọc
                  _showDepositModal();
                } else {
                  // Nếu không có voucher, đặt lịch bình thường
                  _handleBooking();
                }
              },
        buttonType: ButtonType.primary,
        height: 48,
        textStyle: 'head',
        textSize: '16',
        textColor: 'primary',
      ),
    );
  }

  void _showDepositModal() {
    final depositAmount = (widget.quotation.price * 0.03).round(); // 3% deposit

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DepositModal(
        quotationId: widget.quotation.id,
        depositAmount: depositAmount,
        onPaymentSuccess: () async {
          await _createBooking(showLoading: false);
        },
        onPaymentFailed: () {
          AppToastHelper.showError(context, message: 'Thanh toán thất bại hoặc hết hạn. Vui lòng thử lại.');
        },
      ),
    );
  }

  void _handleBooking() {
    // Nếu danh sách voucher có phần tử nhưng người dùng chưa chọn, hỏi xác nhận
    if (_activeVouchers.isNotEmpty && _selectedVoucher == null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            decoration: const BoxDecoration(
              color: DesignTokens.surfacePrimary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Bạn muốn tiếp tục mà không dùng voucher?',
                  textStyle: 'head',
                  textSize: '16',
                  textColor: 'primary',
                ),
                const SizedBox(height: 8),
                MyText(
                  text: 'Bạn đang có voucher khả dụng. Nếu đặt lịch ngay bây giờ, bạn sẽ không được áp dụng ưu đãi.',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'secondary',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: 'Chọn voucher',
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        buttonType: ButtonType.secondary,
                        height: 36,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MyButton(
                        text: 'Vẫn đặt lịch',
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _createBooking();
                        },
                        buttonType: ButtonType.primary,
                        height: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // Không có voucher hoặc đã chọn voucher -> tạo lịch luôn
    _createBooking();
  }

  Future<void> _createBooking({bool showLoading = true}) async {
    if (_selectedDate == null || _selectedTime == null) return;
    if (_isCreatingBooking) return; // chặn gọi trùng
    if (showLoading && mounted) {
      setState(() {
        _isCreatingBooking = true;
      });
    }

    final DateTime bookingTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final int totalAmount = widget.quotation.price;
    final int voucherDiscount = _calculateVoucherDiscount(totalAmount);
    final int depositAmount = _selectedVoucher != null ? (totalAmount * 0.03).round() : 0;
    final int remainPrice = totalAmount - voucherDiscount;

    try {
      final requestBody = {
        'request_service_id': widget.quotation.requestServiceId,
        'quotation_id': widget.quotation.id,
        'time': bookingTime.toIso8601String(),
        'remain_price': remainPrice,
        'voucher_value': voucherDiscount,
        'deposit_value': depositAmount,
      };
      // debugPrint('[CreateBooking] Request body: ' + jsonEncode(requestBody));

      final res = await AuthHttpClient.post(Config.bookingCreateUrl, body: requestBody);
      try {
        // debugPrint('[CreateBooking] Raw response: ' + jsonEncode(res));
      } catch (_) {
        // debugPrint('[CreateBooking] Raw response (non-JSON encodable)');
      }

      if (res['success'] == true) {
        // Điều hướng tới màn chi tiết giao dịch và xóa stack về Home
        Navigate.pushNamedAndRemoveUntil(
          '/transaction-detail',
          '/home',
          arguments: {
            'booking': res['data'],
            'summary': {
              'total': totalAmount,
              'voucher': voucherDiscount,
              'deposit': depositAmount,
              'remain': remainPrice,
            },
          },
        );
      } else {
        // print(res['message']);
      }
    } catch (e) {
      if (mounted) {
        AppToastHelper.showError(context, message: 'Lỗi tạo lịch hẹn: $e');
      }
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _isCreatingBooking = false;
        });
      }
    }
  }

  String _formatPrice(int price) {
    // Làm tròn đến hàng nghìn và rút gọn hiển thị (cho voucher)
    final int rounded = ((price / 1000).round()) * 1000;
    if (rounded >= 1000000) {
      final double millions = rounded / 1000000;
      final bool isInt = (millions % 1) == 0;
      final String value = isInt ? millions.toInt().toString() : millions.toStringAsFixed(1);
      return '$value triệu';
    }
    final int k = rounded ~/ 1000;
    return '${k}k';
  }

  String _formatPriceWithDots(int price) {
    // Format giá tiền với dấu chấm ngăn cách 3 chữ số
    final String priceStr = price.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(priceStr[i]);
    }

    return result.toString();
  }

  int _calculateVoucherDiscount(int totalAmount) {
    if (_selectedVoucher == null) return 0;

    final int type = (_selectedVoucher!['type'] ?? 1) is int
        ? _selectedVoucher!['type'] as int
        : int.tryParse('${_selectedVoucher!['type']}') ?? 1;
    final int discountValue = (_selectedVoucher!['discount_value'] ?? 0) is int
        ? _selectedVoucher!['discount_value'] as int
        : int.tryParse('${_selectedVoucher!['discount_value']}') ?? 0;
    final int minOrder = (_selectedVoucher!['minorder'] ?? 0) is int
        ? _selectedVoucher!['minorder'] as int
        : int.tryParse('${_selectedVoucher!['minorder']}') ?? 0;

    // print('Voucher selected: ${_selectedVoucher}');
    // print('Total amount: $totalAmount, Min order: $minOrder');
    // print('Type: $type, Discount value: $discountValue');

    // Kiểm tra điều kiện đơn hàng tối thiểu
    if (totalAmount < minOrder) {
      // print('Order amount too low for voucher');
      return 0;
    }

    int discount = 0;
    if (type == 2) {
      // Percent discount
      discount = (totalAmount * discountValue / 100).round();
    } else {
      // Money amount discount
      discount = discountValue;
    }

    // print('Calculated discount: $discount');
    return discount;
  }

  Widget _formatVoucherText(Map<String, dynamic> voucher) {
    final int type = (voucher['type'] ?? 1) is int ? voucher['type'] as int : int.tryParse('${voucher['type']}') ?? 1;
    final int discountValue = (voucher['discount_value'] ?? 0) is int
        ? voucher['discount_value'] as int
        : int.tryParse('${voucher['discount_value']}') ?? 0;
    final int minOrder =
        (voucher['minorder'] ?? 0) is int ? voucher['minorder'] as int : int.tryParse('${voucher['minorder']}') ?? 0;

    if (type == 2) {
      // percent
      return Row(
        children: [
          MyText(text: 'Giảm ', textStyle: 'body', textSize: '12', textColor: 'primary'),
          MyText(text: '$discountValue%', textStyle: 'title', textSize: '12', textColor: 'brand'),
          MyText(text: ' cho đơn từ ', textStyle: 'body', textSize: '12', textColor: 'primary'),
          MyText(text: _formatPrice(minOrder), textStyle: 'title', textSize: '12', textColor: 'brand'),
        ],
      );
    }
    // money amount
    return Row(
      children: [
        MyText(text: 'Giảm ', textStyle: 'body', textSize: '12', textColor: 'primary'),
        MyText(text: _formatPrice(discountValue), textStyle: 'title', textSize: '12', textColor: 'brand'),
        MyText(text: ' cho đơn từ ', textStyle: 'body', textSize: '12', textColor: 'primary'),
        MyText(text: _formatPrice(minOrder), textStyle: 'title', textSize: '12', textColor: 'brand'),
      ],
    );
  }
}
