import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/navigation/navigation.dart';

class GarageStatusNotification extends StatelessWidget {
  final int? isVerifiedGarage;
  final String garageName;

  const GarageStatusNotification({
    super.key,
    required this.isVerifiedGarage,
    required this.garageName,
  });

  @override
  Widget build(BuildContext context) {
    
    // Xác định trạng thái và thông báo tương ứng
    String message;
    String buttonText;
    VoidCallback? onButtonPressed;
    String iconPath;

    switch (isVerifiedGarage) {
      case 0: // INACTIVE - Chưa ký hợp đồng
        message = 'Tài khoản của bạn chưa ký hợp đồng';
        buttonText = 'Ký';
        onButtonPressed = () {
          Navigate.pushNamed('/electronic-contract');
        };
        iconPath = 'assets/icons_final/clock.svg';
        break;
      case 1: // ACTIVE - Đã ký và được duyệt
        return const SizedBox.shrink(); // Không hiển thị thông báo khi đã active
      case 2: // PENDING - Đã ký nhưng chờ duyệt
        message = 'Tài khoản của bạn đang được xác thực';
        buttonText = '';
        onButtonPressed = null;
        iconPath = 'assets/icons_final/clock.svg';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
      color: DesignTokens.primaryBlue4,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.borderBrandPrimary,
        ),
      ),
      child: Row(
        children: [
          // Icon
          SvgIcon(
            svgPath: iconPath,
            width: 24,
            height: 24,
            color: DesignTokens.surfaceBrand,
          ),
          const SizedBox(width: 8),
          
          // Message
          Expanded(
            child: MyText(
              text: message,
              textStyle: 'title',
              textSize: '14',
              textColor: 'brand',
            ),
          ),
          
          // Button (chỉ hiển thị khi có action)
          if (onButtonPressed != null) ...[
            const SizedBox(width: 12),
            MyButton(
              text: buttonText,
              onPressed: onButtonPressed,
              buttonType: ButtonType.primary,
              height: 36,
              width: 60,
            ),
          ],
        ],
      ),
    );
  }
}
