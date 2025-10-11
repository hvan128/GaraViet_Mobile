import 'package:flutter/material.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/widgets/button.dart';

class ToastDemo extends StatelessWidget {
  const ToastDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Demo AppToast Widget',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            MyButton(
              text: 'Thông báo thành công',
              buttonType: ButtonType.primary,
              onPressed: () {
                AppToastHelper.showSuccess(
                  context,
                  message: 'Thao tác đã được thực hiện thành công!',
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            MyButton(
              text: 'Thông báo lỗi',
              buttonType: ButtonType.secondary,
              onPressed: () {
                AppToastHelper.showError(
                  context,
                  message: 'Đã xảy ra lỗi, vui lòng thử lại!',
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            MyButton(
              text: 'Thông báo cảnh báo',
              buttonType: ButtonType.secondary,
              onPressed: () {
                AppToastHelper.showWarning(
                  context,
                  message: 'Cảnh báo: Dữ liệu có thể bị mất!',
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            MyButton(
              text: 'Thông báo thông tin',
              buttonType: ButtonType.secondary,
              onPressed: () {
                AppToastHelper.showInfo(
                  context,
                  message: 'Đây là thông tin hữu ích cho bạn!',
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            MyButton(
              text: 'Toast tùy chỉnh',
              buttonType: ButtonType.secondary,
              onPressed: () {
                AppToastHelper.show(
                  context,
                  message: 'Toast với thời gian hiển thị 5 giây',
                  type: AppToastType.info,
                  duration: const Duration(seconds: 5),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Cách sử dụng:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '• AppToastHelper.showSuccess() - Thông báo thành công\n'
              '• AppToastHelper.showError() - Thông báo lỗi\n'
              '• AppToastHelper.showWarning() - Thông báo cảnh báo\n'
              '• AppToastHelper.showInfo() - Thông báo thông tin\n'
              '• AppToastHelper.show() - Toast tùy chỉnh\n'
              '• AppToastHelper.hide() - Ẩn toast hiện tại',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
