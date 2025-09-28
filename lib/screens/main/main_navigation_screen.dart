import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gara/screens/home/home_screen.dart';
import 'package:gara/screens/request/request_screen.dart';
import 'package:gara/screens/schedule/schedule_screen.dart';
import 'package:gara/screens/messages/messages_screen.dart';
import 'package:gara/screens/my_car/my_car_screen.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/theme/effects.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra arguments để set tab được chọn
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('selectedTab')) {
      final selectedTab = args['selectedTab'] as int?;
      if (selectedTab != null && selectedTab >= 0 && selectedTab < _screens.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentIndex = selectedTab;
            });
          }
        });
      }
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const RequestScreen(),
    const ScheduleScreen(),
    const MessagesScreen(),
    const MyCarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Nội dung màn hình hiển thị đầy đủ
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Bottom navigation nổi lên trên
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(100)),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: DesignTokens.surfacePrimary,
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    border: Border.all(
                      color: DesignTokens.borderBrandSecondary,
                      width: 1,
                    ),
                    boxShadow: [
                      DesignEffects.largeCard,
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: 'assets/icons_final/home.svg',
                        label: 'Trang chủ',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: 'assets/icons_final/document-text.svg',
                        label: 'Yêu cầu',
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: 'assets/icons_final/calendar.svg',
                        label: 'Lịch',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: 'assets/icons_final/message-text.svg',
                        label: 'tin nhắn',
                        index: 3,
                      ),
                      _buildNavItem(
                        icon: 'assets/icons_final/car.svg',
                        label: 'Xe bạn',
                        index: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(
              svgPath: icon,
              size: 24,
              color: isActive ? DesignTokens.textBrand : DesignTokens.textPlaceholder,
            ),
            const SizedBox(height: 4),
            MyText(
              text: label,
              textStyle: 'title',
              textSize: '12',
              textColor: isActive ? 'brand' : 'placeholder',
            ),
          ],
        ),
      ),
    );
  }
}
