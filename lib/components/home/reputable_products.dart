import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/models/reputable_product/reputable_product_model.dart';

class ReputableProducts extends StatelessWidget {
  final List<ReputableProductModel> products;
  final VoidCallback? onSeeMorePressed;

  const ReputableProducts({
    super.key,
    required this.products,
    this.onSeeMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với title và link "Xem thêm"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: 'Danh sách dòng hàng uy tín',
                textStyle: 'title',
                textSize: '16',
                textColor: 'primary',
              ),
              GestureDetector(
                onTap: onSeeMorePressed,
                child: MyText(
                  text: 'Xem thêm',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: 'brand',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Danh sách các sản phẩm uy tín
          Column(
            children: products.asMap().entries.map((entry) {
              int index = entry.key;
              ReputableProductModel product = entry.value;
              return Column(
                children: [
                  _buildReputableItem(
                    number: '${index + 1}',
                    title: product.name,
                  ),
                  if (index < products.length - 1) const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReputableItem({
    required String number,
    required String title,
  }) {
    return Row(
      children: [
        // Số thứ tự
        Center(
          child: MyText(
            text: number,
            textStyle: 'title',
            textSize: '14',
            textColor: 'primary',
          ),
        ),
        const SizedBox(width: 8),
        
        // Tên sản phẩm
        Expanded(
          child: MyText(
            text: title,
            textStyle: 'body',
            textSize: '14',
            textColor: 'primary',
          ),
        ),
      ],
    );
  }
}
