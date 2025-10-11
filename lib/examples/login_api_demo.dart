import 'package:flutter/material.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/models/user/login_model.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/widgets/app_toast.dart';

class LoginApiDemo extends StatefulWidget {
  const LoginApiDemo({super.key});

  @override
  State<LoginApiDemo> createState() => _LoginApiDemoState();
}

class _LoginApiDemoState extends State<LoginApiDemo> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _lastResponse;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await Storage.getDeviceID();
    setState(() {
      _deviceId = deviceId ?? 'unknown_device';
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      _showToastError('Vui lòng nhập số điện thoại');
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      _showToastError('Vui lòng nhập mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResponse = null;
    });

    try {
      final request = UserLoginRequest(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        deviceId: _deviceId ?? 'unknown_device',
        rememberMe: _rememberMe,
      );

      final response = await AuthService.loginUser(request);

      setState(() {
        _lastResponse = '''
Success: ${response.success}
Message: ${response.message ?? 'N/A'}
Access Token: ${response.accessToken?.substring(0, 50) ?? 'N/A'}...
Refresh Token: ${response.refreshToken?.substring(0, 50) ?? 'N/A'}...
Data: ${response.data?.toString() ?? 'N/A'}
        ''';
      });

      if (response.success) {
        _showToastSuccess('Đăng nhập thành công!');
      } else {
        _showToastError('Đăng nhập thất bại: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _lastResponse = 'Error: ${e.toString()}';
      });
      _showToastError('Lỗi: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showToastSuccess(String message) {
    AppToastHelper.showSuccess(context, message: message);
  }

  void _showToastError(String message) {
    AppToastHelper.showError(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login API Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Login API Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Device ID display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device ID:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(_deviceId ?? 'Loading...'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Input fields
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                hintText: '0123456789',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                hintText: 'password123',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                const Text('Remember Me'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testLogin,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Test Login API'),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Response display
            if (_lastResponse != null) ...[
              Text(
                'Last Response:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _lastResponse!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
