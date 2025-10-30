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
import 'package:gara/models/car/car_info_model.dart';
import 'package:gara/utils/url.dart';

class EditCarScreen extends StatefulWidget {
  final CarInfo carInfo;

  const EditCarScreen({super.key, required this.carInfo});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedYear;
  final List<File> _newImages = [];
  final List<Map<String, dynamic>> _currentFiles = [];
  final int _maxImages = 10;
  bool _isLoading = false;

  List<String> get _years {
    final current = DateTime.now().year;
    return List<String>.generate(40, (i) => (current - i).toString());
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _typeController.text = widget.carInfo.typeCar;
    _plateController.text = widget.carInfo.vehicleLicensePlate;
    _descriptionController.text = widget.carInfo.description ?? '';
    _selectedYear = widget.carInfo.yearModel;

    // Lưu thông tin file hiện tại
    if (widget.carInfo.listFiles != null && widget.carInfo.listFiles!.isNotEmpty) {
      for (final file in widget.carInfo.listFiles!) {
        _currentFiles.add({'id': file.id, 'path': file.path});
      }
    } else if (widget.carInfo.files != null) {
      // Fallback cho trường hợp cũ
      _currentFiles.add({'id': widget.carInfo.files!.id, 'path': widget.carInfo.files!.path});
    }
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API cập nhật xe
      final success = await UserService.updateCar(
        carId: widget.carInfo.id.toString(),
        typeCar: _typeController.text.trim(),
        yearModel: _selectedYear ?? DateTime.now().year.toString(),
        vehicleLicensePlate: _plateController.text.trim(),
        description: _descriptionController.text.trim(),
        currentFiles: _currentFiles, // Chỉ gửi những ảnh cũ còn lại (không bị xóa)
        newFiles: _newImages.isNotEmpty ? _newImages : null,
      );

      if (!mounted) return;

      if (success) {
        // Quay lại màn hình trước đó và để màn hình đó xử lý toast
        Navigator.of(context).pop({'updated': true});
      } else {
        AppToastHelper.showError(context, message: 'Cập nhật xe thất bại. Vui lòng thử lại!');
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

        // Nút thêm ảnh mới
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              SmartImagePicker(
                label: 'Thêm ảnh xe',
                showPreview: false,
                onImageSelected: (file) {
                  if (file == null) return;
                  if (_newImages.length >= _maxImages) {
                    AppToastHelper.showWarning(context, message: 'Chỉ được thêm tối đa $_maxImages ảnh xe');
                    return;
                  }
                  setState(() => _newImages.add(file));
                },
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildAllImagesDisplay()),
            ],
          ),
        ),
      ],
    );
  }

  // Hiển thị tất cả ảnh (cũ + mới)
  Widget _buildAllImagesDisplay() {
    final allImages = <Widget>[];

    // Thêm ảnh cũ từ server
    for (int i = 0; i < _currentFiles.length; i++) {
      final fileInfo = _currentFiles[i];
      allImages.add(
        _buildExistingFileThumb(fileInfo, () {
          setState(() {
            _currentFiles.removeAt(i);
          });
        }),
      );
    }

    // Thêm ảnh mới từ picker
    for (int i = 0; i < _newImages.length; i++) {
      allImages.add(
        _fileThumb(_newImages[i], () {
          setState(() => _newImages.removeAt(i));
        }),
      );
    }

    if (allImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, i) => allImages[i],
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: allImages.length,
      ),
    );
  }

  // Hiển thị ảnh cũ từ server
  Widget _buildExistingFileThumb(Map<String, dynamic> fileInfo, VoidCallback onRemove) {
    final imageUrl = resolveImageUrl(fileInfo['path']) ?? '';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              (imageUrl.toLowerCase().endsWith('.svg'))
                  ? Container(
                    width: 80,
                    height: 80,
                    color: DesignTokens.surfaceSecondary,
                    child: const Icon(Icons.image, size: 40, color: DesignTokens.textSecondary),
                  )
                  : Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: DesignTokens.gray100, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: DesignTokens.gray100, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.image, color: DesignTokens.gray400),
                      );
                    },
                  ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Label để phân biệt ảnh cũ
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
            child: const Text('Cũ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
              title: 'Sửa thông tin xe',
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
                      onChanged: (val) => setState(() => _selectedYear = val),
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
                text: _isLoading ? 'Đang cập nhật...' : 'Cập nhật xe',
                buttonType: _isLoading ? ButtonType.disable : ButtonType.primary,
                height: 44,
                startIcon: _isLoading ? null : 'assets/icons_final/edit-2.svg',
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
