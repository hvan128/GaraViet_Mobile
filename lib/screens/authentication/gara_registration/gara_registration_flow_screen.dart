import 'package:flutter/material.dart';
import 'garage_account_page.dart';
import 'garage_information_page.dart';
import 'phone_verification_page.dart';
import 'gara_registration_success_page.dart';
import 'electronic_contract_page.dart';
import 'package:gara/navigation/navigation.dart';

class GaraRegistrationFlowScreen extends StatefulWidget {
  const GaraRegistrationFlowScreen({super.key});

  @override
  State<GaraRegistrationFlowScreen> createState() => _GaraRegistrationFlowScreenState();
}

class _GaraRegistrationFlowScreenState extends State<GaraRegistrationFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      GarageAccountPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 1,
        totalSteps: 6,
      ),
      GarageInformationPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 2,
        totalSteps: 6,
      ),
      PhoneVerificationPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 3,
        totalSteps: 6,
      ),
      GaraRegistrationSuccessPage(
        onNext: _nextPage,
        onBack: _previousPage,
      ),
      ElectronicContractPage(
        onNext: _nextPage,
        onBack: _previousPage,
        currentStep: 5,
        totalSteps: 6,
      ),
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
          // Ở trang thành công xác minh: hiện dialog lựa chọn
          if (_currentPage == 3) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Tiếp tục ký hợp đồng?'),
                  content: const Text('Bạn đã xác minh thành công. Bạn muốn tiếp tục đến bước ký hợp đồng ngay bây giờ?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _nextPage();
                      },
                      child: const Text('Tiếp tục'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigate.pushNamedAndRemoveAll('/');
                      },
                      child: const Text('Để sau'),
                    ),
                  ],
                );
              },
            );
            return false;
          }
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
