import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/smart_image_picker.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/user/user_service.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedYear = DateTime.now().year.toString();
  final List<File> _attachedImages = [];
  final int _maxImages = 10;
  bool _isLoading = false;

  List<String> get _years {
    final current = DateTime.now().year;
    return List<String>.generate(40, (i) => (current - i).toString());
  }

  void _onSubmit() async {
    if (_isLoading) return; // Ngăn ấn nhiều lần khi đang loading

    // Validate cơ bản
    if (_typeController.text.trim().isEmpty) {
      AppToastHelper.showError(context, message: 'Vui lòng nhập loại xe');
      return;
    }

    if (_plateController.text.trim().isEmpty) {
      AppToastHelper.showError(context, message: 'Vui lòng nhập biển số xe');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      AppToastHelper.showError(context, message: 'Vui lòng nhập mô tả xe');
      return;
    }

    if (_attachedImages.isEmpty) {
      AppToastHelper.showWarning(context, message: 'Vui lòng chọn ít nhất một ảnh xe');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API tạo xe mới
      final success = await UserService.createCar(
        typeCar: _typeController.text.trim(),
        yearModel: _selectedYear,
        vehicleLicensePlate: _plateController.text.trim(),
        description: _descriptionController.text.trim(),
        files: _attachedImages,
      );

      if (!mounted) return;

      if (success) {
        // Quay lại màn hình trước đó và để màn hình đó xử lý toast
        Navigator.of(context).pop({'created': true});
      } else {
        AppToastHelper.showError(context, message: 'Thêm xe thất bại. Vui lòng thử lại!');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(text: 'Hình ảnh xe', textStyle: 'title', textSize: '16', textColor: 'primary'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              SmartImagePicker(
                label: 'Thêm ảnh xe',
                showPreview: false,
                onImageSelected: (file) {
                  if (file == null) return;
                  if (_attachedImages.length >= _maxImages) {
                    AppToastHelper.showWarning(context, message: 'Chỉ được thêm tối đa $_maxImages ảnh xe');
                    return;
                  }
                  setState(() => _attachedImages.add(file));
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _attachedImages.isNotEmpty
                        ? SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder:
                                (ctx, i) => _fileThumb(_attachedImages[i], () {
                                  setState(() => _attachedImages.removeAt(i));
                                }),
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: _attachedImages.length,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fileThumb(File file, VoidCallback onRemove) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _plateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              title: 'Thêm phương tiện',
              showLeftButton: true,
              onLeftPressed: () => Navigator.pop(context),
              showRightButton: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    MyTextField(
                      label: 'Loại xe',
                      hintText: 'Loại xe..',
                      controller: _typeController,
                      obscureText: false,
                      hasError: false,
                    ),
                    const SizedBox(height: 12),
                    MyDropdown(
                      label: 'Đời xe',
                      hintText: 'Đời xe..',
                      items: _years.map((y) => DropdownItem(value: y, label: y)).toList(),
                      selectedValue: _selectedYear,
                      onChanged: (val) => setState(() => _selectedYear = val ?? ''),
                    ),
                    const SizedBox(height: 12),
                    MyTextField(
                      label: 'Biển số',
                      hintText: 'Biển số..',
                      controller: _plateController,
                      obscureText: false,
                      hasError: false,
                    ),
                    const SizedBox(height: 12),
                    MyTextField(
                      label: 'Mô tả xe',
                      hintText: 'Mô tả xe..',
                      controller: _descriptionController,
                      obscureText: false,
                      hasError: false,
                      maxLines: 3,
                      height: 80,
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentsSection(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: MyButton(
                text: _isLoading ? 'Đang thêm xe...' : 'Thêm xe',
                buttonType: _isLoading ? ButtonType.disable : ButtonType.primary,
                height: 44,
                startIcon: _isLoading ? null : 'assets/icons_final/add.svg',
                sizeStartIcon: const Size(20, 20),
                onPressed: _isLoading ? null : _onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
