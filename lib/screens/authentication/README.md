# Authentication Screens Structure

Cấu trúc thư mục authentication được tổ chức theo luồng đăng ký để dễ quản lý và hiểu rõ hơn.

## 📁 Cấu trúc thư mục

```
authentication/
├── common/                    # Các màn hình chung
│   ├── login_screen.dart
│   ├── registration_wrapper_screen.dart
│   └── user_type_selection_page.dart
├── user_registration/         # Luồng đăng ký User (Customer/Driver)
│   ├── user_registration_flow_screen.dart
│   ├── personal_information_page.dart
│   ├── vehicle_information_page.dart
│   ├── phone_verification_page.dart
│   └── registration_success_page.dart
└── gara_registration/         # Luồng đăng ký Gara
    ├── gara_registration_flow_screen.dart
    ├── garage_information_page.dart
    ├── phone_verification_page.dart
    ├── gara_registration_success_page.dart
    ├── electronic_contract_page.dart
    └── contract_signed_page.dart
```

## 🔄 Luồng đăng ký

### 1. Luồng chung
- **Login Screen**: Màn hình đăng nhập
- **Registration Wrapper**: Wrapper chính cho toàn bộ quá trình đăng ký
- **User Type Selection**: Chọn loại tài khoản (Customer/Driver/Garage)

### 2. Luồng đăng ký User (Customer/Driver)
1. **Personal Information**: Thông tin cá nhân
2. **Vehicle Information**: Thông tin xe
3. **Phone Verification**: Xác thực số điện thoại
4. **Registration Success**: Đăng ký thành công

### 3. Luồng đăng ký Gara
1. **Garage Information**: Thông tin gara
2. **Phone Verification**: Xác thực số điện thoại
3. **Registration Success**: Thông báo đăng ký thành công
4. **Electronic Contract**: Hợp đồng điện tử
5. **Contract Signed**: Ký hợp đồng thành công

## 📝 Ghi chú

- **Phone Verification**: Được sử dụng trong cả hai luồng, nên có bản sao riêng cho mỗi luồng
- **Header**: Tất cả các màn hình đều sử dụng `MyHeader` với icon `arrow-left.svg`
- **Progress Bar**: Hiển thị tiến trình đăng ký ở các màn hình có nhiều bước

## 🔧 Import Paths

Khi import các file từ thư mục authentication, sử dụng đường dẫn tương đối:

```dart
// Từ common/
import '../user_registration/user_registration_flow_screen.dart';
import '../gara_registration/gara_registration_flow_screen.dart';

// Từ user_registration/
import 'personal_information_page.dart';
import 'vehicle_information_page.dart';

// Từ gara_registration/
import 'garage_information_page.dart';
import 'electronic_contract_page.dart';
```
