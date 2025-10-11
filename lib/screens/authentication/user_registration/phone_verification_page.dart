import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/progress_bar.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/models/user/user_model.dart';
import 'package:gara/widgets/error_dialog.dart';
import 'package:gara/widgets/debug_dialog.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/debug_helper.dart';

class PhoneVerificationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;

  const PhoneVerificationPage({
    super.key,
    required this.onNext,
    this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _sendInitialOtp();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  void _sendInitialOtp() async {
    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    
    if (registrationData.phoneNumber == null) {
      ErrorDialog.showSnackBar(
        context, 
        'Không tìm thấy số điện thoại',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final response = await AuthService.sendOtp(
        phone: registrationData.phoneNumber!,
      );

      if (mounted) {
        if (response['success'] == true) {
          // OTP sent successfully
          AppToastHelper.showSuccess(
            context,
            message: 'Mã OTP đã được gửi đến số điện thoại của bạn',
          );
        } else {
          ErrorDialog.showSnackBar(
            context, 
            response['message'] ?? 'Không thể gửi mã OTP',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DebugHelper.logError('_sendInitialOtp', e);
        ErrorDialog.showSnackBar(context, e, backgroundColor: Colors.red);
        DebugDialog.showSnackBar(context, e);
      }
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 4) {
      ErrorDialog.showSnackBar(
        context, 
        'Vui lòng nhập đầy đủ 4 số OTP',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );

    try {
      // Step 1: Verify OTP
      final verifyResponse = await AuthService.verifyOtp(
        phone: registrationData.phoneNumber!,
        otp: otp,
      );

      if (!mounted) return;

      if (verifyResponse['success'] != true) {
        setState(() {
          _isLoading = false;
        });
        ErrorDialog.showSnackBar(
          context, 
          verifyResponse['message'] ?? 'Mã OTP không đúng',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Step 2: Register user after OTP verification
      final registerRequest = UserRegisterRequest(
        phone: registrationData.phoneNumber!,
        password: registrationData.password!,
        name: registrationData.fullName!,
        typeCar: registrationData.vehicleType!,
        yearModel: registrationData.vehicleYear!,
        vehicleLicensePlate: registrationData.licensePlate!,
      );

      final registerResponse = await AuthService.registerUser(registerRequest);

      if (!mounted) return;

      if (registerResponse.success) {
        // Registration successful
        registrationData.setOtpCode(otp);
        registrationData.setOtpVerified(true);
        registrationData.setRegistrationComplete(true);

        AppToastHelper.showSuccess(
          context,
          message: 'Đăng ký thành công!',
        );

        widget.onNext();
      } else {
        setState(() {
          _isLoading = false;
        });
        ErrorDialog.showSnackBar(
          context, 
          registerResponse.message ?? 'Đăng ký thất bại',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        DebugHelper.logError('_verifyOtp', e);
        ErrorDialog.showSnackBar(context, e, backgroundColor: Colors.red);
        DebugDialog.showSnackBar(context, e);
      }
    }
  }

  void _resendOtp() async {
    setState(() {
      _isResending = true;
      _countdown = 60;
    });

    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );

    try {
      final response = await AuthService.resendOtp(
        phone: registrationData.phoneNumber!,
      );

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        if (response['success'] == true) {
          _startCountdown();
          AppToastHelper.showSuccess(
            context,
            message: 'Mã OTP mới đã được gửi',
          );
        } else {
          ErrorDialog.showSnackBar(
            context, 
            response['message'] ?? 'Không thể gửi lại mã OTP',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        DebugHelper.logError('_resendOtp', e);
        ErrorDialog.showSnackBar(context, e, backgroundColor: Colors.red);
        DebugDialog.showSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationData = Provider.of<RegistrationData>(context);
    final maskedPhone = registrationData.getMaskedPhoneNumber();

    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            MyHeader(
              title: 'Xác thực số điện thoại',
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconField(svgPath: "assets/icons_final/send.svg"),

                    const SizedBox(height: 12),

                    // Title
                    MyText(
                      text: 'Xác thực số điện thoại',
                      textStyle: 'head',
                      textSize: '24',
                      textColor: 'primary',
                    ),

                    const SizedBox(height: 4),

                    MyText(
                      text: 'Chúng tôi đã gửi mã xác thực đến số $maskedPhone',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),

                    const SizedBox(height: 32),

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
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
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onOtpChanged(value, index),
                          ),
                        );
                      }),
                    ),


                    const SizedBox(height: 24),

                    Row(
                      children: [
                        MyText(
                          text: 'Bạn có thể yêu cầu',
                          textStyle: 'body',
                          textSize: '14',
                          textColor: 'secondary',
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: MyText(
                            text: 'gửi lại mã',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: _countdown > 0 ? 'secondary' : 'brand',
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (_countdown > 0)
                          MyText(
                            text: 'sau ${_countdown}s',
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'secondary',
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Verify Button
                    MyButton(
                      text: _isLoading ? 'Đang xác thực...' : 'Xác thực',
                      onPressed: _isLoading ? null : _verifyOtp,
                    ),
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
