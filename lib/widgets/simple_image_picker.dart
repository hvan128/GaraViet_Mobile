import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/widgets/text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/app_toast.dart';

class SimpleImagePicker extends StatefulWidget {
  final String label;
  final Function(File?) onImageSelected;
  final File? initialImage;
  final bool showPreview; // Nếu false, không hiển thị ảnh đã chọn

  const SimpleImagePicker({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.initialImage,
    this.showPreview = true,
  });

  @override
  State<SimpleImagePicker> createState() => _SimpleImagePickerState();
}

class _SimpleImagePickerState extends State<SimpleImagePicker> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  @override
  void didUpdateWidget(covariant SimpleImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage?.path != oldWidget.initialImage?.path) {
      setState(() {
        _selectedImage = widget.initialImage;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('Attempting to pick image from gallery...');
      
      // Test if plugin is available
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      print('Image picker result: ${image?.path}');
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        widget.onImageSelected(_selectedImage);
        
        if (mounted) {
          AppToastHelper.showSuccess(
            context,
            message: 'Ảnh đã được chọn thành công!',
          );
        }
      }
    } catch (e) {
      print('Error in gallery picker: $e');
      if (mounted) {
        AppToastHelper.showError(
          context,
          message: 'Lỗi khi chọn ảnh: $e',
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      print('Attempting to take photo...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      print('Camera result: ${image?.path}');
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        widget.onImageSelected(_selectedImage);
        
        if (mounted) {
          AppToastHelper.showSuccess(
            context,
            message: 'Ảnh đã được chụp thành công!',
          );
        }
      }
    } catch (e) {
      print('Error in camera: $e');
      if (mounted) {
        AppToastHelper.showError(
          context,
          message: 'Lỗi khi chụp ảnh: $e',
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const MyText(text: 'Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const MyText(text: 'Chụp ảnh mới'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const MyText(text: 'Xóa ảnh', ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImage = null;
                    });
                    widget.onImageSelected(null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: SizedBox(
        width: 80,
        height: 80,
        child: _selectedImage != null && widget.showPreview
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                            widget.onImageSelected(null);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : DottedBorder(
                color: DesignTokens.getBorderColor('brandSecondary'),
                strokeWidth: 1,
                dashPattern: const [6, 4],
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons_final/add.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
      ),
    );
  }
}
