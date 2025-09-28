import 'package:flutter/material.dart';
import 'package:gara/widgets/text.dart';

class TextStyleDemo extends StatelessWidget {
  const TextStyleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          text: 'Typography Demo',
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
            // Head styles
            const MyText(
              text: 'Head Styles',
              textStyle: 'head',
              textSize: '24',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'Head 32px - Main Heading',
              textStyle: 'head',
              textSize: '32',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Head 24px - Section Heading',
              textStyle: 'head',
              textSize: '24',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Head 18px - Subsection',
              textStyle: 'head',
              textSize: '18',
              textColor: 'primary',
            ),
            const SizedBox(height: 24),
            
            // Title styles
            const MyText(
              text: 'Title Styles',
              textStyle: 'title',
              textSize: '18',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'Title 24px - Card Title',
              textStyle: 'title',
              textSize: '24',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Title 18px - Button Text',
              textStyle: 'title',
              textSize: '18',
              textColor: 'brand',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Title 16px - Form Label',
              textStyle: 'title',
              textSize: '16',
              textColor: 'secondary',
            ),
            const SizedBox(height: 24),
            
            // Label styles
            const MyText(
              text: 'Label Styles',
              textStyle: 'label',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'Label 18px - Navigation',
              textStyle: 'label',
              textSize: '18',
              textColor: 'brand',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Label 16px - Tab Label',
              textStyle: 'label',
              textSize: '16',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Label 14px - Small Label',
              textStyle: 'label',
              textSize: '14',
              textColor: 'tertiary',
            ),
            const SizedBox(height: 24),
            
            // Body styles
            const MyText(
              text: 'Body Styles',
              textStyle: 'body',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'Body 18px - Large paragraph text for important content',
              textStyle: 'body',
              textSize: '18',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Body 16px - Regular paragraph text for normal content',
              textStyle: 'body',
              textSize: '16',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Body 14px - Small text for captions and descriptions',
              textStyle: 'body',
              textSize: '14',
              textColor: 'tertiary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Body 12px - Very small text for fine print',
              textStyle: 'body',
              textSize: '12',
              textColor: 'placeholder',
            ),
            const SizedBox(height: 24),
            
            // Text colors
            const MyText(
              text: 'Text Colors',
              textStyle: 'head',
              textSize: '18',
              textColor: 'primary',
            ),
            const SizedBox(height: 16),
            
            const MyText(
              text: 'Primary Text - Main content',
              textStyle: 'body',
              textSize: '16',
              textColor: 'primary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Brand Text - Links and highlights',
              textStyle: 'body',
              textSize: '16',
              textColor: 'brand',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Secondary Text - Supporting content',
              textStyle: 'body',
              textSize: '16',
              textColor: 'secondary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Tertiary Text - Less important content',
              textStyle: 'body',
              textSize: '16',
              textColor: 'tertiary',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Placeholder Text - Form hints',
              textStyle: 'body',
              textSize: '16',
              textColor: 'placeholder',
            ),
            const SizedBox(height: 8),
            
            const MyText(
              text: 'Disabled Text - Inactive content',
              textStyle: 'body',
              textSize: '16',
              textColor: 'disable',
            ),
            const SizedBox(height: 8),
            
            // Invert text on dark background
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: const MyText(
                text: 'Invert Text - For dark backgrounds',
                textStyle: 'body',
                textSize: '16',
                textColor: 'invert',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
