import 'package:flutter/material.dart';
import 'package:gara/services/error_handler.dart';

class DebugDialog {
  // Hiển thị dialog debug với thông tin chi tiết
  static void show(BuildContext context, dynamic error, {String? title}) {
    if (!ErrorHandler.debugMode || error == null) return;
    
    try {
      final errorDetails = ErrorHandler.getErrorDetails(error);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Debug Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error Details:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Type: ${errorDetails['type']}'),
                Text('Code: ${errorDetails['code']}'),
                Text('Time: ${errorDetails['timestamp']}'),
                Text('Connection Error: ${errorDetails['isConnectionError']}'),
                Text('Auth Error: ${errorDetails['isAuthError']}'),
                const SizedBox(height: 16),
                Text(
                  'Full Error:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                // Copy error details to clipboard
                // TODO: Implement clipboard functionality
                Navigator.of(context).pop();
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
    } catch (e) {
      // Fallback nếu có lỗi khi xử lý debug info
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title ?? 'Debug Error'),
            content: Text('Không thể hiển thị thông tin debug: $e'),
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
  }
  
  // Hiển thị bottom sheet debug
  static void showBottomSheet(BuildContext context, dynamic error, {String? title}) {
    if (!ErrorHandler.debugMode || error == null) return;
    
    try {
      final errorDetails = ErrorHandler.getErrorDetails(error);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'Debug Information',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text('Type: ${errorDetails['type']}'),
              Text('Code: ${errorDetails['code']}'),
              Text('Time: ${errorDetails['timestamp']}'),
              Text('Connection Error: ${errorDetails['isConnectionError']}'),
              Text('Auth Error: ${errorDetails['isAuthError']}'),
              const SizedBox(height: 16),
              Text(
                'Full Error:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  error.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
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
    } catch (e) {
      // Fallback nếu có lỗi khi xử lý debug info
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Debug Error: $e'),
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
  
  // Hiển thị debug info trong snackbar
  static void showSnackBar(BuildContext context, dynamic error) {
    if (!ErrorHandler.debugMode || error == null) return;
    
    try {
      final errorDetails = ErrorHandler.getErrorDetails(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Debug: ${errorDetails['type']} - ${errorDetails['code']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            show(context, error);
          },
        ),
      ),
    );
    } catch (e) {
      // Fallback nếu có lỗi khi xử lý debug info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug Error: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
