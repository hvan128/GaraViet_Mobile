import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/text.dart';

enum AppDialogType { success, error, info, warning }

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final AppDialogType type;
  final String confirmText;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final ButtonType? confirmButtonType;
  final ButtonType? cancelButtonType;
  final bool showIconHeader;
  final Widget? icon;
  final Color? iconBgColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = AppDialogType.info,
    this.confirmText = 'OK',
    this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.confirmButtonType = ButtonType.primary,
    this.cancelButtonType = ButtonType.secondary,
    this.showIconHeader = false,
    this.icon,
    this.iconBgColor,
  });

  Color _iconBgColor(BuildContext context) {
    switch (type) {
      case AppDialogType.success:
        return Colors.green.shade50;
      case AppDialogType.error:
        return Colors.red.shade50;
      case AppDialogType.warning:
        return Colors.orange.shade50;
      case AppDialogType.info:
        return Colors.blue.shade50;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (type) {
      case AppDialogType.success:
        return Colors.green;
      case AppDialogType.error:
        return Colors.red;
      case AppDialogType.warning:
        return Colors.orange;
      case AppDialogType.info:
        return Colors.blue;
    }
  }

  IconData _iconData() {
    switch (type) {
      case AppDialogType.success:
        return Icons.check_circle_rounded;
      case AppDialogType.error:
        return Icons.error_rounded;
      case AppDialogType.warning:
        return Icons.warning_rounded;
      case AppDialogType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCancel = cancelText != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: DesignTokens.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIconHeader) ...[
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? _iconBgColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: icon ?? Icon(_iconData(), color: _iconColor(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyText(
                      text: title,
                      textStyle: 'head',
                      textSize: '16',
                      textColor: 'primary',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (!showIconHeader && title.isNotEmpty) ...[
              MyText(
                text: title,
                textStyle: 'head',
                textSize: '16',
                textColor: 'primary',
              ),
              const SizedBox(height: 8),
            ],
            MyText(
              text: message,
              textStyle: 'body',
              textSize: '14',
              textColor: 'primary',
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                if (hasCancel) ...[
                  Expanded(
                    child: MyButton(
                      text: cancelText!,
                      buttonType: cancelButtonType!,
                      height: 36,
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        onCancel?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: MyButton(
                    text: confirmText,
                    buttonType: confirmButtonType!,
                    height: 36,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppDialogHelper {
  static Future<void> show(
    BuildContext context, {
    required String title,  
    required String message,
    AppDialogType type = AppDialogType.info,
    String confirmText = 'OK',
    ButtonType? confirmButtonType = ButtonType.primary,
    Widget? icon,
    Color? iconBgColor,
    bool showIconHeader = false,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        type: type,
        confirmText: confirmText,
        confirmButtonType: confirmButtonType,
        icon: icon,
        iconBgColor: iconBgColor,
        showIconHeader: showIconHeader,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    AppDialogType type = AppDialogType.warning,
    ButtonType? confirmButtonType = ButtonType.primary,
    ButtonType? cancelButtonType = ButtonType.secondary,
    Widget? icon,
    Color? iconBgColor,
    bool showIconHeader = false,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        type: type,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmButtonType: confirmButtonType,
        cancelButtonType: cancelButtonType,
        icon: icon,
        iconBgColor: iconBgColor,
        showIconHeader: showIconHeader,
        onConfirm: onConfirm,
      ),
    );
  }
}


