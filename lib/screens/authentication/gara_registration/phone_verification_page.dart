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
import 'package:gara/services/debug_helper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:gara/providers/user_provider.dart';

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

  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP đã được gửi đến số điện thoại của bạn'),
              backgroundColor: Colors.green,
            ),
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

      // Debug: Log OTP verification response
      DebugHelper.logError('OTP Verification Response', verifyResponse);

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

      // Step 2: Register garage after OTP verification
      // Debug: Log registration data
      DebugHelper.logError('Registration Data Debug', {
        'phoneNumber': registrationData.phoneNumber,
        'password': registrationData.password != null ? '***' : null,
        'garageName': registrationData.garageName,
        'email': registrationData.email,
        'address': registrationData.address,
        'numberOfWorkers': registrationData.numberOfWorkers,
        'descriptionGarage': registrationData.descriptionGarage,
        'garageImagesCount': registrationData.garageImages?.length,
      });
      
      // Validate required fields
      if (registrationData.phoneNumber == null ||
          registrationData.password == null ||
          registrationData.garageName == null ||
          registrationData.email == null ||
          registrationData.address == null ||
          registrationData.numberOfWorkers == null) {
        setState(() {
          _isLoading = false;
        });
        ErrorDialog.showSnackBar(
          context, 
          'Thiếu thông tin đăng ký. Vui lòng kiểm tra lại.',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Extract session_id from OTP verification response if available
      // Session ID không cần thiết cho API đăng ký gara hiện tại

      final registerRequest = GarageRegisterRequest(
        phone: registrationData.phoneNumber!,
        password: registrationData.password!,
        nameGarage: registrationData.garageName!,
        emailGarage: registrationData.email!,
        address: registrationData.address!,
        numberOfWorker: registrationData.numberOfWorkers!.toString(),
        descriptionGarage: registrationData.descriptionGarage ?? 'mô tả', // Truyền chuỗi rỗng nếu null
        cccd: registrationData.cccd,
        issueDate: registrationData.issueDate?.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
        signature: registrationData.signature,
      );

      // Chuẩn bị files (nếu có) để upload kèm form-data
      final List<http.MultipartFile> files = [];
      final images = registrationData.garageImages;
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          final filename = file.path.split('/').last.split('\\').last;
          // Đoán content-type theo phần mở rộng
          final lower = filename.toLowerCase();
          MediaType contentType;
          if (lower.endsWith('.png')) {
            contentType = MediaType('image', 'png');
          } else if (lower.endsWith('.webp')) {
            contentType = MediaType('image', 'webp');
          } else if (lower.endsWith('.heic')) {
            contentType = MediaType('image', 'heic');
          } else {
            contentType = MediaType('image', 'jpeg');
          }

          // Phía server đọc: request.files.getlist("files")
          final part = await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: contentType,
            filename: filename,
          );
          files.add(part);
        }
      }

      // Debug: Log request body và số lượng files
      DebugHelper.logError('Garage Register Request', {
        ...registerRequest.toJson(),
        'filesCount': files.length,
        'fileNames': files.map((f) => f.filename).toList(),
      });

      final registerResponse = await AuthService.registerGarage(
        registerRequest,
        files: files.isNotEmpty ? files : null,
      );

      if (!mounted) return;

      if (registerResponse.success) {
        // Registration successful - tokens are already saved in AuthService
        registrationData.setOtpCode(otp);
        registrationData.setOtpVerified(true);
        registrationData.setRegistrationComplete(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký garage thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Cập nhật UserProvider với thông tin user mới
        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.refreshUserInfo();
          final userInfo = userProvider.userInfo;
          
          DebugHelper.logError('GetUserInfo Response', {
            'avatar': userInfo?.avatar,
            'avatarPath': userInfo?.avatarPath,
            'nameGarage': userInfo?.nameGarage,
            'listFileAvatar': userInfo?.listFileAvatar?.map((e) => e.toJson()).toList(),
            'listFileCertificate': userInfo?.listFileCertificate?.map((e) => e.toJson()).toList(),
            'raw': userInfo?.toString(),
          });
        } catch (e) {
          DebugHelper.logError('GetUserInfo Error', e);
        }

        widget.onNext();
      } else {
        setState(() {
          _isLoading = false;
        });
        ErrorDialog.showSnackBar(
          context, 
          registerResponse.message ?? 'Đăng ký garage thất bại',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP mới đã được gửi'),
              backgroundColor: Colors.green,
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: DesignTokens.borderPrimary),
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