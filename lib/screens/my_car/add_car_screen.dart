import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/simple_image_picker.dart';
import 'package:gara/widgets/app_toast.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  String _selectedYear = DateTime.now().year.toString();
  File? _image;

  List<String> get _years {
    final current = DateTime.now().year;
    return List<String>.generate(40, (i) => (current - i).toString());
  }

  void _onSubmit() {
    // Tạm thời chỉ validate cơ bản; tích hợp API sau
    if (_typeController.text.trim().isEmpty) {
      AppToastHelper.showError(
        context,
        message: 'Vui lòng nhập loại xe',
      );
      return;
    }
    
    if (_plateController.text.trim().isEmpty) {
      AppToastHelper.showError(
        context,
        message: 'Vui lòng nhập biển số xe',
      );
      return;
    }
    
    if (_image == null) {
      AppToastHelper.showWarning(
        context,
        message: 'Vui lòng chọn ảnh xe',
      );
      return;
    }
    
    // Giả lập thêm xe thành công
    AppToastHelper.showSuccess(
      context,
      message: 'Thêm xe thành công!',
    );
    
    // Delay một chút để user thấy toast rồi mới đóng màn hình
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop({'created': true});
      }
    });
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
                    MyText(
                      text: 'Hình ảnh',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),
                    const SizedBox(height: 6),
                    SimpleImagePicker(
                      label: 'Ảnh xe',
                      onImageSelected: (file) => _image = file,
                      showPreview: true,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: MyButton(
                text: 'Thêm xe',
                buttonType: ButtonType.primary,
                height: 44,
                startIcon: 'assets/icons_final/add.svg',
                sizeStartIcon: const Size(20, 20),
                onPressed: _onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


