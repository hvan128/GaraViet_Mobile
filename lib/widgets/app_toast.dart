import 'package:flutter/material.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/navigation/navigation.dart';

enum AppToastType { success, error, warning, info }

class AppToast extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AppToast({
    super.key,
    required this.message,
    this.type = AppToastType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Tự động ẩn sau thời gian duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _hideToast();
      }
    });
  }

  void _hideToast() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _backgroundColor() {
    switch (widget.type) {
      case AppToastType.success:
        return Colors.green.shade50;
      case AppToastType.error:
        return Colors.red.shade50;
      case AppToastType.warning:
        return Colors.orange.shade50;
      case AppToastType.info:
        return Colors.blue.shade50;
    }
  }

  Color _borderColor() {
    switch (widget.type) {
      case AppToastType.success:
        return Colors.green.shade200;
      case AppToastType.error:
        return Colors.red.shade200;
      case AppToastType.warning:
        return Colors.orange.shade200;
      case AppToastType.info:
        return Colors.blue.shade200;
    }
  }

  Color _iconColor() {
    switch (widget.type) {
      case AppToastType.success:
        return Colors.green.shade600;
      case AppToastType.error:
        return Colors.red.shade600;
      case AppToastType.warning:
        return Colors.orange.shade600;
      case AppToastType.info:
        return Colors.blue.shade600;
    }
  }

  IconData _iconData() {
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
      case AppToastType.warning:
        return Icons.warning_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _backgroundColor(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderColor(), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _iconData(),
                    color: _iconColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyText(
                      text: widget.message,
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'primary',
                    ),
                  ),
                  GestureDetector(
                    onTap: _hideToast,
                    child: Icon(
                      Icons.close_rounded,
                      color: _iconColor(),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppToastHelper {
  static OverlayEntry? _currentToast;

  static void _safeRemoveCurrentToast() {
    try {
      if (_currentToast != null) {
        if (_currentToast!.mounted) {
          _currentToast!.remove();
        }
        _currentToast = null;
      }
    } catch (_) {
      _currentToast = null;
    }
  }

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Ẩn toast hiện tại nếu có (chỉ remove khi còn mounted)
    _safeRemoveCurrentToast();

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: AppToast(
            message: message,
            type: type,
            duration: duration,
            onDismiss: () {
              _safeRemoveCurrentToast();
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentToast!);
  }

  // Hiển thị toast không cần truyền context, dùng global navigatorKey
  static void showGlobal({
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final navigator = Navigate().navigationKey.currentState;
    final context = navigator?.overlay?.context;
    if (context == null) return;
    show(
      context,
      message: message,
      type: type,
      duration: duration,
    );
  }

  static void showGlobalError(String message, {Duration duration = const Duration(seconds: 4)}) {
    showGlobal(message: message, type: AppToastType.error, duration: duration);
  }

  static void showGlobalWarning(String message, {Duration duration = const Duration(seconds: 3)}) {
    showGlobal(message: message, type: AppToastType.warning, duration: duration);
  }

  static void showGlobalInfo(String message, {Duration duration = const Duration(seconds: 3)}) {
    showGlobal(message: message, type: AppToastType.info, duration: duration);
  }

  static void showGlobalSuccess(String message, {Duration duration = const Duration(seconds: 3)}) {
    showGlobal(message: message, type: AppToastType.success, duration: duration);
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.error,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.info,
      duration: duration,
    );
  }

  static void hide() {
    _safeRemoveCurrentToast();
  }
}
