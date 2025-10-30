import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/services/api/auth_http_client.dart';
import 'package:gara/config.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/widgets/app_toast.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Object? arguments;

  const TransactionDetailScreen({super.key, this.arguments});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Map<String, dynamic>? _bookingDetail;
  bool _isLoading = true;
  String? _error;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchBookingDetail();
  }

  Future<void> _fetchBookingDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final args = widget.arguments;
      int? bookingId;
      if (args is Map<String, dynamic>) {
        final b = args['booking'];
        if (b is Map<String, dynamic>) {
          final idInBooking = b['id'];
          if (idInBooking is int) {
            bookingId = idInBooking;
          } else {
            bookingId = int.tryParse('$idInBooking');
          }
        }
        bookingId ??= args['booking_id'] is int ? args['booking_id'] as int : int.tryParse('${args['booking_id']}');
      }

      if (bookingId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Thiếu booking_id để tải chi tiết.';
        });
        return;
      }

      // debugPrint(
      //   '[BookingDetail] Request: GET ' +
      //       Config.bookingDetailUrl +
      //       ' booking_id=' +
      //       bookingId.toString(),
      // );
      Map<String, dynamic> res = {};
      const int maxAttempts = 6; // thử tối đa 6 lần với backoff
      int delayMs = 300; // backoff bắt đầu 300ms
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        res = await AuthHttpClient.get(Config.bookingDetailUrl, queryParams: {'booking_id': bookingId.toString()});

        // DebugLogger.largeJson(
        //   '[BookingDetail] Attempt ' +
        //       attempt.toString() +
        //       '/' +
        //       maxAttempts.toString() +
        //       ' Raw response',
        //   res,
        // );

        // Nếu thành công hoặc không phải 404 thì dừng retry
        if (res['success'] == true || (res['statusCode'] as int? ?? 0) != 404) {
          break;
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * 2).clamp(300, 2400); // exponential backoff, trần 2.4s
      }

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _bookingDetail = res['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = res['message'] ?? 'Không tải được chi tiết lịch hẹn';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Lỗi: $e';
      });
    }
  }

  // sử dụng DebugLogger.largeJson thay cho hàm local

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> summary = _extractMap(widget.arguments, 'summary');

    final int total = _toInt(summary['total']);
    final int voucher = _toInt(summary['voucher']);
    final int deposit = _toInt(summary['deposit']);
    final int remain = _toInt(summary['remain']);

    final booking = _bookingDetail ?? _extractMap(widget.arguments, 'booking');

    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            MyHeader(
              title: 'Chi tiết giao dịch',
              onLeftPressed: () {
                Navigate.pushNamedAndRemoveAll('/home', arguments: {'selectedTab': 2});
              },
            ),

            if (_isLoading) ...[
              Expanded(child: Center(child: SizedBox(width: 36, height: 36, child: const CircularProgressIndicator()))),
            ] else if (_error != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MyText(
                  text: _error!,
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'error',
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      color: DesignTokens.surfacePrimary,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Success Icon and Title
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: DesignTokens.surfaceSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: DesignTokens.borderSecondary),
                            ),
                            child: Center(child: SvgIcon(svgPath: 'assets/icons_final/check_green.svg', size: 54)),
                          ),
                          const SizedBox(height: 8),
                          MyText(text: 'Đặt lịch thành công', textStyle: 'head', textSize: '18', textColor: 'primary'),
                          const SizedBox(height: 4),
                          MyText(
                            text: 'Đã thành công đặt lịch cho xe của bạn.',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'tertiary',
                          ),

                          const SizedBox(height: 16),
                          // Card Detail
                          _buildDetailCard(booking, total, voucher, deposit, remain),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              color: DesignTokens.surfacePrimary,
              child: Row(
                children: [
                  Expanded(
                    child: MyButton(
                      text: 'Tải biên lai',
                      onPressed: () => _screenshotAndSave(),
                      startIcon: 'assets/icons_final/document-download.svg',
                      sizeStartIcon: const Size(24, 24),
                      buttonType: ButtonType.secondary,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      text: 'Xem đơn',
                      onPressed: () {
                        Navigate.pushNamedAndRemoveAll('/home', arguments: {'selectedTab': 2});
                      },
                      buttonType: ButtonType.primary,
                      endIcon: 'assets/icons_final/arrow-right.svg',
                      sizeEndIcon: const Size(24, 24),
                      colorEndIcon: DesignTokens.surfacePrimary,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> booking, int total, int voucher, int deposit, int remain) {
    final request = _extractMap(booking, 'request_service');
    final quotation = _extractMap(booking, 'quotation');
    final payment = _extractMap(booking, 'payment_transaction');
    final garage = _extractMap(quotation, 'infor_garage');

    final serviceName = request['description'] ?? booking['service_name'] ?? '—';
    final garageName = garage['name_garage'] ?? '';
    final idText = payment['transaction_id'] ?? '';
    final bookingTime = booking['time'] ?? quotation['time'];

    // Nếu API có cung cấp tổng/voucher/deposit/remain trong quotation, ưu tiên dùng
    final int apiTotal = _toInt(quotation['price']);
    final int apiVoucher = _toInt(quotation['voucher_value']);
    final int apiDeposit = _toInt(quotation['deposit_value']);
    final int apiRemain = _toInt(quotation['remain_price']);

    final int finalTotal = apiTotal > 0 ? apiTotal : total;
    final int finalVoucher = apiVoucher > 0 ? apiVoucher : voucher;
    final int finalDeposit = apiDeposit > 0 ? apiDeposit : deposit;
    final int finalRemain = apiRemain > 0 ? apiRemain : remain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Garage', garageName.toString()),
          ..._divider(),
          _row('Ngày', _formatTime(bookingTime)),
          ..._divider(),
          _row('Dịch vụ', serviceName.toString()),
          ..._divider(),
          MyText(text: 'Chi tiết giao dịch', textStyle: 'title', textSize: '14', textColor: 'primary'),
          const SizedBox(height: 12),
          if (idText != '') ...[
            _row('ID giao dịch', idText),
            ..._divider(),
            _row('Ngày giao dịch', _formatDateTimeNow()),
            ..._divider(),
          ],
          _row('Trị giá đơn hàng', '${_dot(finalTotal)} đ'),
          ..._divider(),
          _row('Voucher áp dụng', '- ${_dot(finalVoucher)} đ'),
          ..._divider(),
          _row('Đã cọc', '- ${_dot(finalDeposit)} đ'),
          ..._divider(),
          _row('Còn phải thanh toán', '${_dot(finalRemain)} đ', isEmphasis: true),
        ],
      ),
    );
  }

  List<Widget> _divider() {
    return [
      const SizedBox(height: 12),
      const Divider(height: 1, color: DesignTokens.borderTertiary),
      const SizedBox(height: 12),
    ];
  }

  Widget _row(String label, String value, {bool isEmphasis = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MyText(text: label, textStyle: 'body', textSize: '14', textColor: isEmphasis ? 'primary' : 'tertiary'),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: MyText(
              text: value,
              textStyle: isEmphasis ? 'head' : 'label',
              textSize: isEmphasis ? '18' : '14',
              textColor: isEmphasis ? 'brand' : 'primary',
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _extractMap(Object? args, String key) {
    if (args is Map<String, dynamic>) {
      final v = args[key];
      if (v is Map<String, dynamic>) return v;
    }
    return {};
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  String _formatTime(dynamic iso) {
    try {
      final s = iso?.toString();
      if (s == null || s.isEmpty) return '—';
      final dt = DateTime.parse(s);
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final yy = dt.year.toString();
      return '$hh:$mm $dd/$mo/$yy';
    } catch (_) {
      return '—';
    }
  }

  String _formatDateTimeNow() {
    final dt = DateTime.now();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$hh:$mm $dd/$mo/$yy';
  }

  String _dot(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Hàm chụp và lưu ảnh từ một widget có GlobalKey
  Future<void> _screenshotAndSave({bool saveToGallery = true}) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1️⃣ Lấy RenderRepaintBoundary từ key
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 2️⃣ Chụp ảnh widget
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // 3️⃣ Chuyển sang byte
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 4️⃣ Lưu file tạm trong thư mục app
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/bien_lai_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // 5️⃣ (Tuỳ chọn) Lưu vào thư viện ảnh
      if (saveToGallery) {
        await Gal.putImage(file.path);
        if (mounted) {
          Navigator.of(context).pop(); // Đóng loading dialog
          AppToastHelper.showSuccess(context, message: 'Biên lai đã được lưu vào thư viện ảnh');
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Đóng loading dialog
          AppToastHelper.showSuccess(context, message: 'Biên lai đã được lưu tại: $filePath');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Đóng loading dialog
        AppToastHelper.showError(context, message: 'Lỗi khi chụp và lưu biên lai: $e');
      }
    }
  }
}
