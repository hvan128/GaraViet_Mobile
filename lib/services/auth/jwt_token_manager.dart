import 'dart:async';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/services/api/auth_http_client.dart';
import 'package:gara/config.dart';
import 'package:gara/services/auth/token_cache.dart';

class JwtTokenManager {
  static Timer? _refreshTimer;
  static const int _refreshThresholdSeconds = 90; // Refresh trước 90 giây
  
  // Single-flight refresh
  static bool _isRefreshing = false;
  static final List<Completer<void>> _refreshWaiters = [];

  // Khởi tạo timer refresh token
  static Future<void> initializeTokenRefresh() async {
    print('🔄 [JwtTokenManager] initializeTokenRefresh() called');
    print('🔄 [JwtTokenManager] TokenCache.hasToken(): ${TokenCache.hasToken()}');
    
    if (TokenCache.hasToken()) {
      print('🔄 [JwtTokenManager] Token exists in cache, scheduling refresh');
      _scheduleTokenRefresh();
    } else {
      print('🔄 [JwtTokenManager] No token in cache, checking if we can refresh from storage');
      // Nếu không có token trong memory, thử refresh từ storage
      final refreshToken = await Storage.getRefreshToken();
      if (refreshToken != null) {
        print('🔄 [JwtTokenManager] Found refresh token in storage, attempting refresh');
        final success = await refreshTokenIfNeeded();
        print('🔄 [JwtTokenManager] Refresh attempt result: $success');
      } else {
        print('🔄 [JwtTokenManager] No refresh token found in storage');
      }
    }
  }

  // Lazy refresh - check trước mỗi request
  static Future<bool> ensureValidToken() async {
    // Nếu không có token hoặc sắp hết hạn, refresh
    if (!TokenCache.hasToken() || TokenCache.isTokenExpiringSoon()) {
      return await refreshTokenIfNeeded();
    }
    return true;
  }

