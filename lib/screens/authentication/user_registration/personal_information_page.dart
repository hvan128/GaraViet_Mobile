import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/progress_bar.dart';
import 'package:gara/widgets/header.dart';

class PersonalInformationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;

  const PersonalInformationPage({
    super.key,
    required this.onNext,
    this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _submitted = false;

  // Form validator: true nếu tất cả trường hợp lệ
  bool _isFormValid() {
    final String fullName = _fullNameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    final bool hasFullName = fullName.isNotEmpty;
    final bool hasPhone =
        phone.isNotEmpty; // Có thể bổ sung regex VN phone nếu cần
    final bool hasPassword = password.isNotEmpty && password.length >= 6;
    final bool hasConfirm =
        confirmPassword.isNotEmpty && confirmPassword == password;

    return hasFullName && hasPhone && hasPassword && hasConfirm;
  }

  // Điều kiện 1: độ dài hợp lệ (6-32)
  bool _isPasswordLengthValid(String password) {
    return password.length >= 6 && password.length <= 32;
  }

  bool _isFormNotEmpty() {
    return _fullNameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  // Điều kiện 2: có ít nhất một ký tự đặc biệt
  bool _hasSpecialChar(String password) {
    final RegExp special = RegExp(r'[^\w\s]');
    return special.hasMatch(password);
  }

  // Điều kiện 3: có ít nhất một chữ số
  bool _hasDigit(String password) {
    final RegExp digit = RegExp(r'\d');
    return digit.hasMatch(password);
  }

  // Tổng hợp: mạnh khi thỏa cả 3 điều kiện
  bool _isPasswordStrong(String password) {
    return _isPasswordLengthValid(password) &&
        _hasSpecialChar(password) &&
        _hasDigit(password);
  }

  // Kiểm tra nhập lại mật khẩu đúng
  bool _isConfirmMatched() {
    return _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text == _passwordController.text;
  }

  String? _fullNameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    // Load existing data from RegistrationData
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationData = Provider.of<RegistrationData>(
        context,
        listen: false,
      );
      if (registrationData.fullName != null) {
        _fullNameController.text = registrationData.fullName!;
      }
      if (registrationData.phoneNumber != null) {
        _phoneController.text = registrationData.phoneNumber!;
      }
      if (registrationData.password != null) {
        _passwordController.text = registrationData.password!;
      }
      if (registrationData.confirmPassword != null) {
        _confirmPasswordController.text = registrationData.confirmPassword!;
      }
    });

    // Lắng nghe thay đổi để cập nhật trạng thái nút tiếp tục
    _fullNameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndNext() {
    // Bật loading và reset lỗi
    setState(() {
      _isLoading = true;
      _submitted = true;
      _fullNameError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final String fullName = _fullNameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String confirm = _confirmPasswordController.text;

    // Gom lỗi để hiển thị đồng thời cho tất cả các ô
    String? fullNameError;
    String? phoneError;
    String? passwordError;
    String? confirmError;

    // 1) Họ tên
    if (fullName.isEmpty) {
      fullNameError = 'Vui lòng nhập tên đầy đủ';
    }

    // 2) SĐT
    if (phone.isEmpty) {
      phoneError = 'Vui lòng nhập số điện thoại';
    } else {
      final RegExp vnPhone = RegExp(r'^(?:\+?84|0)\d{9,10}$');
      if (!vnPhone.hasMatch(phone)) {
        phoneError = 'Số điện thoại không hợp lệ';
      }
    }

    // 3) Mật khẩu
    if (password.isEmpty) {
      passwordError = 'Vui lòng nhập mật khẩu';
    } else if (!_isPasswordLengthValid(password)) {
      passwordError = 'Mật khẩu phải dài 6-32 ký tự';
    } else if (!_hasSpecialChar(password)) {
      passwordError = 'Mật khẩu phải bao gồm ký tự đặc biệt';
    } else if (!_hasDigit(password)) {
      passwordError = 'Mật khẩu phải bao gồm chữ số';
    }

    // 4) Xác nhận mật khẩu
    if (confirm.isEmpty) {
      confirmError = 'Vui lòng nhập lại mật khẩu';
    } else if (password != confirm) {
      confirmError = 'Mật khẩu không khớp';
    }

    final bool hasAnyError =
        fullNameError != null ||
        phoneError != null ||
        passwordError != null ||
        confirmError != null;

    if (hasAnyError) {
      setState(() {
        _fullNameError = fullNameError;
        _phoneError = phoneError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmError;
        _isLoading = false;
      });
      return;
    }

    // Lưu dữ liệu khi không có lỗi
    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    registrationData.setFullName(fullName);
    registrationData.setPhoneNumber(phone);
    registrationData.setPassword(password);
    registrationData.setConfirmPassword(confirm);

    setState(() {
      _isLoading = false;
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            MyHeader(
              title: 'Thông tin cá nhân',
              onLeftPressed: widget.onBack ?? () => Navigator.pop(context),
            ),

            // Progress bar
            StepProgressBar(
              currentStep: widget.currentStep,
              totalSteps: widget.totalSteps,
              height: 1.0,
              fullWidth: true,
            ),

            // Content
            Expanded(
              child: KeyboardDismissWrapper(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: "assets/icons_final/profile.svg"),

                      const SizedBox(height: 12),

                      // Title
                      MyText(
                        text: 'Bạn là...',
                        textStyle: 'head',
                        textSize: '24',
                        textColor: 'primary',
                      ),

                      const SizedBox(height: 4),

                      MyText(
                        text: 'Hãy cho chúng tôi biết thêm về bạn.',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),

                      const SizedBox(height: 32),

                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name input
                          MyTextField(
                            controller: _fullNameController,
                            label: 'Tên đầy đủ',
                            obscureText: false,
                            hasError: _submitted && _fullNameError != null,
                            errorText: _fullNameError,
                            hintText: 'Nhập tên đầy đủ',
                            onChange: (value) {
                              final String v = value.trim();
                              if (_submitted) {
                                setState(() {
                                  _fullNameError =
                                      v.isEmpty
                                          ? 'Vui lòng nhập tên đầy đủ'
                                          : null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                      
                          // Phone number input
                          MyTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            obscureText: false,
                            hasError: _submitted && _phoneError != null,
                            errorText: _phoneError,
                            keyboardType: TextInputType.phone,
                            hintText: 'Nhập số điện thoại',
                            onChange: (value) {
                              final String v = value.trim();
                              final RegExp vnPhone = RegExp(
                                r'^(?:\+?84|0)\d{9,10}$',
                              );
                              if (_submitted) {
                                setState(() {
                                  if (v.isEmpty) {
                                    _phoneError =
                                        'Vui lòng nhập số điện thoại';
                                  } else if (!vnPhone.hasMatch(v)) {
                                    _phoneError =
                                        'Số điện thoại không hợp lệ';
                                  } else {
                                    _phoneError = null;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                      
                          // Password input
                          MyTextField(
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            obscureText: _obscurePassword,
                            hasError: _submitted && _passwordError != null,
                            errorText: _passwordError,
                            suffixIcon:
                                (_isPasswordStrong(
                                      _passwordController.text,
                                    ))
                                    ? Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      child: SvgIcon(
                                        svgPath:
                                            'assets/icons_final/Check-blue.svg',
                                        width: 24,
                                        height: 24,
                                      ),
                                    )
                                    : null,
                            hintText: 'Nhập mật khẩu',
                            onChange: (value) {
                              final String pw = value;
                              String? err;
                              if (pw.isEmpty) {
                                err = 'Vui lòng nhập mật khẩu';
                              } else if (!_isPasswordLengthValid(pw)) {
                                err = 'Mật khẩu phải dài 6-32 ký tự';
                              } else if (!_hasSpecialChar(pw)) {
                                err =
                                    'Mật khẩu phải bao gồm ký tự đặc biệt';
                              } else if (!_hasDigit(pw)) {
                                err = 'Mật khẩu phải bao gồm chữ số';
                              }
                      
                              if (_submitted) {
                                setState(() {
                                  _passwordError = err;
                                  // Đồng bộ lại lỗi xác nhận khi mật khẩu thay đổi
                                  if (_confirmPasswordController
                                      .text
                                      .isNotEmpty) {
                                    _confirmPasswordError =
                                        (_confirmPasswordController.text ==
                                                pw)
                                            ? null
                                            : 'Mật khẩu không khớp';
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          if (_passwordController.text.isNotEmpty)
                            _buildPasswordStrengthHelperText(),
                          const SizedBox(height: 16),
                      
                          // Confirm Password input
                          MyTextField(
                            controller: _confirmPasswordController,
                            label: 'Nhập lại mật khẩu',
                            obscureText: _obscureConfirmPassword,
                            hasError:
                                _submitted && _confirmPasswordError != null,
                            errorText: _confirmPasswordError,
                            suffixIcon:
                                (_isConfirmMatched())
                                    ? Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      child: SvgIcon(
                                        svgPath:
                                            'assets/icons_final/Check-blue.svg',
                                        width: 24,
                                        height: 24,
                                      ),
                                    )
                                    : null,
                            hintText: 'Nhập lại mật khẩu',
                            onChange: (value) {
                              if (_submitted) {
                                setState(() {
                                  if (value.isEmpty) {
                                    _confirmPasswordError =
                                        'Vui lòng nhập lại mật khẩu';
                                  } else if (value !=
                                      _passwordController.text) {
                                    _confirmPasswordError =
                                        'Mật khẩu không khớp';
                                  } else {
                                    _confirmPasswordError = null;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                      
                          // Continue button
                          MyButton(
                            text: _isLoading ? 'Đang xử lý...' : 'Tiếp tục',
                            buttonType:
                                (!_isFormNotEmpty() || _isLoading)
                                    ? ButtonType.disable
                                    : ButtonType.primary,
                            onPressed:
                                (!_isFormNotEmpty() || _isLoading)
                                    ? null
                                    : _validateAndNext,
                          ),
                          const SizedBox(height: 12),
                      
                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MyText(
                                text: 'Đã có tài khoản?',
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'primary',
                              ),
                              const SizedBox(width: 8),
                              MyText(
                                text: 'Đăng nhập ngay!',
                                textStyle: 'title',
                                textSize: '14',
                                color: DesignTokens.primaryBlue,
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildPasswordStrengthHelperText() {
    final String pw = _passwordController.text;
    final bool c1 = _isPasswordLengthValid(pw);
    final bool c2 = _hasSpecialChar(pw);
    final bool c3 = _hasDigit(pw);

    Widget line(bool ok, String text) => Row(
      children: [
        SvgIcon(
          svgPath:
              ok
                  ? 'assets/icons_final/check_outline.svg'
                  : 'assets/icons_final/close.svg',
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 8),
        MyText(
          text: text,
          textStyle: 'body',
          textSize: '14',
          textColor: 'secondary',
        ),
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
}
