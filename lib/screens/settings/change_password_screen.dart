import 'package:flutter/material.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/debug_helper.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/user/change_password_service.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _submitted = false;
  String? _oldError;
  String? _newError;
  String? _confirmError;

  // ==== Password rules (match PersonalInformationPage) ====
  bool _isPasswordLengthValid(String password) {
    return password.length >= 6 && password.length <= 32;
  }

  bool _hasSpecialChar(String password) {
    final RegExp special = RegExp(r'[^\w\s]');
    return special.hasMatch(password);
  }

  bool _hasDigit(String password) {
    final RegExp digit = RegExp(r'\d');
    return digit.hasMatch(password);
  }

  bool _isPasswordStrong(String password) {
    return _isPasswordLengthValid(password) && _hasSpecialChar(password) && _hasDigit(password);
  }

  bool _isConfirmMatched() {
    return _confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text == _newPasswordController.text;
  }

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
              height: 16,
            ),
            const SizedBox(width: 8),
            MyText(text: text, textStyle: 'body', textSize: '14', textColor: 'secondary'),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(c1, 'Độ dài 6 - 32 kí tự'),
        const SizedBox(height: 4),
        line(c2, 'Bao gồm kí tự đặc biệt'),
        const SizedBox(height: 4),
        line(c3, 'Bao gồm chữ số'),
      ],
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validation theo cùng tiêu chí như PersonalInformationPage
    setState(() {
      _submitted = true;
      _oldError = (_oldPasswordController.text.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null;

      final String newPw = _newPasswordController.text;
      if (newPw.isEmpty) {
        _newError = 'Vui lòng nhập mật khẩu';
      } else if (!_isPasswordLengthValid(newPw)) {
        _newError = 'Mật khẩu phải dài 6-32 ký tự';
      } else if (!_hasSpecialChar(newPw)) {
        _newError = 'Mật khẩu phải bao gồm ký tự đặc biệt';
      } else if (!_hasDigit(newPw)) {
        _newError = 'Mật khẩu phải bao gồm chữ số';
      } else {
        _newError = null;
      }

      final String confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) {
        _confirmError = 'Vui lòng nhập lại mật khẩu';
      } else if (confirm != newPw) {
        _confirmError = 'Mật khẩu không khớp';
      } else {
        _confirmError = null;
      }
    });
    if (_oldError != null || _newError != null || _confirmError != null) return;
    setState(() => _submitting = true);
    try {
      final result = await ChangePasswordService.changePassword(
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      if (result.success) {
        if (mounted) {
          AppToastHelper.showSuccess(context, message: result.message ?? 'Đổi mật khẩu thành công');
          Navigate.pop();
        }
      } else {
        if (mounted) {
          AppToastHelper.showError(context, message: result.message ?? 'Đổi mật khẩu thất bại');
        }
      }
    } catch (e) {
      if (mounted) AppToastHelper.showError(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyHeader(
              height: 56,
              title: 'Đổi mật khẩu',
              showLeftButton: true,
              onLeftPressed: () => Navigate.pop(),
            ),
            Expanded(
              child: KeyboardDismissWrapper(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: 'assets/icons_final/lock.svg'),
                      const SizedBox(height: 12),
                      MyText(text: 'Đổi mật khẩu', textStyle: 'head', textSize: '24', textColor: 'primary'),
                      const SizedBox(height: 4),
                      MyText(
                        text: 'Hãy đặt mật khẩu mới an toàn.',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),
                      const SizedBox(height: 32),

                      // Mật khẩu hiện tại
                      MyTextField(
                        label: 'Mật khẩu hiện tại',
                        controller: _oldPasswordController,
                        obscureText: !_showOld,
                        hasError: _submitted && _oldError != null,
                        errorText: _oldError,
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showOld = !_showOld),
                          child: SvgIcon(
                            svgPath: _showOld ? 'assets/icons_final/eye-slash.svg' : 'assets/icons_final/eye.svg',
                            size: 20,
                            color: DesignTokens.textBrand,
                          ),
                        ),
                        onChange: (value) {
                          setState(() {
                            if (_submitted && _oldError != null) {
                              _oldError = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu mới
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
                                child: SvgIcon(
                                  svgPath: 'assets/icons_final/Check-blue.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              )
                            : GestureDetector(
                                onTap: () => setState(() => _showNew = !_showNew),
                                child: SvgIcon(
                                  svgPath: _showNew ? 'assets/icons_final/eye-slash.svg' : 'assets/icons_final/eye.svg',
                                  size: 20,
                                  color: DesignTokens.textBrand,
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

                      // Xác nhận mật khẩu mới
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
                                child: SvgIcon(
                                  svgPath: 'assets/icons_final/Check-blue.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              )
                            : GestureDetector(
                                onTap: () => setState(() => _showConfirm = !_showConfirm),
                                child: SvgIcon(
                                  svgPath:
                                      _showConfirm ? 'assets/icons_final/eye-slash.svg' : 'assets/icons_final/eye.svg',
                                  size: 20,
                                  color: DesignTokens.textBrand,
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
                        text: _submitting ? 'Đang xử lý...' : 'Lưu thay đổi',
                        buttonType: ButtonType.primary,
                        onPressed: _submitting ? null : _handleSubmit,
                        height: 48,
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
