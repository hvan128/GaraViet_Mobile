import 'package:flutter/material.dart';
import 'package:gara/screens/authentication/common/login_screen.dart';
import 'package:gara/screens/authentication/common/registration_wrapper_screen.dart';
import 'package:gara/screens/authentication/user_registration/user_registration_flow_screen.dart';
import 'package:gara/screens/authentication/gara_registration/gara_registration_flow_screen.dart';
import 'package:gara/screens/main/main_navigation_screen.dart';
import 'package:gara/screens/create_request/create_request_screen.dart';
import 'package:gara/screens/user/user_info_screen.dart';
import 'package:gara/examples/user_info_demo.dart';
import 'package:gara/screens/user/edit_user_info_screen.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/screens/quotation/quotation_list_screen.dart';
import 'package:gara/models/request/request_service_model.dart';

Map<String, WidgetBuilder> routes = {
  //* Initial Screen
  '/': (context) => const MainNavigationScreen(),
  //* Main Navigation Screen (alias)
  '/home': (context) => const MainNavigationScreen(),
  //* Login Screen
  '/login': (context) => const LoginScreen(),
  //* Registration Wrapper Screen (New PageView structure)
  '/register': (context) => const RegistrationWrapperScreen(),
  //* User Registration Flow Screen
  '/user-register': (context) => const UserRegistrationFlowScreen(),
  //* Gara Registration Flow Screen
  '/gara-register': (context) => const GaraRegistrationFlowScreen(),
  //* Create Request Screen
  '/create-request': (context) => const CreateRequestScreen(),
  //* User Info Screen
  '/user-info': (context) => const UserInfoScreen(),
  //* Edit User Info Screen
  '/user-info/edit': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserInfoResponse) {
      return EditUserInfoScreen(userInfo: args);
    }
    // fallback: open empty screen with defaults
    return const UserInfoScreen();
  },
  //* User Info Demo
  '/user-info-demo': (context) => const UserInfoDemo(),
  //* Quotation List Screen
  '/quotation-list': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RequestServiceModel) {
      return QuotationListScreen(request: args);
    }
    // fallback: return to home if no request data
    return const MainNavigationScreen();
  },
  
};