  // Check if token is valid (not expired)
  static Future<bool> isTokenValid(String token) async {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp > now;
    } catch (e) {
      return false;
    }
  }

  // Single-flight refresh
  static Future<bool> refreshTokenIfNeeded() async {
    print('🔄 [JwtTokenManager] refreshTokenIfNeeded() called');
    print('🔄 [JwtTokenManager] _isRefreshing: $_isRefreshing');
    
    // Nếu đang refresh, đợi kết quả
    if (_isRefreshing) {
      print('🔄 [JwtTokenManager] Already refreshing, waiting for result...');
      final completer = Completer<void>();
      _refreshWaiters.add(completer);
      await completer.future;
      final result = TokenCache.hasToken() && !TokenCache.isTokenExpired();
      print('🔄 [JwtTokenManager] Waited for refresh result: $result');
      return result;
    }

    // Bắt đầu refresh
    print('🔄 [JwtTokenManager] Starting refresh process...');
    _isRefreshing = true;
    
    try {
      final success = await _performRefresh();
      print('🔄 [JwtTokenManager] _performRefresh() result: $success');
      
      // Thông báo cho tất cả waiters
      for (final waiter in _refreshWaiters) {
        waiter.complete();
      }
      _refreshWaiters.clear();
      
      return success;
    } catch (e) {
      print('🔄 [JwtTokenManager] Error during refresh: $e');
      // Thông báo lỗi cho tất cả waiters
      for (final waiter in _refreshWaiters) {
        waiter.completeError(e);
      }
      _refreshWaiters.clear();
      return false;
    } finally {
      _isRefreshing = false;
      print('🔄 [JwtTokenManager] Refresh process completed, _isRefreshing set to false');
    }
  }

  // Lên lịch refresh token dựa trên exp từ TokenCache
  static void _scheduleTokenRefresh() {
    if (!TokenCache.hasToken()) return;
    
    final timeUntilExpiry = TokenCache.getTimeUntilExpiry();
    final refreshTime = timeUntilExpiry - _refreshThresholdSeconds;
    
    if (refreshTime > 0) {
      print('Token sẽ được refresh sau: ${refreshTime} giây');
      
      _refreshTimer?.cancel();
      _refreshTimer = Timer(Duration(seconds: refreshTime), () {
        refreshTokenIfNeeded();
      });
    } else {
      // Token sắp hết hạn, refresh ngay lập tức
      refreshTokenIfNeeded();
    }
  }

  // Thực hiện refresh token
  static Future<bool> _performRefresh() async {
    print('🔄 [JwtTokenManager] _performRefresh() started');
    
    try {
      final refreshToken = await Storage.getRefreshToken();
      print('🔄 [JwtTokenManager] Retrieved refresh token from storage: ${refreshToken != null ? "EXISTS" : "NULL"}');
      
      if (refreshToken == null) {
        print('🔄 [JwtTokenManager] ERROR: Không có refresh token');
        return false;
      }

      print('🔄 [JwtTokenManager] Calling refresh token API...');
      // Gọi API refresh token
      final response = await _callRefreshTokenAPI(refreshToken);
      print('🔄 [JwtTokenManager] API response: ${response.toString()}');
      
      if (response['success']) {
        final newAccessToken = response['data']?['access_token'];
        final newRefreshToken = response['data']?['refresh_token'];
        
        print('🔄 [JwtTokenManager] New access token: ${newAccessToken != null ? "EXISTS" : "NULL"}');
        print('🔄 [JwtTokenManager] New refresh token: ${newRefreshToken != null ? "EXISTS" : "NULL"}');
        
        if (newAccessToken != null) {
          // Parse JWT để lấy exp
          final payload = Jwt.parseJwt(newAccessToken);
          final exp = payload['exp'] as int?;
          
          print('🔄 [JwtTokenManager] JWT payload exp: $exp');
          
          if (exp != null) {
            // Lưu access token vào memory, refresh token vào storage
            TokenCache.setAccessToken(newAccessToken, exp);
            if (newRefreshToken != null) {
              Storage.setRefreshToken(newRefreshToken);
            }
            
            // Lên lịch refresh tiếp theo
            _scheduleTokenRefresh();
            print('🔄 [JwtTokenManager] SUCCESS: Token đã được refresh thành công');
            return true;
          } else {
            print('🔄 [JwtTokenManager] ERROR: Không thể parse exp từ JWT');
          }
        } else {
          print('🔄 [JwtTokenManager] ERROR: Không có access token trong response');
        }
      } else {
        print('🔄 [JwtTokenManager] ERROR: Refresh token thất bại: ${response['message']}');
        print('🔄 [JwtTokenManager] Full error response: ${response.toString()}');
        // Xóa token và yêu cầu đăng nhập lại
        await clearTokens();
      }
    } catch (e) {
      print('🔄 [JwtTokenManager] EXCEPTION: Lỗi refresh token: $e');
      print('🔄 [JwtTokenManager] Exception type: ${e.runtimeType}');
      await clearTokens();
    }
    
    print('🔄 [JwtTokenManager] _performRefresh() returning false');
    return false;
  }

  // Gọi API refresh token
  static Future<Map<String, dynamic>> _callRefreshTokenAPI(String refreshToken) async {
    print('🔄 [JwtTokenManager] _callRefreshTokenAPI() called');
    print('🔄 [JwtTokenManager] URL: ${Config.refreshTokenUrl}');
    print('🔄 [JwtTokenManager] Refresh token (first 20 chars): ${refreshToken.substring(0, refreshToken.length > 20 ? 20 : refreshToken.length)}...');
    
    try {
      final response = await AuthHttpClient.post(
        Config.refreshTokenUrl,
        body: {'refresh_token': refreshToken},
        includeAuth: false, // Refresh token không cần auth
      );
      
      print('🔄 [JwtTokenManager] API call completed, response: ${response.toString()}');
      return response;
    } catch (e) {
      print('🔄 [JwtTokenManager] API call exception: $e');
      print('🔄 [JwtTokenManager] Exception type: ${e.runtimeType}');
      return {
        'success': false,
        'message': 'Lỗi gọi API refresh token: ${e.toString()}',
      };
    }
  }

  // Lưu token mới và lên lịch refresh
  static Future<void> saveNewTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      // Parse JWT để lấy exp
      final payload = Jwt.parseJwt(accessToken);
      final exp = payload['exp'] as int?;
      
      if (exp != null) {
        // Lưu access token vào memory, refresh token vào storage
        TokenCache.setAccessToken(accessToken, exp);
        if (refreshToken != null) {
          Storage.setRefreshToken(refreshToken);
        }
        
        // Lên lịch refresh cho token mới
        _scheduleTokenRefresh();
        print('Token mới đã được lưu và lên lịch refresh');
      } else {
        throw Exception('Không thể parse exp từ JWT');
      }
    } catch (e) {
      print('Lỗi lưu token mới: $e');
      throw e;
    }
  }

  // Xử lý app resume - check và refresh nếu cần
  static Future<void> handleAppResume() async {
    if (TokenCache.hasToken() && TokenCache.isTokenExpiringSoon()) {
      print('App resumed - token sắp hết hạn, refresh ngay');
      await refreshTokenIfNeeded();
    }
  }

  // Hủy timer refresh
  static void cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Xóa token và hủy timer
  static Future<void> clearTokens() async {
    TokenCache.clearAccessToken();
    Storage.removeAllToken();
    cancelRefreshTimer();
  }
}
