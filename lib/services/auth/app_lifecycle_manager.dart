import 'package:flutter/material.dart';
import 'package:gara/services/auth/jwt_token_manager.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isInitialized = false;

  // Khởi tạo lifecycle manager
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      print('AppLifecycleManager initialized');
    }
  }

  // Hủy lifecycle manager
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      print('AppLifecycleManager disposed');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - checking token status');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App paused');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }

  // Xử lý khi app resume
  Future<void> _handleAppResumed() async {
    try {
      await JwtTokenManager.handleAppResume();
    } catch (e) {
      print('Error handling app resume: $e');
    }
  }
}
