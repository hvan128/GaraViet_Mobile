import 'package:flutter/material.dart';
import 'package:gara/services/auth/auth_state_manager.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/models/user/login_model.dart';
import 'package:gara/services/storage_service.dart';

class AuthStateDemo extends StatefulWidget {
  const AuthStateDemo({super.key});

  @override
  State<AuthStateDemo> createState() => _AuthStateDemoState();
}

class _AuthStateDemoState extends State<AuthStateDemo> {
  late AuthStateManager _authStateManager;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authStateManager = AuthStateManager();
    _authStateManager.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authStateManager.removeListener(_onAuthStateChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {
      // Rebuild when auth state changes
    });
  }

  Future<void> _testLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại', Colors.red);
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceId = await Storage.getDeviceID() ?? 'demo_device';
      
      final request = UserLoginRequest(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        deviceId: deviceId,
        rememberMe: true,
      );

      final response = await AuthService.loginUser(request);

      if (response.success) {
        _showSnackBar('Đăng nhập thành công!', Colors.green);
      } else {
        _showSnackBar('Đăng nhập thất bại: ${response.message}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    try {
      await AuthService.logout();
      _showSnackBar('Đăng xuất thành công!', Colors.green);
    } catch (e) {
      _showSnackBar('Lỗi khi đăng xuất: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth State Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auth State Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auth State:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Is Logged In: ${_authStateManager.isLoggedIn}'),
                    Text('User Phone: ${_authStateManager.userPhone ?? 'N/A'}'),
                    Text('User Name: ${_authStateManager.userName ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Login Form
            if (!_authStateManager.isLoggedIn) ...[
              Text(
                'Login Form:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
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
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testLogin,
                  child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Test Login'),
                ),
              ),
            ] else ...[
              // Logged in state
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đã đăng nhập!',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _testLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hướng dẫn:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('1. Nhập thông tin đăng nhập và nhấn "Test Login"'),
                    Text('2. Sau khi đăng nhập thành công, UI sẽ thay đổi'),
                    Text('3. Trong HomeScreen, nút "Đăng nhập/Đăng ký" sẽ thành icon account'),
                    Text('4. Nhấn "Logout" để đăng xuất'),
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
