class TokenCache {
  static String? _accessToken;
  static int? _expirationTime; // Unix timestamp in seconds
  static const int _refreshThresholdSeconds = 90; // Refresh trước 90 giây

  // Lưu access token và exp vào memory
  static void setAccessToken(String token, int exp) {
    print('💾 [TokenCache] setAccessToken() called');
    print('💾 [TokenCache] Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    print('💾 [TokenCache] Expiration time: $exp');
    _accessToken = token;
    _expirationTime = exp;
    print('💾 [TokenCache] Token saved to memory');
  }

  // Lấy access token từ memory
  static String? getAccessToken() {
    return _accessToken;
  }

  // Kiểm tra token có sắp hết hạn không
  static bool isTokenExpiringSoon() {
    if (_accessToken == null || _expirationTime == null) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiry = _expirationTime! - now;
    
    return timeUntilExpiry <= _refreshThresholdSeconds;
  }

  // Kiểm tra token có hết hạn chưa
  static bool isTokenExpired() {
    if (_accessToken == null || _expirationTime == null) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return _expirationTime! <= now;
  }

  // Lấy thời gian còn lại của token (seconds)
  static int getTimeUntilExpiry() {
    if (_accessToken == null || _expirationTime == null) {
      return 0;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return _expirationTime! - now;
  }

  // Xóa token khỏi memory
  static void clearAccessToken() {
    print('💾 [TokenCache] clearAccessToken() called');
    _accessToken = null;
    _expirationTime = null;
    print('💾 [TokenCache] Token cleared from memory');
  }

  // Kiểm tra có token không
  static bool hasToken() {
    return _accessToken != null && _expirationTime != null;
  }

  // Lấy thông tin debug
  static Map<String, dynamic> getDebugInfo() {
    return {
      'hasToken': hasToken(),
      'isExpiringSoon': isTokenExpiringSoon(),
      'isExpired': isTokenExpired(),
      'timeUntilExpiry': getTimeUntilExpiry(),
      'expirationTime': _expirationTime,
      'currentTime': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }
}
