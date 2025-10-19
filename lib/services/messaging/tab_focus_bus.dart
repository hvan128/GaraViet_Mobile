import 'package:flutter/foundation.dart';

/// Bus đơn giản để thông báo tab bottom bar đang được focus
class TabFocusBus {
  TabFocusBus._();

  static final TabFocusBus instance = TabFocusBus._();

  /// Chỉ số tab hiện tại
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  /// Tick tăng để ép phát sự kiện ngay cả khi index không đổi
  final ValueNotifier<int> focusTick = ValueNotifier<int>(0);

  void notifyFocused(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
    } else {
      // Ngay cả khi cùng index, vẫn phát lại để các listener có thể tự quyết refresh
      focusTick.value = focusTick.value + 1;
    }
  }
}


