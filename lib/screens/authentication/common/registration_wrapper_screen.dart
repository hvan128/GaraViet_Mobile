import 'package:flutter/material.dart';
import 'user_type_selection_page.dart';
import '../user_registration/user_registration_flow_screen.dart';
import '../gara_registration/gara_registration_flow_screen.dart';

class RegistrationWrapperScreen extends StatefulWidget {
  const RegistrationWrapperScreen({super.key});

  @override
  State<RegistrationWrapperScreen> createState() => _RegistrationWrapperScreenState();
}

class _RegistrationWrapperScreenState extends State<RegistrationWrapperScreen> {

  void _navigateToUserFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserRegistrationFlowScreen()),
    );
  }

  void _navigateToGaraFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GaraRegistrationFlowScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async {
          return true; // Cho phép thoát về màn trước
        },
        child: UserTypeSelectionPage(
          onUserSelected: _navigateToUserFlow,
          onGaraSelected: _navigateToGaraFlow,
        ),
      ),
    );
  }
}

