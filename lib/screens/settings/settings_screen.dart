import 'package:flutter/material.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _languageCode = 'VN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceSecondary,
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              height: 56,
              title: 'Cài đặt',
              showLeftButton: true,
              onLeftPressed: () => Navigate.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSettingsCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Row(
              children: [
                const Expanded(
                  child: MyText(text: 'Thông báo', textStyle: 'title', textSize: '16', textColor: 'primary'),
                ),
                Switch.adaptive(
                  value: _notificationsEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: DesignTokens.textBrand,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Row(
              children: [
                const Expanded(
                  child: MyText(text: 'Ngôn ngữ', textStyle: 'title', textSize: '16', textColor: 'primary'),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: mở modal chọn ngôn ngữ
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.borderSecondary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText(text: _languageCode, textStyle: 'title', textSize: '14', textColor: 'primary'),
                        const SizedBox(width: 4),
                        SvgIcon(svgPath: 'assets/icons_final/arrow-down.svg', size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.pushNamed(context, '/change-password');
            },
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: Row(
                children: [
                  const Expanded(
                    child: MyText(text: 'Đổi mật khẩu', textStyle: 'title', textSize: '16', textColor: 'primary'),
                  ),
                  SvgIcon(svgPath: 'assets/icons_final/arrow-right.svg', size: 24, color: DesignTokens.textBrand),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              // TODO: điều hướng đến màn cài đặt quyền riêng tư
            },
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: Row(
                children: [
                  const Expanded(
                    child: MyText(
                      text: 'Quyền riêng tư & bảo mật',
                      textStyle: 'title',
                      textSize: '16',
                      textColor: 'primary',
                    ),
                  ),
                  SvgIcon(svgPath: 'assets/icons_final/arrow-right.svg', size: 24, color: DesignTokens.textBrand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
