import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/services/auth/forgot_password_service.dart';
import 'package:gara/navigation/navigation.dart';

class ForgotPasswordNewPasswordScreen extends StatefulWidget {
  final String resetToken;
  const ForgotPasswordNewPasswordScreen({super.key, required this.resetToken});

  @override
  State<ForgotPasswordNewPasswordScreen> createState() => _ForgotPasswordNewPasswordScreenState();
}

class _ForgotPasswordNewPasswordScreenState extends State<ForgotPasswordNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _submitted = false;
  bool _isLoading = false;
  String? _newError;
  String? _confirmError;

  bool _isPasswordLengthValid(String password) => password.length >= 6 && password.length <= 32;
  bool _hasSpecialChar(String password) => RegExp(r'[^\w\s]').hasMatch(password);
  bool _hasDigit(String password) => RegExp(r'\d').hasMatch(password);
  bool _isPasswordStrong(String password) =>
      _isPasswordLengthValid(password) && _hasSpecialChar(password) && _hasDigit(password);
  bool _isConfirmMatched() =>
      _confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text == _newPasswordController.text;

  Widget _buildPasswordStrengthHelperText() {
    final String pw = _newPasswordController.text;
    final bool c1 = _isPasswordLengthValid(pw);
    final bool c2 = _hasSpecialChar(pw);
    final bool c3 = _hasDigit(pw);
    Widget line(bool ok, String text) => Row(
          children: [
            SvgIcon(
                svgPath: ok ? 'assets/icons_final/check_outline.svg' : 'assets/icons_final/close.svg',
                width: 16,
                height: 16),
            const SizedBox(width: 8),
            MyText(text: text, textStyle: 'body', textSize: '14', textColor: 'secondary'),
          ],
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line(c1, 'Độ dài 6 - 32 kí tự'),
      const SizedBox(height: 4),
      line(c2, 'Bao gồm kí tự đặc biệt'),
      const SizedBox(height: 4),
      line(c3, 'Bao gồm chữ số'),
    ]);
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _submitted = true;
      final pw = _newPasswordController.text;
      if (pw.isEmpty) {
        _newError = 'Vui lòng nhập mật khẩu';
      } else if (!_isPasswordLengthValid(pw)) {
        _newError = 'Mật khẩu phải dài 6-32 ký tự';
      } else if (!_hasSpecialChar(pw)) {
        _newError = 'Mật khẩu phải bao gồm ký tự đặc biệt';
      } else if (!_hasDigit(pw)) {
        _newError = 'Mật khẩu phải bao gồm chữ số';
      } else {
        _newError = null;
      }

      final confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) {
        _confirmError = 'Vui lòng nhập lại mật khẩu';
      } else if (confirm != pw) {
        _confirmError = 'Mật khẩu không khớp';
      } else {
        _confirmError = null;
      }
    });
    if (_newError != null || _confirmError != null) return;

    setState(() => _isLoading = true);
    try {
      final resp = await ForgotPasswordService.resetPassword(
        resetToken: widget.resetToken,
        newPassword: _newPasswordController.text.trim(),
      );
      if (!mounted) return;
      if (resp['success'] == true) {
        AppToastHelper.showSuccess(context, message: resp['message'] ?? 'Đặt lại mật khẩu thành công');
        Navigate.pushNamedAndRemoveAll('/login');
      } else {
        AppToastHelper.showError(context, message: resp['message'] ?? 'Đặt lại mật khẩu thất bại');
      }
    } catch (e) {
      if (mounted) AppToastHelper.showError(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyHeader(title: 'Đặt mật khẩu mới', onLeftPressed: () => Navigate.pop()),
            Expanded(
              child: KeyboardDismissWrapper(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: 'assets/icons_final/lock.svg'),
                      const SizedBox(height: 12),
                      MyText(text: 'Tạo mật khẩu mới', textStyle: 'head', textSize: '24', textColor: 'primary'),
                      const SizedBox(height: 4),
                      MyText(
                        text: 'Hãy đặt mật khẩu mạnh để bảo vệ tài khoản của bạn.',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),
                      const SizedBox(height: 32),
                      MyTextField(
                        label: 'Mật khẩu mới',
                        controller: _newPasswordController,
                        obscureText: !_showNew,
                        hasError: _submitted && _newError != null,
                        errorText: _newError,
                        suffixIcon: _isPasswordStrong(_newPasswordController.text)
                            ? Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                child: SvgIcon(svgPath: 'assets/icons_final/Check-blue.svg', width: 24, height: 24),
                              )
                            : GestureDetector(
                                onTap: () => setState(() => _showNew = !_showNew),
                                child: SvgIcon(
                                  svgPath: _showNew ? 'assets/icons_final/eye-slash.svg' : 'assets/icons_final/eye.svg',
                                  size: 20,
                                ),
                              ),
                        onChange: (value) {
                          final String pw = value;
                          String? err;
                          if (pw.isEmpty) {
                            err = 'Vui lòng nhập mật khẩu';
                          } else if (!_isPasswordLengthValid(pw)) {
                            err = 'Mật khẩu phải dài 6-32 ký tự';
                          } else if (!_hasSpecialChar(pw)) {
                            err = 'Mật khẩu phải bao gồm ký tự đặc biệt';
                          } else if (!_hasDigit(pw)) {
                            err = 'Mật khẩu phải bao gồm chữ số';
                          }
                          setState(() {
                            if (_submitted) {
                              _newError = err;
                              if (_confirmPasswordController.text.isNotEmpty) {
                                _confirmError = (_confirmPasswordController.text == pw) ? null : 'Mật khẩu không khớp';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_newPasswordController.text.isNotEmpty) _buildPasswordStrengthHelperText(),
                      const SizedBox(height: 16),
                      MyTextField(
                        label: 'Xác nhận mật khẩu mới',
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirm,
                        hasError: _submitted && _confirmError != null,
                        errorText: _confirmError,
                        suffixIcon: _isConfirmMatched()
                            ? Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                child: SvgIcon(svgPath: 'assets/icons_final/Check-blue.svg', width: 24, height: 24),
                              )
                            : GestureDetector(
                                onTap: () => setState(() => _showConfirm = !_showConfirm),
                                child: SvgIcon(
                                  svgPath:
                                      _showConfirm ? 'assets/icons_final/eye-slash.svg' : 'assets/icons_final/eye.svg',
                                  size: 20,
                                ),
                              ),
                        onChange: (value) {
                          setState(() {
                            if (_submitted) {
                              if (value.isEmpty) {
                                _confirmError = 'Vui lòng nhập lại mật khẩu';
                              } else if (value != _newPasswordController.text) {
                                _confirmError = 'Mật khẩu không khớp';
                              } else {
                                _confirmError = null;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      MyButton(
                          text: _isLoading ? 'Đang lưu...' : 'Lưu mật khẩu',
                          onPressed: _isLoading ? null : _handleSubmit),
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
