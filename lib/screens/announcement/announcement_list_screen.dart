import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gara/services/notification/notification_service.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  bool _loading = true;
  Map<String, dynamic>? _raw;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await NotificationService.fetchList();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _raw = res['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Load failed';
        _raw = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                      if (_raw != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(const JsonEncoder.withIndent('  ').convert(_raw)),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(const JsonEncoder.withIndent('  ').convert(_raw)),
                      ),
                    ],
                  ),
                ),
    );
  }
}



