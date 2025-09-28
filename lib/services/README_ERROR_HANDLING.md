# Hệ thống xử lý lỗi (Error Handling System)

## Tổng quan
Hệ thống xử lý lỗi được thiết kế để cung cấp thông báo lỗi thân thiện với người dùng thay vì hiển thị các thông báo lỗi kỹ thuật phức tạp.

## Các thành phần chính

### 1. ErrorHandler Service (`lib/services/error_handler.dart`)
- **Mục đích**: Chuyển đổi lỗi kỹ thuật thành thông báo thân thiện
- **Chức năng chính**:
  - `getErrorMessage(dynamic error)`: Trả về thông báo lỗi thân thiện
  - `isConnectionError(dynamic error)`: Kiểm tra lỗi kết nối
  - `isAuthError(dynamic error)`: Kiểm tra lỗi xác thực

### 2. ErrorDialog Widget (`lib/widgets/error_dialog.dart`)
- **Mục đích**: Hiển thị lỗi dưới dạng dialog, snackbar, hoặc bottom sheet
- **Chức năng chính**:
  - `show()`: Hiển thị dialog lỗi
  - `showSnackBar()`: Hiển thị snackbar lỗi
  - `showBottomSheet()`: Hiển thị bottom sheet lỗi

## Cách sử dụng

### 1. Trong API Service
```dart
try {
  final response = await someApiCall();
  // Xử lý response
} catch (e) {
  return {
    'success': false,
    'message': ErrorHandler.getErrorMessage(e),
    'data': null,
  };
}
```

### 2. Trong UI Component
```dart
try {
  await someApiCall();
} catch (e) {
  // Hiển thị lỗi trong UI
  setState(() {
    _errorMessage = ErrorHandler.getErrorMessage(e);
  });
  
  // Hoặc hiển thị dialog
  ErrorDialog.show(context, e, title: 'Lỗi đăng ký');
}
```

### 3. Xử lý lỗi kết nối
```dart
if (ErrorHandler.isConnectionError(error)) {
  // Hiển thị thông báo lỗi kết nối
  ErrorDialog.showSnackBar(context, error);
}
```

## Các loại lỗi được xử lý

### 1. Lỗi kết nối
- **SocketException**: "Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng."
- **TimeoutException**: "Kết nối quá thời gian. Vui lòng thử lại."
- **HttpException**: "Lỗi kết nối mạng. Vui lòng thử lại sau."

### 2. Lỗi xác thực
- **Unauthorized**: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
- **Forbidden**: "Bạn không có quyền truy cập."

### 3. Lỗi server
- **500 Internal Server Error**: "Server đang gặp sự cố. Vui lòng thử lại sau."
- **404 Not Found**: "Không tìm thấy dữ liệu yêu cầu."

### 4. Lỗi validation
- **Input payload validation failed**: "Thông tin không hợp lệ. Vui lòng kiểm tra lại."
- **Invalid data**: "Dữ liệu không hợp lệ. Vui lòng thử lại."

### 5. Lỗi OTP
- **OTP verification failed**: "Mã xác thực không đúng hoặc đã hết hạn."

## Tích hợp với BaseApiService

BaseApiService đã được cập nhật để tự động sử dụng ErrorHandler:

```dart
// Trước
catch (e) {
  return {
    'success': false,
    'message': 'Lỗi kết nối: ${e.toString()}',
    'data': null,
  };
}

// Sau
catch (e) {
  return {
    'success': false,
    'message': ErrorHandler.getErrorMessage(e),
    'data': null,
    'error': e,
  };
}
```

## Lợi ích

1. **UX tốt hơn**: Người dùng nhận được thông báo lỗi dễ hiểu
2. **Bảo mật**: Không hiển thị thông tin kỹ thuật nhạy cảm
3. **Nhất quán**: Tất cả lỗi được xử lý theo cùng một cách
4. **Dễ bảo trì**: Tập trung logic xử lý lỗi ở một nơi
5. **Linh hoạt**: Dễ dàng thêm loại lỗi mới hoặc thay đổi thông báo

## Ví dụ thực tế

### Trước khi có ErrorHandler:
```
Lỗi kết nối: ClientException with SocketException: Connection timed out (OS Error: Connection timed out, errno = 110), address = 14.224.137.80, port = 45988, uri=https://14.224.137.80:5009/api/v1/auth/verify-otp
```

### Sau khi có ErrorHandler:
```
Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.
```
