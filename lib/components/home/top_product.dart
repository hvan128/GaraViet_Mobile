import 'package:flutter/material.dart';
import 'package:gara/models/product/product_model.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/text.dart';

class TopProduct extends StatelessWidget {
  const TopProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: 'Sản phẩm hot',
                textStyle: 'title',
                textSize: '16',
                textColor: 'primary',
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to see more products
                },
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
          // Product List - Horizontal Scrollable
          SizedBox(
            height: 194,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < 2 ? 12 : 0,
                  ),
                  child: _buildProductCard(
                    product: ProductModel(
                      name: 'Ghế da Nappa',
                      description: 'Sản phẩm',
                      customerCount: 40,
                      isPartner: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({required ProductModel product}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Image.asset(
            'assets/images/ghe_da.png',
            width: 144,
            height: 144,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 160,
                height: 120,
                color: DesignTokens.gray100,
                child: Icon(
                  Icons.shopping_bag,
                  color: DesignTokens.gray500,
                  size: 40,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Product Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Product Name
            MyText(
              text: product.name!,
              textStyle: 'title',
              textSize: '14',
              textColor: 'primary',
            ),
            // Customer Count
            MyText(
              text: '${product.customerCount ?? 0} khách hàng lựa chọn',
              textStyle: 'body',
              textSize: '12',
              textColor: 'tertiary',
            ),
          ],
        ),
      ],
    );
  }
}
