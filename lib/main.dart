import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gara/navigation/routes.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/auth/auth_initializer.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/providers/user_provider.dart';

void main() async {
  print('🚀 [MAIN] App starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình SSL để bỏ qua certificate verification cho development
  HttpOverrides.global = MyHttpOverrides();
  print('🚀 [MAIN] SSL overrides configured');

  Storage.newDeviceID();
  print('🚀 [MAIN] Device ID initialized');
  
  // Khởi tạo hệ thống authentication
  print('🚀 [MAIN] Starting authentication initialization...');
  await AuthInitializer.initialize();
  print('🚀 [MAIN] Authentication initialization completed');
  
  print('🚀 [MAIN] Starting app...');
  runApp(const MyApp());
}

// Custom HttpOverrides để bỏ qua SSL certificate verification
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('🔒 SSL Certificate bypassed for $host:$port');
        return true; // Bỏ qua certificate verification
      };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RegistrationData()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Gara App',
        navigatorKey: Navigate().navigationKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routes: routes,
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

