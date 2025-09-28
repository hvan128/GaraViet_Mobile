import 'package:flutter/material.dart';
import 'package:gara/services/auth/jwt_token_manager.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/providers/user_provider.dart';

class AuthStateManager extends ChangeNotifier {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  bool _isLoggedIn = false;
  String? _userPhone;
  String? _userName;
  String? _userAvatar;

  bool get isLoggedIn => _isLoggedIn;
  String? get userPhone => _userPhone;
  String? get userName => _userName;
  String? get userAvatar => _userAvatar;

  // Initialize auth state when app starts
  Future<void> initialize() async {
    print('🔐 [AuthStateManager] initialize() called');
    await _checkAuthState();
    print('🔐 [AuthStateManager] initialize() completed, isLoggedIn: $_isLoggedIn');
  }

  // Check if user is logged in by checking token validity
  Future<void> _checkAuthState() async {
    print('🔐 [AuthStateManager] _checkAuthState() started');
    
    try {
      // Check TokenCache first (memory)
      final tokenFromCache = TokenCache.getAccessToken();
      print('🔐 [AuthStateManager] Token from cache: ${tokenFromCache != null ? "EXISTS" : "NULL"}');
      
      if (tokenFromCache != null) {
        print('🔐 [AuthStateManager] Token exists in memory, checking validity...');
        // Token exists in memory, check if valid
        final isValid = await JwtTokenManager.isTokenValid(tokenFromCache);
        print('🔐 [AuthStateManager] Token validity: $isValid');
        
        if (isValid) {
          print('🔐 [AuthStateManager] Token is valid, setting logged in state');
          _isLoggedIn = true;
          _userPhone = await Storage.getItem('saved_phone');
          _userName = await Storage.getItem('user_name');
          _userAvatar = await Storage.getItem('user_avatar');
          
          // Kiểm tra nếu thông tin user null thì gọi API
          if (_userName == null || _userPhone == null) {
            await loadUserInfo();
          }
        } else {
          print('🔐 [AuthStateManager] Token expired, attempting refresh...');
          // Token expired, try to refresh
          final refreshSuccess = await JwtTokenManager.refreshTokenIfNeeded();
          print('🔐 [AuthStateManager] Refresh result: $refreshSuccess');
          
          if (refreshSuccess) {
            print('🔐 [AuthStateManager] Refresh successful, setting logged in state');
            _isLoggedIn = true;
            _userPhone = await Storage.getItem('saved_phone');
            _userName = await Storage.getItem('user_name');
            _userAvatar = await Storage.getItem('user_avatar');
            
            // Kiểm tra nếu thông tin user null thì gọi API
            if (_userName == null || _userPhone == null) {
              await loadUserInfo();
            }
          } else {
            print('🔐 [AuthStateManager] Refresh failed, clearing auth state');
            await _clearAuthState();
          }
        }
      } else {
        print('🔐 [AuthStateManager] No token in memory, checking storage for refresh token...');
        // No token in memory, check if we can refresh from storage
        final refreshToken = await Storage.getRefreshToken();
        print('🔐 [AuthStateManager] Refresh token from storage: ${refreshToken != null ? "EXISTS" : "NULL"}');
        
        if (refreshToken != null) {
          print('🔐 [AuthStateManager] Found refresh token, attempting refresh...');
          final refreshSuccess = await JwtTokenManager.refreshTokenIfNeeded();
          print('🔐 [AuthStateManager] Refresh result: $refreshSuccess');
          
          if (refreshSuccess) {
            print('🔐 [AuthStateManager] Refresh successful, setting logged in state');
            _isLoggedIn = true;
            _userPhone = await Storage.getItem('saved_phone');
            _userName = await Storage.getItem('user_name');
            _userAvatar = await Storage.getItem('user_avatar');
            
            // Kiểm tra nếu thông tin user null thì gọi API
            if (_userName == null || _userPhone == null) {
              await loadUserInfo();
            }
          } else {
            print('🔐 [AuthStateManager] Refresh failed, clearing auth state');
            await _clearAuthState();
          }
        } else {
          print('🔐 [AuthStateManager] No refresh token found, user not logged in');
          _isLoggedIn = false;
        }
      }
    } catch (e) {
      print('🔐 [AuthStateManager] EXCEPTION in _checkAuthState: $e');
      print('🔐 [AuthStateManager] Exception type: ${e.runtimeType}');
      // Error checking auth state, assume not logged in
      _isLoggedIn = false;
    }
    
    print('🔐 [AuthStateManager] _checkAuthState() completed, final isLoggedIn: $_isLoggedIn');
    notifyListeners();
  }

  // Set logged in state after successful login
  Future<void> setLoggedIn({
    required String phone,
    String? name,
    String? avatar,
  }) async {
    _isLoggedIn = true;
    _userPhone = phone;
    _userName = name;
    _userAvatar = avatar;
    
    // Save user info
    await Storage.setItem('saved_phone', phone);
    if (name != null) {
      await Storage.setItem('user_name', name);
    }
    if (avatar != null) {
      await Storage.setItem('user_avatar', avatar);
    }
    
    notifyListeners();
  }

  // Clear auth state after logout
  Future<void> setLoggedOut() async {
    _isLoggedIn = false;
    _userPhone = null;
    _userName = null;
    _userAvatar = null;
    
    // Clear stored user info
    await Storage.setItem('saved_phone', null);
    await Storage.setItem('user_name', null);
    await Storage.setItem('user_avatar', null);
    
    notifyListeners();
  }

  // Clear auth state (internal method)
  Future<void> _clearAuthState() async {
    _isLoggedIn = false;
    _userPhone = null;
    _userName = null;
    _userAvatar = null;
    notifyListeners();
  }

  // Refresh auth state (useful when token is refreshed)
  Future<void> refreshAuthState() async {
    await _checkAuthState();
  }

  // Load user info from API
  Future<void> loadUserInfo() async {
    if (!_isLoggedIn) {
      return;
    }
    
    // Kiểm tra nếu đã có thông tin user thì không cần gọi API lại
    if (_userName != null && _userName!.isNotEmpty && _userPhone != null && _userPhone!.isNotEmpty) {
      return;
    }
    
    try {
      final userProvider = UserProvider();
      await userProvider.initializeUserInfo();
      final userInfo = userProvider.userInfo;
      
      if (userInfo != null) {
        _userName = userInfo.name;
        _userPhone = userInfo.phone; // Cập nhật phone từ API
        _userAvatar = userInfo.avatar;
        
        // Save to storage
        await Storage.setItem('user_name', userInfo.name);
        await Storage.setItem('saved_phone', userInfo.phone);
        if (userInfo.avatar != null) {
          await Storage.setItem('user_avatar', userInfo.avatar!);
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('💥 Error loading user info: $e');
    }
  }
}
