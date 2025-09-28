import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Storage {
  static final Future<SharedPreferences> _store =
      SharedPreferences.getInstance();
  static const _secureStore = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
  );

  static Future<dynamic> getItem(String key) async {
    try {
      final store = await _store;
      late final dynamic res;

      final value = store.get(key);
      if (value is String) {
        // Thử parse JSON, nếu fail thì trả về string gốc
        try {
          res = jsonDecode(value);
        } catch (e) {
          // Nếu không phải JSON, trả về string gốc
          res = value;
        }
      } else {
        res = value;
      }

      return res;
      // ignore: empty_catches
    } catch (err) {
      print('💥 Storage.getItem($key) error: $err');
      return null;
    }
  }

  static Future<void> setItem<T>(String key, T value) async {
    try {
      final store = await _store;

      if (value is Map<String, dynamic>) {
        final res = jsonEncode(value);
        await store.setString(key, res);
      } else if (value is bool) {
        await store.setBool(key, value);
      } else if (value is double) {
        await store.setDouble(key, value);
      } else if (value is int) {
        await store.setInt(key, value);
      } else if (value is String) {
        await store.setString(key, value);
      } else if (value is List<String>) {
        await store.setStringList(key, value);
      } else if (value == null) {
        await store.remove(key);
      } else {
        /// Other types must define .toJson() function in class, example: AccountLogin class
        final res = jsonEncode(value);
        await store.setString(key, res);
      }
      // ignore: empty_catches
    } catch (err) {
      print('💥 Storage.setItem($key) error: $err');
    }
  }

  static Future<String?> getAccessToken() async {
    return await _secureStore.read(key: 'accessToken');
  }

  static Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStore.read(key: 'refreshToken');
      print('💾 [Storage] getRefreshToken() called, result: ${token != null ? "EXISTS" : "NULL"}');
      if (token != null) {
        print('💾 [Storage] Refresh token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      return token;
    } catch (e) {
      print('💾 [Storage] ERROR getting refresh token: $e');
      return null;
    }
  }

  static void setAccessToken(String value) async {
    await _secureStore.write(key: 'accessToken', value: value);
  }

  static void setRefreshToken(String value) async {
    try {
      print('💾 [Storage] setRefreshToken() called');
      print('💾 [Storage] Refresh token (first 20 chars): ${value.substring(0, value.length > 20 ? 20 : value.length)}...');
      await _secureStore.write(key: 'refreshToken', value: value);
      print('💾 [Storage] Refresh token saved to secure storage');
    } catch (e) {
      print('💾 [Storage] ERROR setting refresh token: $e');
    }
  }

  static void removeToken(String key) async {
    await _secureStore.delete(key: key);
  }

  static void removeAllToken() async {
    try {
      print('💾 [Storage] removeAllToken() called');
      await _secureStore.delete(key: 'accessToken');
      await _secureStore.delete(key: 'refreshToken');
      print('💾 [Storage] All tokens removed from secure storage');
    } catch (e) {
      print('💾 [Storage] ERROR removing tokens: $e');
    }
  }

  static Future<String?> getDeviceID() async {
    try {
      final store = await _store;
      return store.getString('deviceId');
      // ignore: empty_catches
    } catch (err) {}

    return null;
  }

  static void newDeviceID() async {
    final newId = uuid.v8();

    try {
      final store = await _store;
      // Check existed deviceId
      if (store.getString('deviceId') == null) {
        await store.setString('deviceId', newId);
      }
      // ignore: empty_catches
    } catch (err) {}
  }
}
