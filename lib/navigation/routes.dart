import 'package:flutter/material.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/screens/announcement/announcement_list_screen.dart';
import 'package:gara/screens/authentication/common/login_screen.dart';
import 'package:gara/screens/authentication/common/registration_wrapper_screen.dart';
import 'package:gara/screens/authentication/user_registration/user_registration_flow_screen.dart';
import 'package:gara/screens/authentication/gara_registration/gara_registration_flow_screen.dart';
import 'package:gara/screens/main/main_navigation_screen.dart';
import 'package:gara/screens/main/default_screen.dart';
import 'package:gara/screens/create_request/create_request_screen.dart';
import 'package:gara/screens/request/request_detail_screen.dart';
import 'package:gara/screens/user/user_info_screen.dart';
import 'package:gara/examples/user_info_demo.dart';
import 'package:gara/screens/user/edit_user_info_screen.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/screens/quotation/quotation_list_screen.dart';
import 'package:gara/screens/booking/booking_screen.dart';
import 'package:gara/models/request/request_service_model.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/screens/transaction/transaction_detail_screen.dart';
import 'package:gara/screens/my_car/add_car_screen.dart';
import 'package:gara/screens/my_car/edit_car_screen.dart';
import 'package:gara/screens/messaging/messages_screen.dart';
import 'package:gara/screens/messaging/chat_room_screen.dart';
import 'package:gara/widgets/fullscreen_image_viewer.dart';
import 'package:gara/screens/authentication/gara_registration/electronic_contract_page.dart';
import 'package:gara/screens/garage/garage_info_screen.dart';
import 'package:gara/screens/settings/settings_screen.dart';
import 'package:gara/screens/settings/change_password_screen.dart';
import 'package:gara/screens/authentication/forgot_password/forgot_password_phone_screen.dart';
import 'package:gara/screens/authentication/forgot_password/forgot_password_otp_screen.dart';
import 'package:gara/screens/authentication/forgot_password/forgot_password_new_password_screen.dart';

Map<String, WidgetBuilder> routes = {
  //* Initial Screen - DefaultScreen cho người dùng chưa đăng nhập
  '/': (context) => const DefaultScreen(),
  //* Main Navigation Screen (alias)
  '/home': (context) => const MainNavigationScreen(),
  //* Request Detail Screen
  '/request-detail': (context) =>
      RequestDetailScreen(item: ModalRoute.of(context)?.settings.arguments as RequestServiceModel),
  //* Fullscreen Image Viewer
  '/image-viewer': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final files = (args['files'] as List).cast<FileInfo>();
      return FullscreenImageViewer(files: files, initialIndex: (args['initialIndex'] ?? 0) as int);
    }
    return const MainNavigationScreen();
  },
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
      return QuotationListScreen(requestItem: args);
    }
    // fallback: return to home if no request data
    return const QuotationListScreen();
  },
  //* Announcement List Screen
  '/announcements': (context) => const AnnouncementListScreen(),
  //* Booking Screen
  '/booking': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is QuotationModel) {
      return BookingScreen(quotation: args);
    }
    // fallback: return to home if no quotation data
    return const MainNavigationScreen();
  },
  //* Transaction Detail Screen
  '/transaction-detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return TransactionDetailScreen(arguments: args);
  },
  //* Add Car Screen
  '/add-car': (context) => const AddCarScreen(),
  //* Edit Car Screen
  '/edit-car': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['carInfo'] != null) {
      return EditCarScreen(carInfo: args['carInfo']);
    }
    // fallback: return to home if no car data
    return const MainNavigationScreen();
  },
  //* Messages Screen
  '/messages': (context) => const MessagesScreen(),
  //* Chat Room Screen
  '/chat-room': (context) {
    return const ChatRoomScreen();
  },
  //* Electronic Contract Screen
  '/electronic-contract': (context) => ElectronicContractPage(
        onNext: () {
          // Navigate back to home after successful contract signing
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        },
        currentStep: 1,
        totalSteps: 1,
      ),
  //* Garage Info Screen
  '/garage-info': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserInfoResponse) {
      return GarageInfoScreen(garageInfo: args);
    }
    // fallback: return to home if no garage data
    return const MainNavigationScreen();
  },
  //* Settings Screen
  '/settings': (context) => const SettingsScreen(),
  //* Change Password Screen
  '/change-password': (context) => const ChangePasswordScreen(),
  //* Forgot Password Flow
  '/forgot-password/phone': (context) => const ForgotPasswordPhoneScreen(),
  '/forgot-password/otp': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final phone = (args is Map) ? args['phone'] as String? : null;
    return ForgotPasswordOtpScreen(phone: phone ?? '');
  },
  '/forgot-password/new-password': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final token = (args is Map) ? args['reset_token'] as String? : null;
    return ForgotPasswordNewPasswordScreen(resetToken: token ?? '');
  },
};
