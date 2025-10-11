import 'package:flutter/material.dart';
import 'package:gara/services/error_handler.dart';
import 'package:gara/widgets/app_toast.dart';

class ErrorDialog {
  // Hiển thị dialog lỗi với thông báo thân thiện
  static void show(BuildContext context, dynamic error, {String? title}) {
    final message = ErrorHandler.getErrorMessage(error);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Có lỗi xảy ra'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
  
  // Hiển thị snackbar lỗi
  static void showSnackBar(BuildContext context, dynamic error, {Color? backgroundColor}) {
    if (error == null) return;
    
    try {
      final message = ErrorHandler.getErrorMessage(error);
      AppToastHelper.showError(context, message: message);
    } catch (e) {
      AppToastHelper.showError(context, message: 'Đã xảy ra lỗi không xác định');
    }
  }
  
  // Hiển thị bottom sheet lỗi
  static void showBottomSheet(BuildContext context, dynamic error, {String? title}) {
    if (error == null) return;
    
    final message = ErrorHandler.getErrorMessage(error);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'Có lỗi xảy ra',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(message),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
