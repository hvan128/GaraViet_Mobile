import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/widgets/progress_bar.dart';
import 'package:gara/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/widgets/header.dart';

class RegistrationSuccessPage extends StatefulWidget {
  const RegistrationSuccessPage({super.key});

  @override
  State<RegistrationSuccessPage> createState() => _RegistrationSuccessPageState();
}

class _RegistrationSuccessPageState extends State<RegistrationSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Mark registration as complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationData = Provider.of<RegistrationData>(context, listen: false);
      registrationData.setRegistrationComplete(true);
    });
  }

  void _navigateToLogin() {
    // Clear registration data
    final registrationData = Provider.of<RegistrationData>(context, listen: false);
    registrationData.clear();
    
    // Navigate to login screen
    Navigate.pushNamedAndRemoveUntil('/login', '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            MyHeader(
              showLeftButton: false, // Không hiển thị nút back
            ),
            StepProgressBar(
              currentStep: 4,
              totalSteps: 4,
              height: 1.0,
              fullWidth: true,
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconField(svgPath: "assets/icons_final/Check.svg"),
                    const SizedBox(height: 12),

                    // Success Icon
                    MyText(
                      text: 'Đăng ký thành công',
                      textStyle: 'head',
                      textSize: '24',
                      textColor: 'primary',
                    ),
                    
                    const SizedBox(height: 4),

                    MyText(
                      text: 'Giờ bạn đã có thể đăng nhập băng tài khoản vừa tạo.',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),

                    const SizedBox(height: 32),
                    
                    // Login Button
                    MyButton(
                      text: 'Đăng nhập',
                      onPressed: _navigateToLogin,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}