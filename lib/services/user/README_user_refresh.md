# User Refresh Service

## Tổng quan

UserRefreshService là một service tự động cập nhật thông tin user từ API mà không cần đăng xuất/đăng nhập lại. Service này giải quyết vấn đề khi admin thay đổi trạng thái user (active/inactive) từ phía server.

## Tính năng

- **Auto-refresh định kỳ**: Tự động refresh user info mỗi 5 phút
- **Quick refresh**: Refresh nhanh khi app trở lại active (30 giây)
- **Force refresh**: Refresh thủ công khi cần thiết
- **App lifecycle**: Tự động pause/resume khi app chuyển trạng thái
- **Pull-to-refresh**: Hỗ trợ kéo xuống để refresh

## Cách sử dụng

### 1. Khởi tạo (đã được tích hợp trong main.dart)

```dart
// Service đã được khởi tạo tự động trong main.dart
UserRefreshService.initialize();
AppLifecycleService().initialize();
```

### 2. Sử dụng trong màn hình

```dart
import 'package:gara/services/user/user_refresh_service.dart';
import 'package:gara/widgets/user_refresh_indicator.dart';

class MyScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Trigger quick refresh khi màn hình load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserRefreshService.quickRefresh();
    });
  }

  Future<void> _handleRefresh() async {
    // Force refresh user info
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.forceRefreshUserInfo();
    
    // Also trigger service refresh
    await UserRefreshService.forceRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: UserRefreshIndicator(
          onRefresh: _handleRefresh,
          child: YourContent(),
        ),
      ),
    );
  }
}
```

### 3. Sử dụng UserProvider

```dart
// Force refresh user info
final userProvider = Provider.of<UserProvider>(context, listen: false);
final success = await userProvider.forceRefreshUserInfo();

if (success) {
  // User info đã được cập nhật
  print('User info updated successfully');
}
```

### 4. Kiểm tra trạng thái

```dart
// Kiểm tra đang refresh
bool isRefreshing = UserRefreshService.isRefreshing;

// Kiểm tra lần refresh cuối
DateTime? lastRefresh = UserRefreshService.lastRefreshTime;

// Kiểm tra app đang active
bool isAppActive = UserRefreshService.isAppActive;
```

## Cấu hình

### Thời gian refresh

```dart
// Trong user_refresh_service.dart
static const Duration _refreshInterval = Duration(minutes: 5); // Auto refresh
static const Duration _quickRefreshInterval = Duration(seconds: 30); // Quick refresh
```

### Tùy chỉnh

Bạn có thể thay đổi thời gian refresh bằng cách sửa các constant trong `UserRefreshService`:

```dart
// Thay đổi thời gian auto refresh
static const Duration _refreshInterval = Duration(minutes: 10); // 10 phút

// Thay đổi thời gian quick refresh
static const Duration _quickRefreshInterval = Duration(minutes: 1); // 1 phút
```

## Lưu ý

1. **Network**: Service chỉ hoạt động khi có kết nối mạng
2. **Performance**: Auto refresh chỉ chạy khi app đang active
3. **Battery**: Service được tối ưu để tiết kiệm pin
4. **Error handling**: Service tự động xử lý lỗi và retry

## Troubleshooting

### Service không hoạt động

1. Kiểm tra xem service đã được khởi tạo chưa
2. Kiểm tra kết nối mạng
3. Kiểm tra access token còn hợp lệ không

### User info không cập nhật

1. Kiểm tra API endpoint có hoạt động không
2. Kiểm tra response format từ API
3. Kiểm tra UserProvider có được notify đúng không

### Debug

```dart
// Bật debug mode để xem log
debugPrint('[UserRefreshService] Debug logs enabled');
```

## Ví dụ hoàn chỉnh

Xem file `lib/examples/user_refresh_example.dart` để có ví dụ hoàn chỉnh về cách sử dụng service này.
