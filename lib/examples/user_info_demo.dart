import 'package:flutter/material.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:provider/provider.dart';

class UserInfoDemo extends StatefulWidget {
  const UserInfoDemo({super.key});

  @override
  State<UserInfoDemo> createState() => _UserInfoDemoState();
}

class _UserInfoDemoState extends State<UserInfoDemo> {
  UserInfoResponse? _userInfo;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userInfo = userProvider.userInfo;
      
      if (userInfo == null) {
        // Nếu chưa có user info, refresh từ provider
        await userProvider.refreshUserInfo();
        final refreshedUserInfo = userProvider.userInfo;
        setState(() {
          _userInfo = refreshedUserInfo;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userInfo = userInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info API Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Info API Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadUserInfo,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Load User Info'),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Results
            if (_errorMessage != null) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                    ],
                  ),
                ),
              ),
            ] else if (_userInfo != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Success',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildUserInfoDisplay(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('ID', _userInfo!.id.toString()),
        _buildInfoRow('User ID', _userInfo!.userId.toString()),
        _buildInfoRow('Name', _userInfo!.name),
        _buildInfoRow('Phone', _userInfo!.phone),
        _buildInfoRow('Role ID', _userInfo!.roleId.toString()),
        _buildInfoRow('Role Code', _userInfo!.roleCode),
        _buildInfoRow('Role Name', _userInfo!.roleName),
        _buildInfoRow('Is Active', _userInfo!.isActive.toString()),
        _buildInfoRow('Is Phone Verified', _userInfo!.isPhoneVerified.toString()),
        _buildInfoRow('Device ID', _userInfo!.deviceId),
        _buildInfoRow('Session ID', _userInfo!.sessionId),
        _buildInfoRow('Created At', _userInfo!.createdAt),
        _buildInfoRow('Updated At', _userInfo!.updatedAt),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
