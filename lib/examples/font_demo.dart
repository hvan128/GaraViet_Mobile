import 'package:flutter/material.dart';
import 'package:gara/widgets/text.dart';

class FontDemo extends StatelessWidget {
  const FontDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          text: 'Font Demo',
          textStyle: 'head',
          textSize: '18',
          textColor: 'primary',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test different font weights
            const MyText(
              text: 'Font Weight Test',
              textStyle: 'head',
              textSize: '24',
              textColor: 'primary',
            ),
            const SizedBox(height: 24),
            
            // Body styles with different weights
            const MyText(
              text: 'Body 400 (Regular)',
              textStyle: 'body',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Label 500 (Medium)',
              textStyle: 'label',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Title 600 (SemiBold)',
              textStyle: 'title',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Head 700 (Bold)',
              textStyle: 'head',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 24),
            
            // Test different sizes
            const MyText(
              text: 'Size Test',
              textStyle: 'head',
              textSize: '24',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: '12px - Extra Small',
              textStyle: 'body',
              textSize: '12',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: '14px - Small',
              textStyle: 'body',
              textSize: '14',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: '16px - Regular',
              textStyle: 'body',
              textSize: '16',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: '18px - Large',
              textStyle: 'body',
              textSize: '18',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: '24px - Extra Large',
              textStyle: 'head',
              textSize: '24',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: '32px - Huge',
              textStyle: 'head',
              textSize: '32',
              textColor: 'secondary',
            ),
            const SizedBox(height: 24),
            
            // Test with custom font weights
            const MyText(
              text: 'Custom Font Weights',
              textStyle: 'head',
              textSize: '18',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            // Test with custom color
            const MyText(
              text: 'Brand Color Text',
              textStyle: 'head',
              textSize: '18',
              textColor: 'brand',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Error Color Text',
              textStyle: 'head',
              textSize: '18',
              textColor: 'error',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Success Color Text',
              textStyle: 'head',
              textSize: '18',
              textColor: 'success',
            ),
            const SizedBox(height: 24),
            
            // Test paragraph
            const MyText(
              text: 'Paragraph Test',
              textStyle: 'head',
              textSize: '18',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'Đây là một đoạn văn dài để test font Manrope với tiếng Việt. Font này sẽ hiển thị đẹp và dễ đọc trên mọi thiết bị. Chúng ta có thể sử dụng các font weight khác nhau từ 200 đến 800.',
              textStyle: 'body',
              textSize: '16',
              textColor: 'secondary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'This is a long paragraph to test Manrope font with English text. The font should display beautifully and be easy to read on all devices. We can use different font weights from 200 to 800.',
              textStyle: 'body',
              textSize: '16',
              textColor: 'tertiary',
            ),
          ],
        ),
      ),
    );
  }
}
