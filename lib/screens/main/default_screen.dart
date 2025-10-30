import 'package:flutter/material.dart';
import 'package:gara/screens/home/home_screen.dart';
import 'package:gara/screens/main/main_navigation_screen.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Màn hình mặc định - kiểm tra trạng thái đăng nhập và hiển thị màn hình phù hợp
class DefaultScreen extends StatelessWidget {
  const DefaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isLoggedIn = userProvider.isLoggedIn;

        // Nếu đã đăng nhập, chuyển đến MainNavigationScreen
        if (isLoggedIn) {
          return const MainNavigationScreen();
        }

        // Nếu chưa đăng nhập, chỉ hiển thị HomeScreen mà không có bottom navigation
        return const Scaffold(body: HomeScreen());
      },
    );
  }
}
