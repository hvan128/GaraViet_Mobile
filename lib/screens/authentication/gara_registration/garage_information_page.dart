import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/index.dart';
import 'package:provider/provider.dart';
import 'package:gara/widgets/text.dart';
// import 'package:gara/widgets/svg_icon.dart';
// import 'package:gara/theme/index.dart';

import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/smart_image_picker.dart';
import 'package:gara/widgets/progress_bar.dart';
import 'package:gara/widgets/header.dart';

class GarageInformationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;

  const GarageInformationPage({
    super.key,
    required this.onNext,
    this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<GarageInformationPage> createState() => _GarageInformationPageState();
}

class _GarageInformationPageState extends State<GarageInformationPage> {
  final TextEditingController _garageNameController = TextEditingController();
  final TextEditingController _numberOfWorkersController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;

  String? _garageNameError;
  String? _numberOfWorkersError;
  String? _addressError;
  String? _emailError;

  List<File> _selectedImages = [];

  // Trang này chỉ còn thông tin gara (không còn tài khoản)

  @override
  void initState() {
    super.initState();
    // Load existing data from RegistrationData immediately so initialImage works on first build
    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    if (registrationData.garageName != null) {
      _garageNameController.text = registrationData.garageName!;
    }
    if (registrationData.numberOfWorkers != null) {
      _numberOfWorkersController.text =
          registrationData.numberOfWorkers.toString();
    }
    if (registrationData.address != null) {
      _addressController.text = registrationData.address!;
    }
    if (registrationData.email != null) {
      _emailController.text = registrationData.email!;
    }
    if (registrationData.garageImages != null) {
      _selectedImages = registrationData.garageImages!;
    }

    // Không còn nghe thay đổi mật khẩu ở màn này
  }

  @override
  void dispose() {
    _garageNameController.dispose();
    _numberOfWorkersController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    
    super.dispose();
  }

  bool _isFormNotEmpty() {
    return _garageNameController.text.isNotEmpty &&
        _numberOfWorkersController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _emailController.text.isNotEmpty;
  }

  void _validateAndNext() {
    setState(() {
      _isLoading = true;
      _submitted = true;
      _garageNameError = null;
      _numberOfWorkersError = null;
      _addressError = null;
      _emailError = null;
    });

    final String garageName = _garageNameController.text.trim();
    final String numWorkersStr = _numberOfWorkersController.text.trim();
    final String address = _addressController.text.trim();
    final String email = _emailController.text.trim();
    

    String? garageNameError;
    String? numberOfWorkersError;
    String? addressError;
    String? emailError;
    

    if (garageName.isEmpty) {
      garageNameError = 'Vui lòng nhập tên gara';
    }
    final int? numberOfWorkers = int.tryParse(numWorkersStr);
    if (numWorkersStr.isEmpty) {
      numberOfWorkersError = 'Vui lòng nhập số lượng nhân viên';
    } else if (numberOfWorkers == null || numberOfWorkers <= 0) {
      numberOfWorkersError = 'Số lượng nhân viên phải là số dương';
    }
    if (address.isEmpty) {
      addressError = 'Vui lòng nhập địa chỉ';
    }
    if (email.isEmpty) {
      emailError = 'Vui lòng nhập email';
    } else if (!email.contains('@')) {
      emailError = 'Email không hợp lệ';
    }
    

    final bool hasAnyError =
        garageNameError != null ||
        numberOfWorkersError != null ||
        addressError != null ||
        emailError != null;

    if (hasAnyError) {
      setState(() {
        _garageNameError = garageNameError;
        _numberOfWorkersError = numberOfWorkersError;
        _addressError = addressError;
        _emailError = emailError;
        _isLoading = false;
      });
      return;
    }

    // Save to RegistrationData
    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    registrationData.setGarageName(garageName);
    registrationData.setNumberOfWorkers(numberOfWorkers);
    registrationData.setAddress(address);
    registrationData.setEmail(email);
    
    registrationData.setGarageImages(_selectedImages);

    // Reset loading state before navigation
    setState(() {
      _isLoading = false;
    });

    // Navigate to next page
    widget.onNext();
  }

  void _onImagesSelected(File? image) {
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            MyHeader(
              title: 'Thông tin gara',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: "assets/icons_final/profile.svg"),

                      const SizedBox(height: 12),

                      MyText(
                        text: 'Đăng ký',
                        textStyle: 'head',
                        textSize: '24',
                        textColor: 'primary',
                      ),
                      const SizedBox(height: 4),

                      // Mô tả
                      MyText(
                        text: 'Hãy cung cấp thông tin về gara của bạn',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),
                      const SizedBox(height: 32),
                      // Form content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Garage Name input
                          MyTextField(
                            controller: _garageNameController,
                            label: 'Tên gara',
                            obscureText: false,
                            hasError: _submitted && _garageNameError != null,
                            errorText: _garageNameError,
                            onChange: (value) {
                              setState(() {
                                if (_submitted) {
                                  _garageNameError = value.trim().isEmpty
                                      ? 'Vui lòng nhập tên gara'
                                      : null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Number of Workers input
                          MyTextField(
                            controller: _numberOfWorkersController,
                            label: 'Số lượng nhân viên',
                            obscureText: false,
                            hasError:
                                _submitted && _numberOfWorkersError != null,
                            errorText: _numberOfWorkersError,
                            keyboardType: TextInputType.number,
                            onChange: (value) {
                              setState(() {
                                if (_submitted) {
                                  final num = int.tryParse(value.trim());
                                  if (value.trim().isEmpty) {
                                    _numberOfWorkersError = 'Vui lòng nhập số lượng nhân viên';
                                  } else if (num == null || num <= 0) {
                                    _numberOfWorkersError = 'Số lượng nhân viên phải là số dương';
                                  } else {
                                    _numberOfWorkersError = null;
                                  }
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address input
                          MyTextField(
                            controller: _addressController,
                            label: 'Địa chỉ',
                            obscureText: false,
                            hasError: _submitted && _addressError != null,
                            errorText: _addressError,
                            onChange: (value) {
                              setState(() {
                                if (_submitted) {
                                  _addressError = value.trim().isEmpty
                                      ? 'Vui lòng nhập địa chỉ'
                                      : null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email input
                          MyTextField(
                            controller: _emailController,
                            label: 'Email',
                            obscureText: false,
                            hasError: _submitted && _emailError != null,
                            errorText: _emailError,
                            keyboardType: TextInputType.emailAddress,
                            onChange: (value) {
                              setState(() {
                                if (_submitted) {
                                  final v = value.trim();
                                  if (v.isEmpty) {
                                    _emailError = 'Vui lòng nhập email';
                                  } else if (!v.contains('@')) {
                                    _emailError = 'Email không hợp lệ';
                                  } else {
                                    _emailError = null;
                                  }
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                         
                          MyText(text: 'Hình ảnh', textStyle: 'body', textSize: '14', textColor: 'secondary'),
                          const SizedBox(height: 6),
                          // Image Picker
                          Row(
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: SmartImagePicker(
                                  label: 'Hình ảnh',
                                  onImageSelected: _onImagesSelected,
                                  initialImage:
                                      _selectedImages.isNotEmpty
                                          ? _selectedImages.first
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: SmartImagePicker(
                                  label: 'Hình ảnh',
                                  onImageSelected: _onImagesSelected,
                                  initialImage:
                                      _selectedImages.length > 1
                                          ? _selectedImages[1]
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: SmartImagePicker(
                                  label: 'Hình ảnh',
                                  onImageSelected: _onImagesSelected,
                                  initialImage:
                                      _selectedImages.length > 2
                                          ? _selectedImages[2]
                                          : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(text: 'Lưu ý: Bạn có thể chọn tối đa 3 hình ảnh', textStyle: 'body', textSize: '12', textColor: 'primary'),
                              MyText(text: '  - 1 hình ảnh nhìn từ trước, có biển hiệu', textStyle: 'body', textSize: '12', textColor: 'primary'),
                              MyText(text: '  - 2 hình ảnh ở trong gara', textStyle: 'body', textSize: '12', textColor: 'primary'),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Continue button
                          MyButton(
                            text: _isLoading ? 'Đang xử lý...' : 'Tiếp tục',
                            buttonType:
                                (_isLoading || !_isFormNotEmpty())
                                    ? ButtonType.disable
                                    : ButtonType.primary,
                            onPressed:
                                (_isLoading || !_isFormNotEmpty())
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
}
