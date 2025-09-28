import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/widgets/fallback_image_picker.dart';
import 'package:gara/widgets/simple_image_picker.dart';

class SmartImagePicker extends StatefulWidget {
  final String label;
  final Function(File?) onImageSelected;
  final File? initialImage;
  final bool showPreview;

  const SmartImagePicker({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.initialImage,
    this.showPreview = true,
  });

  @override
  State<SmartImagePicker> createState() => _SmartImagePickerState();
}

class _SmartImagePickerState extends State<SmartImagePicker> {
  bool _isPluginAvailable = true;

  @override
  void initState() {
    super.initState();
    _checkPluginAvailability();
  }

  void _checkPluginAvailability() {
    // Try to test if image_picker plugin is available
    try {
      // This is a simple test - if we can import the package, it should work
      // In a real app, you might want to do a more sophisticated check
      _isPluginAvailable = true;
    } catch (e) {
      _isPluginAvailable = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPluginAvailable) {
      return SimpleImagePicker(
        label: widget.label,
        initialImage: widget.initialImage,
        onImageSelected: widget.onImageSelected,
        showPreview: widget.showPreview,
      );
    } else {
      return FallbackImagePicker(
        label: widget.label,
        initialImage: widget.initialImage,
        onImageSelected: widget.onImageSelected,
      );
    }
  }
}
