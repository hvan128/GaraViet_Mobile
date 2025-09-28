import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/progress_bar.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/header.dart';
import 'package:provider/provider.dart';

class GarageAccountPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;

  const GarageAccountPage({
    super.key,
    required this.onNext,
    this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<GarageAccountPage> createState() => _GarageAccountPageState();
}

class _GarageAccountPageState extends State<GarageAccountPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;

  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _isFormNotEmpty() {
    return _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  bool _isPasswordLengthValid(String password) => password.length >= 6 && password.length <= 32;
  bool _hasSpecialChar(String password) => RegExp(r'[^\w\s]').hasMatch(password);
  bool _hasDigit(String password) => RegExp(r'\d').hasMatch(password);
  bool _isPasswordStrong(String password) => _isPasswordLengthValid(password) && _hasSpecialChar(password) && _hasDigit(password);
  bool _isConfirmMatched() => _confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text == _passwordController.text;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = Provider.of<RegistrationData>(context, listen: false);
      if (data.phoneNumber != null) _phoneController.text = data.phoneNumber!;
      if (data.password != null) _passwordController.text = data.password!;
      if (data.confirmPassword != null) _confirmPasswordController.text = data.confirmPassword!;
    });
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndNext() {
    setState(() {
      _isLoading = true;
      _submitted = true;
      _phoneError = _passwordError = _confirmPasswordError = null;
    });

    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String confirm = _confirmPasswordController.text;

    String? phoneError;
    String? passwordError;
    String? confirmError;

    if (phone.isEmpty) {
      phoneError = 'Vui lòng nhập số điện thoại';
    } else {
      final RegExp vnPhone = RegExp(r'^(?:\+?84|0)\d{9,10}$');
      if (!vnPhone.hasMatch(phone)) phoneError = 'Số điện thoại không hợp lệ';
    }
    if (password.isEmpty) {
      passwordError = 'Vui lòng nhập mật khẩu';
    } else if (!_isPasswordLengthValid(password)) {
      passwordError = 'Mật khẩu phải dài 6-32 ký tự';
    } else if (!_hasSpecialChar(password)) {
      passwordError = 'Mật khẩu phải bao gồm ký tự đặc biệt';
    } else if (!_hasDigit(password)) {
      passwordError = 'Mật khẩu phải bao gồm chữ số';
    }
    if (confirm.isEmpty) {
      confirmError = 'Vui lòng nhập lại mật khẩu';
    } else if (password != confirm) {
      confirmError = 'Mật khẩu không khớp';
    }

    if (phoneError != null || passwordError != null || confirmError != null) {
      setState(() {
        _phoneError = phoneError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmError;
        _isLoading = false;
      });
      return;
    }

    final data = Provider.of<RegistrationData>(context, listen: false);
    data.setPhoneNumber(phone);
    data.setPassword(password);
    data.setConfirmPassword(confirm);

    setState(() => _isLoading = false);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(title: 'Tài khoản gara', onLeftPressed: widget.onBack ?? () => Navigator.pop(context)),
            StepProgressBar(currentStep: widget.currentStep, totalSteps: widget.totalSteps, height: 1.0, fullWidth: true),
            Expanded(
              child: KeyboardDismissWrapper(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: 'assets/icons_final/profile.svg'),
                      const SizedBox(height: 12),
                      MyText(text: 'Đăng ký', textStyle: 'head', textSize: '24', textColor: 'primary'),
                      const SizedBox(height: 4),
                      MyText(text: 'Nhập thông tin tài khoản cho gara của bạn', textStyle: 'body', textSize: '14', textColor: 'secondary'),
                      const SizedBox(height: 32),

                      MyTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        obscureText: false,
                        hasError: _submitted && _phoneError != null,
                        errorText: _phoneError,
                        keyboardType: TextInputType.phone,
                        onChange: (v) {
                          if (_submitted) {
                            final String val = v.trim();
                            final RegExp vnPhone = RegExp(r'^(?:\+?84|0)\d{9,10}$');
                            setState(() {
                              if (val.isEmpty) _phoneError = 'Vui lòng nhập số điện thoại';
                              else if (!vnPhone.hasMatch(val)) _phoneError = 'Số điện thoại không hợp lệ';
                              else _phoneError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      MyTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        obscureText: true,
                        hasError: _submitted && _passwordError != null,
                        errorText: _passwordError,
                        suffixIcon: (_isPasswordStrong(_passwordController.text))
                            ? Container(width: 24, height: 24, alignment: Alignment.center, child: SvgIcon(svgPath: 'assets/icons_final/Check-blue.svg', width: 24, height: 24))
                            : null,
                        onChange: (value) {
                          if (_submitted) {
                            setState(() {
                              if (value.isEmpty) _passwordError = 'Vui lòng nhập mật khẩu';
                              else if (!_isPasswordLengthValid(value)) _passwordError = 'Mật khẩu phải dài 6-32 ký tự';
                              else if (!_hasSpecialChar(value)) _passwordError = 'Mật khẩu phải bao gồm ký tự đặc biệt';
                              else if (!_hasDigit(value)) _passwordError = 'Mật khẩu phải bao gồm chữ số';
                              else _passwordError = null;
                              if (_confirmPasswordController.text.isNotEmpty) {
                                _confirmPasswordError = (_confirmPasswordController.text == value) ? null : 'Mật khẩu không khớp';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_passwordController.text.isNotEmpty) _buildPasswordStrengthHelper(),
                      const SizedBox(height: 16),

                      MyTextField(
                        controller: _confirmPasswordController,
                        label: 'Nhập lại mật khẩu',
                        obscureText: true,
                        hasError: _submitted && _confirmPasswordError != null,
                        errorText: _confirmPasswordError,
                        suffixIcon: (_isConfirmMatched())
                            ? Container(width: 24, height: 24, alignment: Alignment.center, child: SvgIcon(svgPath: 'assets/icons_final/Check-blue.svg', width: 24, height: 24))
                            : null,
                        onChange: (value) {
                          if (_submitted) {
                            setState(() {
                              if (value.isEmpty) _confirmPasswordError = 'Vui lòng nhập lại mật khẩu';
                              else if (value != _passwordController.text) _confirmPasswordError = 'Mật khẩu không khớp';
                              else _confirmPasswordError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      MyButton(
                        text: _isLoading ? 'Đang xử lý...' : 'Tiếp tục',
                        buttonType: (_isLoading || !_isFormNotEmpty()) ? ButtonType.disable : ButtonType.primary,
                        onPressed: (_isLoading || !_isFormNotEmpty()) ? null : _validateAndNext,
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

  Widget _buildPasswordStrengthHelper() {
    final String pw = _passwordController.text;
    final bool c1 = _isPasswordLengthValid(pw);
    final bool c2 = _hasSpecialChar(pw);
    final bool c3 = _hasDigit(pw);

    Widget line(bool ok, String text) => Row(children: [
          SvgIcon(svgPath: ok ? 'assets/icons_final/check_outline.svg' : 'assets/icons_final/close.svg', width: 16, height: 16),
          const SizedBox(width: 8),
          MyText(text: text, textStyle: 'body', textSize: '14', textColor: 'secondary'),
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line(c1, 'Độ dài 6 - 32 kí tự'),
      const SizedBox(height: 4),
      line(c2, 'Bao gồm kí tự đặc biệt'),
      const SizedBox(height: 4),
      line(c3, 'Bao gồm chữ số'),
    ]);
  }
}


