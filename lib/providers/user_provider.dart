import 'package:flutter/foundation.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/services/user/user_service.dart';

class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();
  factory UserProvider() => _instance;
  UserProvider._internal();

  UserInfoResponse? _userInfo;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserInfoResponse? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _userInfo != null;
  
  // Check if user is garage
  bool get isGarageUser {
    if (_userInfo == null) return false;
    final code = _userInfo!.roleCode.toUpperCase();
    return _userInfo!.roleId == 3 ||
        code == 'GARA' ||
        code == 'GARAGE' ||
        code.contains('GARAGE');
  }

  // Get user display name
  String get userDisplayName {
    if (_userInfo == null) return 'Người dùng';
    return isGarageUser 
        ? (_userInfo!.nameGarage ?? _userInfo!.name)
        : _userInfo!.name;
  }

  // Initialize user info (call this when app starts or user logs in)
  Future<void> initializeUserInfo() async {
    if (_userInfo != null) {
      debugPrint('[UserProvider] User info already loaded');
      return;
    }

    _setLoading(true);
    try {
      debugPrint('[UserProvider] Loading user info...');
      final userInfo = await UserService.getUserInfo();
      
      if (userInfo != null) {
        _userInfo = userInfo;
        _error = null;
        debugPrint('[UserProvider] User info loaded: ${userInfo.name}, roleId: ${userInfo.roleId}, roleCode: ${userInfo.roleCode}');
        debugPrint('[UserProvider] isGarageUser: $isGarageUser');
      } else {
        _error = 'Không thể tải thông tin người dùng';
        debugPrint('[UserProvider] User info is null');
      }
    } catch (e) {
      _error = 'Lỗi khi tải thông tin người dùng: $e';
      debugPrint('[UserProvider] Error loading user info: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user info
  Future<void> refreshUserInfo() async {
    _userInfo = null;
    await initializeUserInfo();
  }

  // Clear user info (call this when user logs out)
  void clearUserInfo() {
    _userInfo = null;
    _error = null;
    _setLoading(false);
    debugPrint('[UserProvider] User info cleared');
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Force update user info (for manual refresh)
  void updateUserInfo(UserInfoResponse userInfo) {
    _userInfo = userInfo;
    _error = null;
    debugPrint('[UserProvider] User info updated: ${userInfo.name}, isGarage: $isGarageUser');
    notifyListeners();
  }
}
