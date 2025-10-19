import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/progress_bar.dart';
import 'package:gara/widgets/header.dart';

class VehicleInformationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;

  const VehicleInformationPage({
    super.key,
    required this.onNext,
    this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<VehicleInformationPage> createState() => _VehicleInformationPageState();
}

class _VehicleInformationPageState extends State<VehicleInformationPage> {
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  
  bool _isLoading = false;
  bool _submitted = false;
  String? _vehicleTypeError;
  String? _vehicleYearError;
  String? _licensePlateError;

  final List<String> _vehicleYears = List.generate(
    30,
    (index) => (DateTime.now().year - index).toString(),
  );

  @override
  void initState() {
    super.initState();
    // Load existing data from provider (không listen)
    final registrationData = Provider.of<RegistrationData>(context, listen: false);
    // debugPrint('[VehiclePage:initState] provider.vehicleType=${registrationData.vehicleType}, provider.vehicleYear=${registrationData.vehicleYear}, provider.licensePlate=${registrationData.licensePlate}');
    if (registrationData.vehicleType != null) {
      _vehicleTypeController.text = registrationData.vehicleType!;
    }
    if (registrationData.vehicleYear != null) {
      _vehicleYearController.text = registrationData.vehicleYear!;
    }
    if (registrationData.licensePlate != null) {
      _licensePlateController.text = registrationData.licensePlate!;
    }
    // debugPrint('[VehiclePage:initState] controllers: type=${_vehicleTypeController.text}, year=${_vehicleYearController.text}, plate=${_licensePlateController.text}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Khi quay lại từ màn khác, đồng bộ lại dữ liệu từ Provider nếu khác
    final registrationData = Provider.of<RegistrationData>(context);
    // debugPrint('[VehiclePage:didChangeDependencies] provider(before sync) type=${registrationData.vehicleType}, year=${registrationData.vehicleYear}, plate=${registrationData.licensePlate} | controllers(before) type=${_vehicleTypeController.text}, year=${_vehicleYearController.text}, plate=${_licensePlateController.text}');
    if (registrationData.vehicleType != null &&
        registrationData.vehicleType!.isNotEmpty &&
        registrationData.vehicleType != _vehicleTypeController.text) {
      _vehicleTypeController.text = registrationData.vehicleType!;
    }
    if (registrationData.vehicleYear != null &&
        registrationData.vehicleYear!.isNotEmpty &&
        registrationData.vehicleYear != _vehicleYearController.text) {
      _vehicleYearController.text = registrationData.vehicleYear!;
    }
    if (registrationData.licensePlate != null &&
        registrationData.licensePlate!.isNotEmpty &&
        registrationData.licensePlate != _licensePlateController.text) {
      _licensePlateController.text = registrationData.licensePlate!;
    }
    // debugPrint('[VehiclePage:didChangeDependencies] controllers(after) type=${_vehicleTypeController.text}, year=${_vehicleYearController.text}, plate=${_licensePlateController.text}');
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleYearController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  // Kiểm tra rỗng tất cả các trường để enable nút Tiếp tục
  bool _isFormNotEmpty() {
    return _vehicleTypeController.text.trim().isNotEmpty &&
        _vehicleYearController.text.trim().isNotEmpty &&
        _licensePlateController.text.trim().isNotEmpty;
  }

  // Validate từng trường
  String _normalizePlate(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  String? _validateVehicleTypeValue(String value) {
    if (value.trim().isEmpty) return 'Vui lòng nhập loại xe';
    return null;
  }

  String? _validateVehicleYearValue(String value) {
    if (value.trim().isEmpty) return 'Vui lòng chọn năm sản xuất';
    return null;
  }

  String? _validateLicensePlateValue(String value) {
    final String raw = value.trim();
    if (raw.isEmpty) return 'Vui lòng nhập biển số xe';

    // Chuẩn hóa
    final String normalized = _normalizePlate(raw);

    // Điều kiện: đúng 8 ký tự và theo mẫu 2 số + 1 chữ + 5 số (VD: 30A12345)
    final bool lengthOk = normalized.length == 8;
    final RegExp pattern = RegExp(r'^\d{2}[A-Z]\d{5}$');
    final bool formatOk = pattern.hasMatch(normalized);

    if (!lengthOk || !formatOk) {
      return 'Biển số xe không hợp lệ (ví dụ: 30A12345)';
    }
    return null;
  }

  void _validateAndNext() {
    setState(() {
      _isLoading = true;
      _submitted = true; // Đánh dấu đã bấm Tiếp tục, bắt đầu hiển thị lỗi
      _vehicleTypeError = null;
      _vehicleYearError = null;
      _licensePlateError = null;
    });

    final String vehicleType = _vehicleTypeController.text;
    final String vehicleYear = _vehicleYearController.text;
    final String licensePlate = _licensePlateController.text;

    final String? vtErr = _validateVehicleTypeValue(vehicleType);
    final String? vyErr = _validateVehicleYearValue(vehicleYear);
    final String? lpErr = _validateLicensePlateValue(licensePlate);

    final bool hasAnyError = vtErr != null || vyErr != null || lpErr != null;

    if (hasAnyError) {
      setState(() {
        _vehicleTypeError = vtErr;
        _vehicleYearError = vyErr;
        _licensePlateError = lpErr;
        _isLoading = false;
      });
      return;
    }

    // Save to RegistrationData khi hợp lệ
    final registrationData = Provider.of<RegistrationData>(context, listen: false);
    final String normalizedPlate = _normalizePlate(licensePlate);
    // Cập nhật controller để hiển thị giá trị chuẩn hóa
    _licensePlateController.text = normalizedPlate;
    registrationData.setVehicleType(vehicleType.trim());
    registrationData.setVehicleYear(vehicleYear.trim());
    registrationData.setLicensePlate(normalizedPlate);
    // debugPrint('[VehiclePage:save] saved type=${vehicleType.trim()}, year=${vehicleYear.trim()}, plate=$normalizedPlate');

    setState(() {
      _isLoading = false;
    });

    widget.onNext();
  }

  // _showYearPicker đã bỏ, dùng MyDropdown thay thế

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
              title: 'Thông tin xe',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(svgPath: "assets/icons_final/car.svg"),

                      const SizedBox(height: 12),

                      // Title
                      MyText(
                        text: 'Phương tiện',
                        textStyle: 'head',
                        textSize: '24',
                        textColor: 'primary',
                      ),

                      const SizedBox(height: 4),

                      MyText(
                        text: 'Đừng lo bạn có thể thay đổi thông tin về sau.',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),

                      const SizedBox(height: 32),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Type input
                          MyTextField(
                            controller: _vehicleTypeController,
                            label: 'Loại xe',
                            hintText: 'Nhập loại xe',
                            obscureText: false,
                            hasError: _submitted && _vehicleTypeError != null,
                            errorText: _vehicleTypeError,
                            onChange: (value) {
                              setState(() {
                                if (_submitted) {
                                  _vehicleTypeError = _validateVehicleTypeValue(value);
                                }
                              });
                              // debugPrint('[VehiclePage:onChange] type="$value"');
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Vehicle Year input
                          MyDropdown(
                            items: _vehicleYears.map((year) => DropdownItem(value: year, label: year)).toList(),
                            selectedValue: _vehicleYearController.text,
                            onChanged: (value) {
                              setState(() {
                                _vehicleYearController.text = value ?? '';
                                if (_submitted) {
                                  _vehicleYearError = _validateVehicleYearValue(_vehicleYearController.text);
                                }
                              });
                            },
                            label: 'Đời xe',
                            hintText: 'Đời xe',
                            hasError: _submitted && _vehicleYearError != null,
                            errorText: _vehicleYearError,
                          ),
                          const SizedBox(height: 16),
                          
                          // License Plate input
                          MyTextField(
                            controller: _licensePlateController,
                            label: 'Biển số xe',
                            obscureText: false,
                            hasError: _submitted && _licensePlateError != null,
                            errorText: _licensePlateError,
                            hintText: 'Nhập biển số xe',
                            onChange: (value) {
                              setState(() {
                                if (_submitted) {
                                  _licensePlateError = _validateLicensePlateValue(value);
                                }
                              });
                              // debugPrint('[VehiclePage:onChange] plate="$value"');
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Continue button
                          MyButton(
                            text: _isLoading ? 'Đang xử lý...' : 'Tiếp tục',
                            buttonType: (_isLoading || !_isFormNotEmpty()) ? ButtonType.disable : ButtonType.primary,
                            onPressed: (_isLoading || !_isFormNotEmpty()) ? null : _validateAndNext,
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