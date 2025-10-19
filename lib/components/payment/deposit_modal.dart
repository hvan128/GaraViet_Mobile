import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/svg_icon.dart';
// import 'package:gara/widgets/app_dialog.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/models/payment/payment_model.dart';
import 'package:gara/services/payment/payment_service.dart';
import 'package:gal/gal.dart';
import 'dart:typed_data';

class DepositModal extends StatefulWidget {
  final int quotationId;
  final int depositAmount;
  final int? voucherDiscount; // để hiển thị cảnh báo hủy voucher
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentFailed;

  const DepositModal({
    super.key,
    required this.quotationId,
    required this.depositAmount,
    this.voucherDiscount,
    this.onPaymentSuccess,
    this.onPaymentFailed,
  });

  @override
  State<DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<DepositModal> {
  PaymentModel? _paymentData;
  bool _isLoading = true;
  bool _isPolling = false;
  bool _isSavingQr = false;
  bool _qrSaved = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  Uint8List? _qrBytes; // cache QR bytes để tránh nháy khi rebuild
  String? _inlineMessage; // thông báo hiển thị trực tiếp trong modal
  Color _inlineMessageColor = Colors.blue;
  bool _hasNotifiedSuccess = false; // đảm bảo chỉ callback thành công một lần

  @override
  void initState() {
    super.initState();
    _createQrPayment();
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

  void _showCancelConfirm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: DesignTokens.surfacePrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MyText(
                    text: 'Lưu ý : ',
                    textStyle: 'head',
                    textSize: '16',
                    textColor: 'primary',
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        MyText(
                          text: 'Voucher giảm ',
                          textStyle: 'head',
                          textSize: '16',
                          textColor: 'primary',
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: MyText(
                            text: _formatPriceShort(widget.voucherDiscount ?? 0),
                            textStyle: 'head',
                            textSize: '16',
                            textColor: 'brand',
                          ),
                        ),
                        MyText(
                          text: ' sẽ bị hủy bỏ',
                          textStyle: 'head',
                          textSize: '16',
                          textColor: 'primary',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      text: 'Hủy đặt lịch',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      buttonType: ButtonType.secondary,
                      color: DesignTokens.alertError,
                      borderColor: DesignTokens.borderSecondary,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      text: 'Vẫn đặt lịch',
                      onPressed: () => Navigator.of(ctx).pop(),
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
  }

  String _formatPriceShort(int price) {
    if (price >= 1000000) {
      final d = (price / 1000000);
      final s = (d % 1 == 0) ? d.toInt().toString() : d.toStringAsFixed(1);
      return '${s}tr';
    }
    return '${(price / 1000).round()}k';
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _createQrPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PaymentService.createQrPayment(
        quotationId: widget.quotationId,
        deposit: widget.depositAmount,
        expiresMinutes: 30,
      );

      if (result['success'] && result['data'] != null) {
        final data = result['data'] as PaymentModel;
        DebugLogger.largeJson('[CreateQrPayment] PaymentModel', data.toJson()['transaction_id']);
        // Cache QR bytes một lần duy nhất
        final raw = data.qrCode.split(',').last;
        _qrBytes = Uint8List.fromList(base64Decode(raw));
        setState(() {
          _paymentData = data;
          _isLoading = false;
        });
        _startPolling();
      } else {
        print(result['message']);
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = 'Lỗi khi tạo mã QR: $e';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    if (_paymentData == null) return;

    setState(() {
      _isPolling = true;
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Kiểm tra mounted trước khi setState
      if (!mounted) {
        timer.cancel();
        return;
      }

      final result = await PaymentService.pollPaymentStatus(
        transactionId: _paymentData!.transactionId,
        timeout: 30,
        pollInterval: 2,
      );

      // Kiểm tra mounted sau khi async call
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (result['success'] && result['data'] != null) {
        final updatedPayment = result['data'] as PaymentModel;
        
        if (updatedPayment.isCompleted) {
          timer.cancel();
          setState(() {
            _isPolling = false;
          });
          _handleSuccessAndClose();
        } else if (updatedPayment.isExpired) {
          timer.cancel();
          setState(() {
            _isPolling = false;
          });
          final onFail = widget.onPaymentFailed;
          if (mounted) {
            Future.microtask(() {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              onFail?.call();

            });
          }
        }
      }
    });
  }

  Future<void> _saveQrToDevice() async {
    if (_paymentData == null) return;

    setState(() {
      _isSavingQr = true;
    });

    try {
      // Lưu trực tiếp từ cache QR bytes (nếu có) để tránh decode lại)
      _qrBytes ??= Uint8List.fromList(
        base64Decode(_paymentData!.qrCode.split(',').last),
      );

      // Kiểm tra quyền truy cập thư viện ảnh
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            setState(() {
              _isSavingQr = false;
            });
            AppToastHelper.showWarning(
              context,
              message: 'Cần quyền truy cập thư viện ảnh để lưu QR code',
            );
          }
          return;
        }
      }

      // Lưu vào thư viện ảnh của máy
      await Gal.putImageBytes(
        _qrBytes!,
        name: 'QR_Code_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Kiểm tra mounted trước khi cập nhật UI
      if (mounted) {
        setState(() {
          _isSavingQr = false;
          _qrSaved = true; // giữ trạng thái đã lưu cho tới khi đóng modal
        });
      }
    } catch (e) {
      // Kiểm tra mounted trước khi hiển thị lỗi
      if (mounted) {
        setState(() {
          _isSavingQr = false;
        });
        AppToastHelper.showError(
          context,
          message: 'Lỗi khi lưu QR code: $e',
        );
      }
    }
  }

  Future<void> _checkStatusAndClose() async {
    if (_paymentData == null) return;
    try {
      final res = await PaymentService.checkPaymentStatus(
        transactionId: _paymentData!.transactionId,
      );
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
    // Cộng thêm chiều cao khi có thông báo inline để tránh thay đổi kích thước đột ngột
    final double baseHeight = 448;
    final double extraMsgHeight = _inlineMessage != null ? 56 : 0; // ~56px cho banner inline
    return Container(
      height: baseHeight + extraMsgHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          // Title
          MyText(
            text: 'Đặt cọc',
            textStyle: 'title',
            textSize: '16',
            textColor: 'primary',
          ),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // QR Code Section
                  if (_isLoading) ...[
                    // Skeleton loading cho QR code
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    // Error state cho QR code
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
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          MyText(
                            text: _errorMessage ?? 'Lỗi tải QR',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'error',
                          ),
                        ],
                      ),
                    ),
                  ] else if (_paymentData != null) ...[
                    // QR Code thực tế
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: Image.memory(
                        _qrBytes ?? Uint8List.fromList(base64Decode(_paymentData!.qrCode.split(',').last)),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),

                  // Inline message (errors/info)
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
                  
                  // Save QR button
                  GestureDetector(
                    onTap: (_isSavingQr || _qrSaved || _isLoading || _errorMessage != null) ? null : _saveQrToDevice,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSavingQr) ...[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.textBrand),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MyText(
                            text: 'Đang lưu...',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'brand',
                          ),
                        ] else if (_qrSaved) ...[
                          SvgIcon(
                            svgPath: 'assets/icons_final/Check.svg',
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          MyText(
                            text: 'Đã lưu',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'success',
                          ),
                        ] else ...[
                          SvgIcon(
                            svgPath: 'assets/icons_final/gallery-import.svg',
                            size: 20,
                            color: DesignTokens.textBrand,
                          ),
                          const SizedBox(width: 8),
                          MyText(
                            text: 'Lưu QR về máy',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'brand',
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Amount
                  Column(
                    children: [
                      MyText(
                        text: 'Số tiền',
                        textStyle: 'body',
                        textSize: '12',
                        textColor: 'tertiary',
                      ),
                      MyText(
                        text: _paymentData != null 
                            ? '${_formatPriceWithDots(_paymentData!.amount)}đ'
                            : '${_formatPriceWithDots(widget.depositAmount)}đ',
                        textStyle: 'head',
                        textSize: '24',
                        textColor: 'primary',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Note
                  MyText(
                    text: 'Lưu ý: Bạn có thể thay đổi lịch hẹn sau khi đặt cọc.',
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'secondary',
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Hủy đặt cọc',
                          onPressed: _showCancelConfirm,
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

  String _formatPriceWithDots(int price) {
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

}
