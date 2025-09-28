import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/services/auth/jwt_token_manager.dart';

class AdvancedAuthDemo extends StatefulWidget {
  const AdvancedAuthDemo({super.key});

  @override
  State<AdvancedAuthDemo> createState() => _AdvancedAuthDemoState();
}

class _AdvancedAuthDemoState extends State<AdvancedAuthDemo> {
  String? currentToken;
  String? tokenExpiry;
  String? refreshStatus = 'Chưa khởi tạo';
  Map<String, dynamic>? debugInfo;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    final token = TokenCache.getAccessToken();
    setState(() {
      currentToken = token;
      debugInfo = TokenCache.getDebugInfo();
      if (token != null) {
        _parseTokenExpiry(token);
      }
    });
  }

  void _parseTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
        final padded = normalized.padRight(normalized.length + (4 - normalized.length % 4) % 4, '=');
        final decoded = utf8.decode(base64Decode(padded));
        final payloadMap = jsonDecode(decoded);
        final exp = payloadMap['exp'] as int?;
        
        if (exp != null) {
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          tokenExpiry = '${expiryDate.toString().substring(0, 19)}';
        }
      }
    } catch (e) {
      tokenExpiry = 'Lỗi parse token: $e';
    }
  }

  Future<void> _simulateLogin() async {
    // Tạo token giả với thời gian hết hạn ngắn để test
    final now = DateTime.now();
    final exp = now.add(const Duration(seconds: 15)).millisecondsSinceEpoch ~/ 1000; // Hết hạn sau 15 giây
    
    final mockToken = _createMockJWT(exp);
    
    await JwtTokenManager.saveNewTokens(
      accessToken: mockToken,
      refreshToken: 'mock_refresh_token',
    );
    
    setState(() {
      currentToken = mockToken;
      _parseTokenExpiry(mockToken);
      refreshStatus = 'Đã lên lịch refresh token';
    });
    
    _loadTokenInfo();
  }

  String _createMockJWT(int exp) {
    final header = base64Encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = base64Encode(utf8.encode(jsonEncode({
      'sub': 'user123',
      'exp': exp,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    })));
    final signature = base64Encode(utf8.encode('mock_signature'));
    
    return '$header.$payload.$signature';
  }

  Future<void> _clearTokens() async {
    await JwtTokenManager.clearTokens();
    setState(() {
      currentToken = null;
      tokenExpiry = null;
      refreshStatus = 'Đã xóa token';
      debugInfo = null;
    });
  }

  Future<void> _testLazyRefresh() async {
    setState(() {
      refreshStatus = 'Testing lazy refresh...';
    });
    
    final success = await JwtTokenManager.ensureValidToken();
    
    setState(() {
      refreshStatus = success ? 'Lazy refresh thành công' : 'Lazy refresh thất bại';
    });
    
    _loadTokenInfo();
  }

  Future<void> _testAppResume() async {
    setState(() {
      refreshStatus = 'Simulating app resume...';
    });
    
    await JwtTokenManager.handleAppResume();
    
    setState(() {
      refreshStatus = 'App resume simulation hoàn thành';
    });
    
    _loadTokenInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Auth Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTokenInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Authentication Demo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Token Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin Token:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Token: ${currentToken?.substring(0, 50) ?? 'Không có'}...'),
                    Text('Hết hạn: ${tokenExpiry ?? 'Không có'}'),
                    Text('Trạng thái: $refreshStatus'),
                    if (debugInfo != null) ...[
                      const SizedBox(height: 8),
                      Text('Debug Info:', style: Theme.of(context).textTheme.titleSmall),
                      Text('Has Token: ${debugInfo!['hasToken']}'),
                      Text('Is Expiring Soon: ${debugInfo!['isExpiringSoon']}'),
                      Text('Is Expired: ${debugInfo!['isExpired']}'),
                      Text('Time Until Expiry: ${debugInfo!['timeUntilExpiry']}s'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _simulateLogin,
                  child: const Text('Simulate Login'),
                ),
                ElevatedButton(
                  onPressed: _clearTokens,
                  child: const Text('Clear Tokens'),
                ),
                ElevatedButton(
                  onPressed: _testLazyRefresh,
                  child: const Text('Test Lazy Refresh'),
                ),
                ElevatedButton(
                  onPressed: _testAppResume,
                  child: const Text('Test App Resume'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hướng dẫn Test:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('1. "Simulate Login" - Tạo token giả (hết hạn sau 15s)'),
                    const Text('2. "Test Lazy Refresh" - Test lazy refresh logic'),
                    const Text('3. "Test App Resume" - Simulate app resume'),
                    const Text('4. "Clear Tokens" - Xóa tất cả token'),
                    const Text('5. Xem console để theo dõi quá trình refresh'),
                    const Text('6. Token sẽ tự động refresh trước 90s hết hạn'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Features Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tính năng đã implement:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Lazy refresh - check token trước mỗi request'),
                    const Text('✅ Single-flight refresh - chỉ 1 luồng refresh'),
                    const Text('✅ App resume handling - check khi app resume'),
                    const Text('✅ 401 retry logic - retry 1 lần khi gặp 401'),
                    const Text('✅ Memory token cache - access token trong RAM'),
                    const Text('✅ Secure storage - refresh token trong storage'),
                    const Text('✅ Timer-based refresh - refresh chủ động'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
