import 'package:flutter/material.dart';
import 'personal_information_page.dart';
import 'vehicle_information_page.dart';
import 'phone_verification_page.dart';
import 'registration_success_page.dart';

class UserRegistrationFlowScreen extends StatefulWidget {
  const UserRegistrationFlowScreen({super.key});

  @override
  State<UserRegistrationFlowScreen> createState() => _UserRegistrationFlowScreenState();
}

class _UserRegistrationFlowScreenState extends State<UserRegistrationFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      PersonalInformationPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 1,
        totalSteps: 4,
      ),
      VehicleInformationPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 2,
        totalSteps: 4,
      ),
      PhoneVerificationPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 3,
        totalSteps: 4,
      ),
      const RegistrationSuccessPage(),
    ];
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Nếu ở trang đầu tiên, quay về màn hình chọn user type
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async {
          if (_currentPage == 0) {
            return true; // Cho phép thoát nếu đang ở trang đầu tiên
          } else {
            _previousPage();
            return false; // Ngăn thoát, chỉ quay lại trang trước
          }
        },
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Ngăn vuốt
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: _pages,
        ),
      ),
    );
  }
}
