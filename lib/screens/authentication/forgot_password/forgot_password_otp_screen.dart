import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:flutter/services.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/auth/forgot_password_service.dart';
import 'package:gara/navigation/navigation.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String phone;
  const ForgotPasswordOtpScreen({super.key, required this.phone});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Tự động gửi khi đã nhập đủ 4 số, giống màn gốc
        _verify();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length != 4) {
      AppToastHelper.showError(context, message: 'Vui lòng nhập đủ 4 số OTP');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final resp = await ForgotPasswordService.verifyOtp(phone: widget.phone, otp: otp);
      if (!mounted) return;
      if (resp['success'] == true && resp['reset_token'] != null) {
        Navigate.pushNamed('/forgot-password/new-password', arguments: {
          'reset_token': resp['reset_token'],
        });
      } else {
        AppToastHelper.showError(context, message: resp['message'] ?? 'OTP không đúng');
      }
    } catch (e) {
      if (mounted) AppToastHelper.showError(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyHeader(title: 'Xác thực OTP', onLeftPressed: () => Navigate.pop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconField(svgPath: 'assets/icons_final/send.svg'),
                    const SizedBox(height: 12),
                    MyText(text: 'Nhập mã xác thực', textStyle: 'head', textSize: '24', textColor: 'primary'),
                    const SizedBox(height: 4),
                    MyText(
                      text: 'Chúng tôi đã gửi mã OTP đến số ${widget.phone}.',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: DesignTokens.borderPrimary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                            onChanged: (v) => _onChanged(v, index),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    MyButton(
                        text: _isLoading ? 'Đang xác thực...' : 'Xác thực', onPressed: _isLoading ? null : _verify),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
