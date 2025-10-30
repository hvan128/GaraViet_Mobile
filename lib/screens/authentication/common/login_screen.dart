import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/models/user/login_model.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/theme/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? helperTextPhone;
  String? helperTextPassword;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    // Load saved phone if remember me was checked
    final savedPhone = await Storage.getItem('saved_phone');
    final rememberMe = await Storage.getItem('remember_me');

    if (!mounted) return;
    if (savedPhone != null && rememberMe == true) {
      setState(() {
        _phoneController.text = savedPhone;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    // Validate required fields
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        helperTextPhone = 'Vui lòng nhập số điện thoại';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        helperTextPassword = 'Vui lòng nhập mật khẩu';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Get device ID
      final deviceId = await Storage.getDeviceID() ?? 'unknown_device';

      final request = UserLoginRequest(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        deviceId: deviceId,
        rememberMe: _rememberMe,
      );

      final response = await AuthService.loginUser(request);

      if (response.success) {
        if (!mounted) return;
        AppToastHelper.showSuccess(context, message: 'Đăng nhập thành công!');

        // Save phone if remember me is checked
        if (_rememberMe) {
          Storage.setItem('saved_phone', _phoneController.text.trim());
          Storage.setItem('remember_me', true);
        } else {
          Storage.setItem('saved_phone', null);
          Storage.setItem('remember_me', false);
        }

        // FCM token đã được đăng ký trong AuthService.loginUser()

        // Đợi một chút để đảm bảo UserProvider đã được cập nhật
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to home screen or next step
        Navigate.pushNamedAndRemoveAll('/home');
      } else {
        if (!mounted) return;
        AppToastHelper.showError(context, message: response.message ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      AppToastHelper.showError(context, message: 'Có lỗi xảy ra: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconField(svgPath: 'assets/icons_final/key.svg'),
                const SizedBox(height: 12),
                // Title
                MyText(text: 'Đăng nhập', textStyle: 'head', textSize: '24', textColor: 'primary'),
                const SizedBox(height: 8),
                MyText(
                  text: 'Đăng nhập bằng số điện thoại của bạn.',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'secondary',
                ),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone number input
                    MyTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hintText: 'Số điện thoại',
                      obscureText: false,
                      hasError: helperTextPhone != null,
                      errorText: helperTextPhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Password input
                    MyTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      obscureText: _obscurePassword,
                      hintText: 'Mật khẩu',
                      hasError: helperTextPassword != null,
                      errorText: helperTextPassword,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: SvgIcon(
                            svgPath:
                                _obscurePassword ? 'assets/icons_final/eye-slash.svg' : 'assets/icons_final/eye.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Remember me checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: DesignTokens.borderPrimary, width: 1),
                            activeColor: DesignTokens.textBrand,
                            checkColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MyText(text: 'Ghi nhớ đăng nhập', textStyle: 'body', textSize: '14', textColor: 'primary'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    MyButton(
                      text: _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                      onPressed: _isLoading ? null : _loginUser,
                      buttonType: ButtonType.primary,
                    ),
                    const SizedBox(height: 12),

                    // Register button
                    MyButton(
                      text: 'Đăng ký',
                      onPressed: () {
                        Navigate.pushNamedAndRemoveAll('/register');
                      },
                      buttonType: ButtonType.transparent,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText(text: 'Quên mật khẩu?', textStyle: 'body', textSize: '14', textColor: 'primary'),
                        const SizedBox(width: 8),
                        MyText(
                          text: 'Cài lại mật khẩu',
                          textStyle: 'title',
                          textSize: '14',
                          color: DesignTokens.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
