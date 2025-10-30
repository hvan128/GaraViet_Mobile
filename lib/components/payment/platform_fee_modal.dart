import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gara/models/payment/payment_model.dart';
import 'package:gara/services/payment/payment_service.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gal/gal.dart';

class PlatformFeeModal extends StatefulWidget {
  final int month;
  final int year;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentFailed;

  const PlatformFeeModal({
    super.key,
    required this.month,
    required this.year,
    this.onPaymentSuccess,
    this.onPaymentFailed,
  });

  @override
  State<PlatformFeeModal> createState() => _PlatformFeeModalState();
}

class _PlatformFeeModalState extends State<PlatformFeeModal> {
  PaymentModel? _paymentData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;
  Uint8List? _qrBytes;
  bool _isSavingQr = false;
  bool _qrSaved = false;
  String? _inlineMessage;
  Color _inlineMessageColor = Colors.blue;
  bool _hasNotifiedSuccess = false;

  @override
  void initState() {
    super.initState();
    _createQr();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _createQr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await PaymentService.createPlatformFeeQr(month: widget.month, year: widget.year);
      if (res['success'] && res['data'] != null) {
        final data = res['data'] as PaymentModel;
        _qrBytes = Uint8List.fromList(base64Decode(data.qrCode.split(',').last));
        setState(() {
          _paymentData = data;
          _isLoading = false;
        });
        _startPolling();
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Không tạo được QR';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tạo QR: $e';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    if (_paymentData == null) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final res = await PaymentService.pollPlatformFeePayment(
        transactionId: _paymentData!.transactionId,
        timeout: 30,
        pollInterval: 2,
      );
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (res['success'] && res['data'] != null) {
        final data = res['data'] as PaymentModel;
        if (data.isCompleted) {
          timer.cancel();
          _handleSuccessAndClose();
        } else if (data.isExpired) {
          timer.cancel();
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          widget.onPaymentFailed?.call();
        }
      }
    });
  }

  void _handleSuccessAndClose() {
    if (_hasNotifiedSuccess) return;
    _hasNotifiedSuccess = true;
    _pollingTimer?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Future.microtask(() => widget.onPaymentSuccess?.call());
  }

  Future<void> _saveQrToDevice() async {
    if (_paymentData == null || _qrBytes == null) return;
    setState(() {
      _isSavingQr = true;
    });
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) setState(() => _isSavingQr = false);
          return;
        }
      }
      await Gal.putImageBytes(_qrBytes!, name: 'QR_PlatformFee_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        setState(() {
          _isSavingQr = false;
          _qrSaved = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSavingQr = false);
    }
  }

  Future<void> _checkStatusAndClose() async {
    if (_paymentData == null) return;
    try {
      final res = await PaymentService.checkPaymentStatus(transactionId: _paymentData!.transactionId);
      if (!mounted) return;
      if (res['success'] && res['data'] != null) {
        final payment = res['data'] as PaymentModel;
        if (payment.isCompleted) {
          _handleSuccessAndClose();
          return;
        }
        setState(() {
          _inlineMessage = 'Chưa nhận được thanh toán. Vui lòng thử lại sau.';
          _inlineMessageColor = Colors.orange;
        });
      } else {
        setState(() {
          _inlineMessage = res['message'] ?? 'Kiểm tra thất bại';
          _inlineMessageColor = Colors.red;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineMessage = 'Lỗi: $e';
        _inlineMessageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double baseHeight = 448;
    final double extraMsgHeight = _inlineMessage != null ? 56 : 0;
    return Container(
      height: baseHeight + extraMsgHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MyText(text: 'Thanh toán phí nền tảng', textStyle: 'title', textSize: '16', textColor: 'primary'),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_isLoading) ...[
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ] else if (_errorMessage != null) ...[
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 8),
                          MyText(text: _errorMessage!, textStyle: 'body', textSize: '14', textColor: 'error'),
                          const SizedBox(height: 8),
                          MyButton(text: 'Thử lại', onPressed: _createQr, buttonType: ButtonType.primary, height: 36),
                        ],
                      ),
                    ),
                  ] else if (_paymentData != null) ...[
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: Image.memory(_qrBytes!, fit: BoxFit.contain, gaplessPlayback: true),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_inlineMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _inlineMessageColor.withOpacity(0.08),
                        border: Border.all(color: _inlineMessageColor.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: _inlineMessageColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MyText(
                              text: _inlineMessage!,
                              textStyle: 'body',
                              textSize: '12',
                              textColor: 'secondary',
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _inlineMessage = null),
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: (_isSavingQr || _qrSaved || _isLoading || _errorMessage != null) ? null : _saveQrToDevice,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSavingQr) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          const MyText(text: 'Đang lưu...', textStyle: 'body', textSize: '14', textColor: 'brand'),
                        ] else if (_qrSaved) ...[
                          SvgIcon(svgPath: 'assets/icons_final/Check.svg', size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          const MyText(text: 'Đã lưu', textStyle: 'body', textSize: '14', textColor: 'success'),
                        ] else ...[
                          SvgIcon(
                              svgPath: 'assets/icons_final/gallery-import.svg',
                              size: 20,
                              color: DesignTokens.textBrand),
                          const SizedBox(width: 8),
                          const MyText(text: 'Lưu QR về máy', textStyle: 'body', textSize: '14', textColor: 'brand'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      const MyText(text: 'Số tiền', textStyle: 'body', textSize: '12', textColor: 'tertiary'),
                      MyText(
                        text: '${_formatDots(_paymentData?.amount ?? 0)}đ',
                        textStyle: 'head',
                        textSize: '24',
                        textColor: 'primary',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const MyText(
                    text: 'Lưu ý: Vui lòng hoàn tất trong thời gian hiệu lực mã QR.',
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'secondary',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Đóng',
                          onPressed: () => Navigator.of(context).pop(),
                          buttonType: ButtonType.secondary,
                          height: 36,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyButton(
                          text: 'Đã chuyển khoản',
                          onPressed: _paymentData != null ? _checkStatusAndClose : null,
                          buttonType: ButtonType.primary,
                          height: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDots(int price) {
    final s = price.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}
