# 🔍 Hướng dẫn Debug Firebase Notification khi App Terminated

## 📋 **Các bước test và debug**

### **1. Chuẩn bị môi trường test**

```bash
# Build app với debug logging
flutter clean
flutter pub get
flutter build apk --debug

# Install app
adb install build/app/outputs/flutter-apk/app-debug.apk

# Bật logcat để xem logs
adb logcat -s flutter
```

### **2. Test scenario cơ bản**

#### **Bước 1: Test khi app đang chạy**
1. Mở app
2. Gửi notification từ Firebase Console
3. Kiểm tra logs:
   ```bash
   adb logcat | grep "PushNotificationService\|FCM\|GARA"
   ```
4. Xác nhận notification hiển thị

#### **Bước 2: Test khi app ở background**
1. Đưa app về background (không terminate)
2. Gửi notification
3. Kiểm tra notification có hiển thị không
4. Tap vào notification, kiểm tra app có mở đúng không

#### **Bước 3: Test khi app terminated**
1. **Terminate app hoàn toàn:**
   ```bash
   # Swipe app khỏi recent apps hoặc
   adb shell am force-stop com.garageviet.dev
   ```
2. Gửi notification từ Firebase Console
3. **Kiểm tra notification có hiển thị không**
4. **Tap vào notification**
5. **Kiểm tra logs khi app mở lại:**
   ```bash
   adb logcat | grep "Initial Message\|terminated_opened_by_notification"
   ```

### **3. Debug logs quan trọng**

#### **Khi app khởi động:**
```
🔍 Checking for initial message (app started from terminated state)...
📱 App was opened from terminated state by notification!
```

#### **Khi nhận notification:**
```
📨 Received foreground message: [message_id]
🔔 Foreground chat message for current room -> emit event, skip local notification
```

#### **Khi tap notification:**
```
👆 Notification tapped: [message_id]
📱 Processing notification tap with data: {...}
```

### **4. Test với Firebase Console**

#### **Cấu hình notification:**
```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This is a test message"
  },
  "data": {
    "type": "test",
    "room_id": "123",
    "sender_name": "Test User"
  }
}
```

#### **Cấu hình Advanced Options:**
- **Android**: 
  - Channel ID: `gara_notifications`
  - Priority: `High`
  - Sound: `Default`
- **iOS**:
  - Sound: `Default`
  - Badge: `1`

### **5. Debug với ADB Commands**

#### **Kiểm tra notification channels:**
```bash
adb shell dumpsys notification | grep -A 10 "gara_notifications"
```

#### **Kiểm tra app permissions:**
```bash
adb shell dumpsys package com.garageviet.dev | grep -i permission
```

#### **Kiểm tra FCM token:**
```bash
adb logcat | grep "FCM Token"
```

#### **Clear notification history:**
```bash
adb shell pm clear com.garageviet.dev
```

### **6. Test trên thiết bị thật**

#### **Các thiết bị cần test:**
- **Samsung** (có thể có battery optimization)
- **Xiaomi** (cần enable auto-start)
- **Huawei** (cần enable background activity)
- **OnePlus** (cần disable battery optimization)

#### **Cài đặt cần kiểm tra:**
1. **Battery Optimization**: Tắt cho app
2. **Auto-start**: Bật cho app
3. **Background Activity**: Cho phép
4. **Notification Permission**: Đã cấp

### **7. Troubleshooting**

#### **Notification không hiển thị khi terminated:**
1. Kiểm tra server có gửi `notification` payload không
2. Kiểm tra `channel_id` có đúng không
3. Kiểm tra battery optimization
4. Kiểm tra notification permission

#### **App không mở khi tap notification:**
1. Kiểm tra `click_action` trong notification
2. Kiểm tra `getInitialMessage()` có hoạt động không
3. Kiểm tra navigation logic

#### **Logs không xuất hiện:**
1. Đảm bảo app được build với debug mode
2. Kiểm tra `DebugLogger` có hoạt động không
3. Kiểm tra logcat filter

### **8. Backend Debug**

#### **Kiểm tra response từ Firebase:**
```python
result = send_multicast_notification(tokens, title, body, data)
print(f"Success: {result['success_count']}/{len(tokens)}")
print(f"Debug info: {result.get('debug_info', {})}")
```

#### **Test với Postman:**
```json
POST https://fcm.googleapis.com/fcm/send
Headers:
  Authorization: key=YOUR_SERVER_KEY
  Content-Type: application/json

Body:
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "Test",
    "body": "Test message"
  },
  "data": {
    "type": "test"
  }
}
```

## 🎯 **Kết quả mong đợi**

### **✅ Thành công:**
- Notification hiển thị khi app terminated
- Tap notification mở app đúng cách
- Logs hiển thị `terminated_opened_by_notification`
- Navigation hoạt động đúng

### **❌ Thất bại:**
- Notification không hiển thị
- App không mở khi tap notification
- Logs không xuất hiện
- Navigation không hoạt động

## 📱 **Lưu ý quan trọng**

1. **Test trên thiết bị thật** - Emulator có thể không hoạt động đúng
2. **Kiểm tra battery optimization** - Có thể ngăn notification
3. **Sử dụng Firebase Console** - Để test nhanh
4. **Kiểm tra logs** - Để debug chi tiết
5. **Test nhiều thiết bị** - Mỗi hãng có cơ chế khác nhau
