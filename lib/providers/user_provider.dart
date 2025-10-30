import 'package:flutter/foundation.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/services/user/user_service.dart';
import 'package:gara/services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();
  factory UserProvider() => _instance;
  UserProvider._internal();

  UserInfoResponse? _userInfo;
  bool _isLoading = false;
  String? _error;
  bool _hasRefreshToken = false; // Track refresh token state

  // Getters
  UserInfoResponse? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user is logged in - chỉ khi có user info thực sự
  bool get isLoggedIn {
    // Chỉ coi là đã đăng nhập khi có thông tin user đầy đủ
    // Không dựa vào refresh token để tránh trường hợp token có nhưng user info chưa load xong
    return _userInfo != null;
  }

  // Check if user is garage
  bool get isGarageUser {
    if (_userInfo == null) return false;
    final code = _userInfo!.roleCode.toUpperCase();
    return _userInfo!.roleId == 3 || code == 'GARA' || code == 'GARAGE' || code.contains('GARAGE');
  }

  // Get user display name
  String get userDisplayName {
    if (_userInfo == null) return 'Người dùng';
    return isGarageUser ? (_userInfo!.nameGarage ?? _userInfo!.name) : _userInfo!.name;
  }

  // Initialize user info (call this when app starts or user logs in)
  Future<void> initializeUserInfo() async {
    // Kiểm tra refresh token trước
    await _updateRefreshTokenState();

    if (_userInfo != null) {
      debugPrint('[UserProvider] User info already loaded');
      return;
    }

    _setLoading(true);
    try {
      debugPrint('[UserProvider] Loading user info...');

      // Thử load từ API trước
      UserInfoResponse? userInfo;
      try {
        userInfo = await UserService.getUserInfo();
        if (userInfo != null) {
          // Lưu vào storage khi load thành công từ API
          await Storage.setUserInfo(userInfo.toJson());
          debugPrint('[UserProvider] User info saved to storage');
        }
      } catch (e) {
        debugPrint('[UserProvider] Failed to load from API: $e');
        // Nếu không load được từ API, thử load từ storage
        userInfo = await _loadUserInfoFromStorage();
        if (userInfo != null) {
          debugPrint('[UserProvider] Loaded user info from storage as fallback');
        }
      }

      if (userInfo != null) {
        _userInfo = userInfo;
        _error = null;
        debugPrint(
          '[UserProvider] User info loaded: ${userInfo.name}, roleId: ${userInfo.roleId}, roleCode: ${userInfo.roleCode}',
        );
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

  // Load user info từ storage
  Future<UserInfoResponse?> _loadUserInfoFromStorage() async {
    try {
      final userInfoData = await Storage.getUserInfo();
      if (userInfoData != null) {
        return UserInfoResponse.fromJson(userInfoData);
      }
    } catch (e) {
      debugPrint('[UserProvider] Error loading from storage: $e');
    }
    return null;
  }

  // Update refresh token state
  Future<void> _updateRefreshTokenState() async {
    try {
      final refreshToken = await Storage.getRefreshToken();
      _hasRefreshToken = refreshToken != null;
      debugPrint('[UserProvider] Refresh token state updated: $_hasRefreshToken');
    } catch (e) {
      _hasRefreshToken = false;
      debugPrint('[UserProvider] Error checking refresh token: $e');
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
    _hasRefreshToken = false;
    _setLoading(false);
    // Xóa user info khỏi storage
    Storage.removeUserInfo();
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
    // Lưu vào storage khi update
    Storage.setUserInfo(userInfo.toJson());
    debugPrint('[UserProvider] User info updated: ${userInfo.name}, isGarage: $isGarageUser');
    notifyListeners();
  }

  // Update refresh token state (call when network is restored)
  Future<void> updateRefreshTokenState() async {
    await _updateRefreshTokenState();
    notifyListeners();
  }

  // Load user info từ storage khi app khởi động (fallback)
  Future<void> loadUserInfoFromStorage() async {
    if (_userInfo != null) return; // Đã có user info rồi

    try {
      final userInfo = await _loadUserInfoFromStorage();
      if (userInfo != null) {
        _userInfo = userInfo;
        _error = null;
        debugPrint('[UserProvider] Loaded user info from storage on startup: ${userInfo.name}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[UserProvider] Error loading user info from storage on startup: $e');
    }
  }

  // Force refresh user info từ API (không dùng cache)
  Future<bool> forceRefreshUserInfo() async {
    _setLoading(true);
    try {
      debugPrint('[UserProvider] Force refreshing user info from API...');

      // Gọi API để lấy thông tin mới nhất
      final userInfo = await UserService.getUserInfo();

      if (userInfo != null) {
        _userInfo = userInfo;
        _error = null;

        // Lưu vào storage
        await Storage.setUserInfo(userInfo.toJson());

        debugPrint('[UserProvider] Force refresh successful: ${userInfo.name}, isGarage: $isGarageUser');
        notifyListeners();
        return true;
      } else {
        _error = 'Không thể tải thông tin người dùng';
        debugPrint('[UserProvider] Force refresh failed - no user info returned');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi khi tải thông tin người dùng: $e';
      debugPrint('[UserProvider] Force refresh error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
