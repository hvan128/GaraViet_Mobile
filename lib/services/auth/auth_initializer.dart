import 'package:gara/services/auth/jwt_token_manager.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/services/auth/app_lifecycle_manager.dart';
import 'package:gara/providers/user_provider.dart';

class AuthInitializer {
  // Khởi tạo hệ thống authentication khi app khởi động
  static Future<void> initialize() async {
    print('🚀 [AuthInitializer] initialize() started');
    
    try {
      // Khởi tạo AppLifecycleManager
      print('🚀 [AuthInitializer] Initializing AppLifecycleManager...');
      AppLifecycleManager().initialize();
      
      // AuthStateManager đã được xóa, sử dụng UserProvider
      print('🚀 [AuthInitializer] Using UserProvider for user state management');
      
      // Kiểm tra xem có refresh token không (access token lưu trong memory)
      print('🚀 [AuthInitializer] Checking for existing refresh token...');
      final refreshToken = await Storage.getRefreshToken();
      print('🚀 [AuthInitializer] Refresh token exists: ${refreshToken != null}');
      
      if (refreshToken != null) {
        // Nếu có refresh token, khởi tạo refresh timer
        print('🚀 [AuthInitializer] Found refresh token, initializing token refresh...');
        await JwtTokenManager.initializeTokenRefresh();
        
        // Khởi tạo UserProvider với thông tin user
        print('🚀 [AuthInitializer] Initializing UserProvider...');
        await UserProvider().initializeUserInfo();
        
        print('🚀 [AuthInitializer] Authentication system initialized with existing refresh token');
      } else {
        print('🚀 [AuthInitializer] No existing refresh token found, authentication system ready');
      }
    } catch (e) {
      print('🚀 [AuthInitializer] EXCEPTION during initialization: $e');
      print('🚀 [AuthInitializer] Exception type: ${e.runtimeType}');
      // Nếu có lỗi, xóa token để đảm bảo app hoạt động bình thường
      await JwtTokenManager.clearTokens();
    }
    
    print('🚀 [AuthInitializer] initialize() completed');
  }

  // Khởi tạo lại khi user đăng nhập
  static Future<void> reinitializeAfterLogin() async {
    await JwtTokenManager.initializeTokenRefresh();
    await UserProvider().initializeUserInfo();
  }

  // Dọn dẹp khi user đăng xuất
  static Future<void> cleanup() async {
    await JwtTokenManager.clearTokens();
    UserProvider().clearUserInfo();
  }
}
