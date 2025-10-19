# Garage Activation Notification System

## Tổng quan

Hệ thống notification cho garage activation được tích hợp vào messaging service hiện có, sử dụng Firebase Cloud Messaging để tự động cập nhật thông tin user khi admin thay đổi trạng thái garage.

## Cách hoạt động

### 1. **Firebase Notification Flow**
```
Admin thay đổi trạng thái garage
    ↓
Firebase gửi notification với payload:
{
  "type": "announcement",
  "subtype": "activatedGarage",
  "data": {...}
}
    ↓
PushNotificationService xử lý
    ↓
NavigationEventBus.emitReloadUserInfo()
    ↓
Home screen listen và force refresh user info
    ↓
Hiển thị thông báo cho user
```

### 2. **Contract Signing Flow**
```
User ký hợp đồng thành công
    ↓
Cập nhật isVerifiedGarage = 0 (chờ xác thực)
    ↓
Lưu vào UserProvider và Storage
    ↓
Điều hướng về trang chủ
```

## Cấu trúc Code

### 1. **PushNotificationService Integration**
```dart
// Trong _handleForegroundMessage()
final isActivatedGarage = subtype == 'activatedGarage' || data['subtype'] == 'activatedGarage';

if (isAnnouncement && isActivatedGarage) {
  // Xử lý garage activation notification - force refresh user info
  NavigationEventBus().emitReloadUserInfo(reason: 'announcement:activatedGarage');
}
```

### 2. **NavigationEventBus**
```dart
// Event mới cho reload user info
class ReloadUserInfoEvent {
  final String? reason;
  ReloadUserInfoEvent({this.reason});
}

// Stream và method
Stream<ReloadUserInfoEvent> get onReloadUserInfo => _reloadUserInfoController.stream;
void emitReloadUserInfo({String? reason}) { ... }
```

### 3. **Home Screen Integration**
```dart
void _setupUserInfoReloadListener() {
  NavigationEventBus().onReloadUserInfo.listen((event) async {
    if (event.reason == 'announcement:activatedGarage') {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.forceRefreshUserInfo();
      
      if (mounted) {
        _showGarageActivationNotification(userProvider);
      }
    }
  });
}
```

### 4. **Contract Signing Integration**
```dart
// Trong electronic_contract_page.dart
if (resp['success'] == true) {
  // Cập nhật isVerifiedGarage = 0 (chờ xác thực) sau khi ký hợp đồng thành công
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  if (userProvider.userInfo != null) {
    final updatedUserInfo = userProvider.userInfo!.copyWith(isVerifiedGarage: 0);
    userProvider.updateUserInfo(updatedUserInfo);
  }
  
  AppToastHelper.showSuccess(context, message: 'Ký hợp đồng thành công');
  Navigate.pushNamedAndRemoveAll('/');
}
```

## Notification Payload Format

### Garage Activation Notification
```json
{
  "type": "announcement",
  "subtype": "activatedGarage",
  "title": "Tài khoản gara đã được kích hoạt",
  "body": "Tài khoản gara của bạn đã được admin kích hoạt thành công!",
  "data": {
    "garage_id": "123",
    "status": "active",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

## isVerifiedGarage Values

- **0**: Chờ xác thực (sau khi ký hợp đồng)
- **1**: Đã được kích hoạt (admin approve)
- **2**: Bị từ chối (admin reject)

## Lợi ích

1. **Tích hợp sẵn có**: Sử dụng messaging service hiện có, không cần tạo service riêng
2. **Consistent**: Cùng pattern với `new_request` notification
3. **Real-time**: Thông tin user được cập nhật ngay lập tức
4. **No Re-login**: User không cần đăng xuất/đăng nhập lại
5. **User Experience**: Hiển thị thông báo phù hợp với trạng thái

## So sánh với Auto-refresh

| Aspect | Auto-refresh | Notification-based |
|--------|-------------|-------------------|
| **Efficiency** | ❌ Polling mỗi 5 phút | ✅ Chỉ khi có thay đổi |
| **Battery** | ❌ Tiêu tốn pin | ✅ Tiết kiệm pin |
| **Network** | ❌ Nhiều request không cần thiết | ✅ Chỉ khi cần |
| **Accuracy** | ❌ Có thể miss updates | ✅ Real-time |
| **Integration** | ❌ Service riêng biệt | ✅ Tích hợp messaging service |
| **Consistency** | ❌ Pattern khác | ✅ Cùng pattern với new_request |

## Troubleshooting

### Notification không hoạt động
1. Kiểm tra Firebase configuration
2. Kiểm tra notification payload format
3. Kiểm tra event listener setup trong home screen

### User info không cập nhật
1. Kiểm tra API endpoint
2. Kiểm tra UserProvider.forceRefreshUserInfo()
3. Kiểm tra Storage operations

### Contract signing không cập nhật isVerifiedGarage
1. Kiểm tra copyWith method trong UserInfoModel
2. Kiểm tra UserProvider.updateUserInfo()
3. Kiểm tra logic trong electronic_contract_page.dart

## Debug

```dart
// Enable debug logs
debugPrint('[PushNotificationService] Processing garage activation notification');
debugPrint('[UserProvider] Force refresh successful: ${userInfo.name}');
debugPrint('[NavigationEventBus] Emitting reload user info: $reason');
```

## Tích hợp vào App

Hệ thống đã được tích hợp hoàn toàn vào messaging service hiện có:

1. **PushNotificationService**: Xử lý notification với type/subtype
2. **NavigationEventBus**: Emit reload user info event
3. **Home Screen**: Listen và handle events
4. **Contract Signing**: Cập nhật isVerifiedGarage

Không cần thêm service riêng biệt, tất cả đều sử dụng infrastructure hiện có!
