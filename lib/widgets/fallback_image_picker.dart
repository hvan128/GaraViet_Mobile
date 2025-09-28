import 'dart:io';
import 'package:flutter/material.dart';

class FallbackImagePicker extends StatefulWidget {
  final String label;
  final Function(File?) onImageSelected;
  final File? initialImage;

  const FallbackImagePicker({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.initialImage,
  });

  @override
  State<FallbackImagePicker> createState() => _FallbackImagePickerState();
}

class _FallbackImagePickerState extends State<FallbackImagePicker> {
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  void _showNotSupportedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tính năng chưa khả dụng'),
          content: const Text(
            'Tính năng chọn ảnh hiện tại chưa khả dụng trên platform này. '
            'Vui lòng thử lại sau hoặc liên hệ hỗ trợ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showNotSupportedDialog,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: _selectedImage != null ? Colors.grey[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedImage != null ? Colors.blue[300]! : Colors.grey[300]!,
            width: _selectedImage != null ? 2 : 1,
          ),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
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
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: Colors.grey[500],
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(Chưa khả dụng)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
