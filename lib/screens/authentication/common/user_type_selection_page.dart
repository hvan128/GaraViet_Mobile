import 'package:flutter/material.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/button.dart';

class UserTypeSelectionPage extends StatefulWidget {
  final VoidCallback onUserSelected;
  final VoidCallback onGaraSelected;

  const UserTypeSelectionPage({
    super.key,
    required this.onUserSelected,
    required this.onGaraSelected,
  });

  @override
  State<UserTypeSelectionPage> createState() => _UserTypeSelectionPageState();
}

class _UserTypeSelectionPageState extends State<UserTypeSelectionPage> {
  UserType? _selectedUserType;

  void _selectUserType(UserType type) {
    setState(() {
      _selectedUserType = type;
    });

    // Save to provider
    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    registrationData.setSelectedUserType(type);
  }

  void _continue() {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại tài khoản'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUserType == UserType.customer) {
      widget.onUserSelected();
    } else if (_selectedUserType == UserType.garage) {
      widget.onGaraSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with back button
              MyHeader(
                title: 'Chọn loại tài khoản',
                onLeftPressed: () => Navigator.pop(context),
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Person icon
                    IconField(svgPath: "assets/icons_final/profile.svg"),

                    const SizedBox(height: 12),

                    // Title
                    MyText(
                      text: 'Bạn là...',
                      textStyle: 'head',
                      textSize: '24',
                      textColor: 'primary',
                    ),

                    const SizedBox(height: 4),

                    MyText(
                      text: 'Hãy giúp chúng tôi xác nhận bạn là.',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),

                    const SizedBox(height: 32),

                    // User Type Cards
                    Column(
                      children: [
                        // Customer Card
                        GestureDetector(
                          onTap: () => _selectUserType(UserType.customer),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(
                              top: 16,
                              bottom: 0,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.surfacePrimary,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  _selectedUserType == UserType.customer
                                      ? Border.all(
                                        color: DesignTokens.borderBrandPrimary,
                                        width: 2,
                                      )
                                      : Border.all(
                                        color: DesignTokens.borderPrimary,
                                        width: 1,
                                      ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                MyText(
                                  text: 'Khách hàng',
                                  textStyle: 'head',
                                  textSize: '16',
                                  textColor: 'brand',
                                ),
                                Image.asset(
                                  'assets/images/Businessman.png',
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Garage Card
                        GestureDetector(
                          onTap: () => _selectUserType(UserType.garage),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(
                              top: 16,
                              bottom: 0,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.surfacePrimary,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  _selectedUserType == UserType.garage
                                      ? Border.all(
                                        color: DesignTokens.borderBrandPrimary,
                                        width: 2,
                                      )
                                      : Border.all(
                                        color: DesignTokens.borderPrimary,
                                        width: 1,
                                      ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                MyText(
                                  text: 'Garage',
                                  textStyle: 'head',
                                  textSize: '16',
                                  textColor: 'brand',
                                ),

                                Image.asset(
                                  'assets/images/Garageman.png',
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Continue Button
                    MyButton(text: 'Tiếp tục', onPressed: _continue),

                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Đăng nhập ngay!',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
