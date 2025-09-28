import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/widgets/header.dart';

class ContractSignedPage extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const ContractSignedPage({
    super.key,
    this.onNext,
    this.onBack,
  });

  @override
  State<ContractSignedPage> createState() => _ContractSignedPageState();
}

class _ContractSignedPageState extends State<ContractSignedPage> {
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
              title: 'Ký hợp đồng thành công',
              showLeftButton: false, // Không hiển thị nút back
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green[200]!,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in,
                        size: 80,
                        color: Colors.green[600],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Success Title
                    Text(
                      'Hoàn thành!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Success Message
                    Text(
                      'Hợp đồng đã được ký thành công',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Tài khoản gara của bạn đã được tạo và sẵn sàng sử dụng',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Login Button
                    MyButton(
                      text: 'Đăng nhập ngay',
                      onPressed: _navigateToLogin,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Additional Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Thông tin quan trọng',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Tài khoản của bạn đang chờ xét duyệt\n• Bạn sẽ nhận được thông báo khi được phê duyệt\n• Vui lòng kiểm tra email để biết thêm chi tiết',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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