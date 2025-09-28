# Hệ thống Debug cho Error Handling

## Tổng quan
Hệ thống debug được thiết kế để giúp developer dễ dàng debug lỗi trong quá trình phát triển ứng dụng.

## Các thành phần chính

### 1. ErrorHandler với Debug Mode
- **Debug Mode**: Bật/tắt hiển thị mã lỗi trong thông báo
- **Logging**: Tự động log chi tiết lỗi vào console
- **Error Code**: Tạo mã lỗi duy nhất cho mỗi lỗi

### 2. DebugHelper
- **API Logging**: Log tất cả API calls và responses
- **Error Logging**: Log lỗi với context chi tiết
- **State Logging**: Log state changes
- **User Action Logging**: Log user interactions

### 3. DebugDialog
- **Debug Dialog**: Hiển thị thông tin lỗi chi tiết trong UI
- **Debug SnackBar**: Hiển thị mã lỗi trong snackbar
- **Debug BottomSheet**: Hiển thị thông tin debug trong bottom sheet

## Cách sử dụng

### 1. Bật/Tắt Debug Mode
```dart
// Bật debug mode
ErrorHandler.setDebugMode(true);

// Tắt debug mode
ErrorHandler.setDebugMode(false);

// Toggle debug mode
DebugHelper.toggleDebugMode();
```

### 2. Logging API Calls
```dart
// Trong AuthService (đã được tích hợp sẵn)
DebugHelper.logApiCall('POST', '/auth/send-otp', body: {'phone': phone});
DebugHelper.logApiResponse('/auth/send-otp', response);
```

### 3. Logging Errors
```dart
// Log lỗi với context
DebugHelper.logError('_sendInitialOtp', error);

// Log state
DebugHelper.logState('PhoneVerificationPage', {'isLoading': true, 'countdown': 60});

// Log user action
DebugHelper.logUserAction('OTP_VERIFY', {'otp': '1234'});
```

### 4. Hiển thị Debug Info trong UI
```dart
// Hiển thị debug dialog
DebugDialog.show(context, error, title: 'Debug Information');

// Hiển thị debug snackbar
DebugDialog.showSnackBar(context, error);

// Hiển thị debug bottom sheet
DebugDialog.showBottomSheet(context, error);
```

## Thông tin Debug

### 1. Error Code Format
```
SOCKETEX-1234
TIMEOUT-5678
HTTPEX-9012
```

### 2. Log Format trong Console
```
[ErrorHandler] ERROR [2024-01-15T10:30:00.000Z]
[ErrorHandler] Socket Error: Connection timed out, Address: 14.224.137.80, Port: 5009
[BaseApiService] API Error: /auth/verify-otp
[DebugHelper] Error in _verifyOtp
[DebugHelper] Error Details: {type: SocketException, code: SOCKETEX-1234, ...}
```

### 3. Debug Dialog Content
```
Error Details:
- Type: SocketException
- Code: SOCKETEX-1234
- Time: 2024-01-15T10:30:00.000Z
- Connection Error: true
- Auth Error: false

Full Error:
ClientException with SocketException: Connection timed out...
```

## Cách Debug Lỗi

### 1. Khi có lỗi xảy ra:
1. **Kiểm tra Console Logs**: Xem chi tiết lỗi trong console
2. **Kiểm tra Error Code**: Sử dụng mã lỗi để tra cứu
3. **Kiểm tra Debug SnackBar**: Xem mã lỗi trong UI
4. **Mở Debug Dialog**: Xem thông tin chi tiết

### 2. Thông tin cần thu thập:
- **Error Type**: Loại lỗi (SocketException, TimeoutException, etc.)
- **Error Code**: Mã lỗi duy nhất
- **Timestamp**: Thời gian xảy ra lỗi
- **Context**: Nơi xảy ra lỗi (method name)
- **API Endpoint**: Endpoint bị lỗi
- **Request/Response**: Dữ liệu gửi/nhận

### 3. Các loại lỗi thường gặp:

#### Connection Errors
- **SocketException**: Không thể kết nối đến server
- **TimeoutException**: Kết nối quá thời gian
- **HttpException**: Lỗi HTTP

#### API Errors
- **400 Bad Request**: Dữ liệu gửi không hợp lệ
- **401 Unauthorized**: Chưa đăng nhập hoặc token hết hạn
- **403 Forbidden**: Không có quyền truy cập
- **404 Not Found**: API endpoint không tồn tại
- **500 Internal Server Error**: Lỗi server

#### Validation Errors
- **Input payload validation failed**: Dữ liệu gửi không đúng format
- **OTP verification failed**: Mã OTP không đúng

## Production vs Development

### Development Mode (Debug Mode = true)
- Hiển thị mã lỗi trong thông báo
- Log chi tiết vào console
- Hiển thị debug dialogs
- Hiển thị debug snackbars

### Production Mode (Debug Mode = false)
- Chỉ hiển thị thông báo thân thiện
- Không log chi tiết
- Không hiển thị debug dialogs
- Không hiển thị debug snackbars

## Best Practices

### 1. Luôn bật debug mode khi development
```dart
void main() {
  // Bật debug mode cho development
  ErrorHandler.setDebugMode(true);
  runApp(MyApp());
}
```

### 2. Tắt debug mode cho production
```dart
void main() {
  // Tắt debug mode cho production
  ErrorHandler.setDebugMode(false);
  runApp(MyApp());
}
```

### 3. Sử dụng logging một cách hợp lý
- Log API calls quan trọng
- Log errors với context rõ ràng
- Không log thông tin nhạy cảm

### 4. Sử dụng error codes để tracking
- Mỗi lỗi có mã duy nhất
- Dễ dàng tra cứu và fix
- Có thể tracking lỗi theo thời gian

## Ví dụ thực tế

### Trước khi có debug system:
```
User thấy: "Không thể kết nối đến server"
Developer: Không biết lỗi gì, ở đâu, khi nào
```

### Sau khi có debug system:
```
User thấy: "Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng. [ERR-SOCKETEX-1234]"

Console logs:
[ErrorHandler] ERROR [2024-01-15T10:30:00.000Z]
[ErrorHandler] Socket Error: Connection timed out, Address: 14.224.137.80, Port: 5009
[BaseApiService] API Error: /auth/verify-otp
[DebugHelper] Error in _verifyOtp

Developer biết:
- Lỗi: SocketException
- Mã lỗi: SOCKETEX-1234
- Thời gian: 2024-01-15T10:30:00.000Z
- Context: _verifyOtp method
- API: /auth/verify-otp
- Chi tiết: Connection timed out to 14.224.137.80:5009
```
