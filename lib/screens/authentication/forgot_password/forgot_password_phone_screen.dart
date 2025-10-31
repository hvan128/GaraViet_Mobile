import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/auth/forgot_password_service.dart';
import 'package:gara/navigation/navigation.dart';

class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() => _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _submitted = true;
      _phoneError = null;
    });
    final String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Vui lòng nhập số điện thoại');
      return;
    }
    final RegExp vnPhone = RegExp(r'^(?:\+?84|0)\d{9,10}$');
    if (!vnPhone.hasMatch(phone)) {
      setState(() => _phoneError = 'Số điện thoại không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await ForgotPasswordService.sendOtp(phone: phone);
      if (!mounted) return;
      if (resp['success'] == true) {
        AppToastHelper.showSuccess(context, message: resp['message'] ?? 'OTP đã được gửi');
        Navigate.pushNamed('/forgot-password/otp', arguments: {'phone': phone});
      } else {
        AppToastHelper.showError(context, message: resp['message'] ?? 'Gửi OTP thất bại');
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
            MyHeader(title: 'Quên mật khẩu', onLeftPressed: () => Navigate.pop()),
            Expanded(
              child: KeyboardDismissWrapper(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: 'assets/icons_final/lock.svg'),
                      const SizedBox(height: 12),
                      MyText(text: 'Khôi phục mật khẩu', textStyle: 'head', textSize: '24', textColor: 'primary'),
                      const SizedBox(height: 4),
                      MyText(
                        text: 'Nhập số điện thoại để nhận mã OTP đặt lại mật khẩu.',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),
                      const SizedBox(height: 32),
                      MyTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        keyboardType: TextInputType.phone,
                        obscureText: false,
                        hasError: _submitted && _phoneError != null,
                        errorText: _phoneError,
                        hintText: 'Nhập số điện thoại',
                        onChange: (v) {
                          if (_submitted) {
                            final String value = v.trim();
                            final RegExp vnPhone = RegExp(r'^(?:\+?84|0)\d{9,10}$');
                            setState(() {
                              if (value.isEmpty) {
                                _phoneError = 'Vui lòng nhập số điện thoại';
                              } else if (!vnPhone.hasMatch(value)) {
                                _phoneError = 'Số điện thoại không hợp lệ';
                              } else {
                                _phoneError = null;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      MyButton(
                        text: _isLoading ? 'Đang gửi...' : 'Xác nhận',
                        onPressed: _isLoading ? null : _handleSendOtp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
