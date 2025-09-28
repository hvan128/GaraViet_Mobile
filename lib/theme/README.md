# Theme System

Hệ thống theme của ứng dụng Gara được tổ chức theo design tokens từ Figma.

## Cấu trúc thư mục

```
lib/theme/
├── index.dart          # Export tất cả theme components
├── color.dart          # Colors và text colors
├── typography.dart     # Typography styles
└── README.md          # Hướng dẫn sử dụng
```

## Colors

### Primary Colors
- `MyColors.primary['blue']` - Màu chính (#006FFD)
- `MyColors.primary['blue2']` - Màu xanh 2 (#2897FF)
- `MyColors.primary['blue3']` - Màu xanh 3 (#B4DBFF)
- `MyColors.primary['blue4']` - Màu xanh 4 (#EAF2FF)

### Secondary Colors
- `MyColors.secondary['green']` - Xanh lá (#6CD185)
- `MyColors.secondary['yellow']` - Vàng (#FFDA00)
- `MyColors.secondary['orange']` - Cam (#FC7D5D)

### Gray Scale
- `MyColors.gray['50']` đến `MyColors.gray['900']` - Thang màu xám

### Text Colors
- `MyColors.text['primary']` - Màu chính (#171717)
- `MyColors.text['brand']` - Màu thương hiệu (#006FFD)
- `MyColors.text['secondary']` - Màu thứ cấp (#404040)
- `MyColors.text['tertiary']` - Màu phụ (#737373)
- `MyColors.text['placeholder']` - Màu placeholder (#A3A3A3)
- `MyColors.text['disable']` - Màu vô hiệu hóa (#D4D4D4)
- `MyColors.text['error']` - Màu lỗi (#ED544E)
- `MyColors.text['success']` - Màu thành công (#17B26A)
- `MyColors.text['warning']` - Màu cảnh báo (#F79009)

### Alert Colors
- `MyColors.alerts['success']` - Thành công (#17B26A)
- `MyColors.alerts['warning']` - Cảnh báo (#F79009)
- `MyColors.alerts['error']` - Lỗi (#ED544E)

## Typography

### Font Family
Sử dụng font **Manrope** với các weight:
- 200 - ExtraLight
- 300 - Light
- 400 - Regular
- 500 - Medium
- 600 - SemiBold
- 700 - Bold
- 800 - ExtraBold

### Typography Styles

#### Body (FontWeight: 400)
- `MyTypography.typography['body']['12']` - 12px
- `MyTypography.typography['body']['14']` - 14px
- `MyTypography.typography['body']['16']` - 16px
- `MyTypography.typography['body']['18']` - 18px

#### Label (FontWeight: 500)
- `MyTypography.typography['label']['12']` - 12px
- `MyTypography.typography['label']['14']` - 14px
- `MyTypography.typography['label']['16']` - 16px
- `MyTypography.typography['label']['18']` - 18px

#### Title (FontWeight: 600)
- `MyTypography.typography['title']['12']` - 12px
- `MyTypography.typography['title']['14']` - 14px
- `MyTypography.typography['title']['16']` - 16px
- `MyTypography.typography['title']['18']` - 18px
- `MyTypography.typography['title']['24']` - 24px

#### Head (FontWeight: 700)
- `MyTypography.typography['head']['12']` - 12px
- `MyTypography.typography['head']['14']` - 14px
- `MyTypography.typography['head']['16']` - 16px
- `MyTypography.typography['head']['18']` - 18px
- `MyTypography.typography['head']['24']` - 24px
- `MyTypography.typography['head']['32']` - 32px

### Convenience Methods
- `MyTypography.getStyle(style, size)` - Lấy style theo tên và size
- `MyTypography.heading1` - Predefined heading1 style
- `MyTypography.body1` - Predefined body1 style
- etc.

## Cách sử dụng

### Import
```dart
import 'package:gara/theme/index.dart';
```

### Sử dụng MyText widget
```dart
MyText(
  text: 'Hello World',
  textStyle: 'head',    // body, label, title, head
  textSize: '18',       // 12, 14, 16, 18, 24, 32
  textColor: 'primary', // primary, brand, secondary, etc.
)

// Hoặc sử dụng màu tùy chỉnh
MyText(
  text: 'Custom Color',
  textStyle: 'body',
  textSize: '16',
  color: Colors.red, // Override textColor
)
```

### Sử dụng trực tiếp
```dart
Text(
  'Hello World',
  style: MyTypography.heading1.copyWith(
    color: MyColors.text['primary'],
  ),
)
```

## Font Files

Fonts được lưu trong `assets/fonts/`:
- Manrope-ExtraLight.ttf (200)
- Manrope-Light.ttf (300)
- Manrope-Regular.ttf (400)
- Manrope-Medium.ttf (500)
- Manrope-SemiBold.ttf (600)
- Manrope-Bold.ttf (700)
- Manrope-ExtraBold.ttf (800)

## Demo

Xem `lib/examples/font_demo.dart` và `lib/examples/text_style_demo.dart` để tham khảo cách sử dụng.
