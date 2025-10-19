import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isConnected = true;
  static final List<VoidCallback> _connectionListeners = [];

  /// Kiểm tra có phải lỗi mạng không
  static bool isNetworkError(dynamic error) {
    return error is SocketException || 
           error is TimeoutException ||
           error.toString().contains('ClientException') ||
           error.toString().contains('NetworkException') ||
           error.toString().contains('Connection refused') ||
           error.toString().contains('Failed host lookup') ||
           error.toString().contains('No route to host');
  }
  
  /// Kiểm tra thực sự có thể kết nối internet (chỉ dùng khi cần thiết)
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Khởi tạo network connectivity listener
  static void initializeConnectivityListener() {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final wasConnected = _isConnected;
          _isConnected = results.any((result) => 
            result == ConnectivityResult.mobile || 
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet
          );
          
          print('🌐 [NetworkUtils] Connectivity changed: $_isConnected (was: $wasConnected)');
          
          // Nếu từ không có mạng chuyển sang có mạng
          if (!wasConnected && _isConnected) {
            print('🌐 [NetworkUtils] Network restored, notifying listeners...');
            _notifyConnectionRestored();
          }
        },
        onError: (error) {
          print('🌐 [NetworkUtils] Connectivity listener error: $error');
        },
      );
    } catch (e) {
      print('🌐 [NetworkUtils] Failed to initialize connectivity listener: $e');
      // Fallback: assume connected
      _isConnected = true;
    }
  }

  /// Thêm listener cho sự kiện kết nối mạng được khôi phục
  static void addConnectionListener(VoidCallback listener) {
    _connectionListeners.add(listener);
  }

  /// Xóa listener
  static void removeConnectionListener(VoidCallback listener) {
    _connectionListeners.remove(listener);
  }

  /// Thông báo cho tất cả listeners khi mạng được khôi phục
  static void _notifyConnectionRestored() {
    for (final listener in _connectionListeners) {
      try {
        listener();
      } catch (e) {
        print('🌐 [NetworkUtils] Error in connection listener: $e');
      }
    }
  }

  /// Kiểm tra trạng thái kết nối hiện tại
  static bool get isConnected => _isConnected;

  /// Hủy listener
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _connectionListeners.clear();
  }
}
