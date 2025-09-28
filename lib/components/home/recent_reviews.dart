import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/models/review/review_model.dart';
import 'package:gara/utils/url.dart';

class RecentReviews extends StatelessWidget {
  final List<ReviewModel> reviews;
  final VoidCallback? onSeeMorePressed;

  const RecentReviews({
    super.key,
    required this.reviews,
    this.onSeeMorePressed,
  });

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
                text: 'Đánh giá gần đây',
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
          
          // Reviews List
          Column(
            children: reviews.map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildReviewCard(review),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: DesignTokens.gray100,
                backgroundImage: review.userAvatar != null 
                    ? NetworkImage(resolveImageUrl(review.userAvatar!)!) 
                    : null,
                child: review.userAvatar == null 
                    ? Icon(
                        Icons.person,
                        color: DesignTokens.gray500,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              
              // User name
              MyText(
                text: review.userName,
                textStyle: 'title',
                textSize: '14',
                textColor: 'primary',
              ),
              
              const SizedBox(width: 8),
              // Arrow
              SvgIcon(svgPath: 'assets/icons_final/arrow-right.svg', width: 16, height: 16, color: Color(0xFF1C1C28)),
              
              const SizedBox(width: 8),
              
              // Context
              MyText(
                text: review.context ?? 'Vietnam car',
                textStyle: 'title',
                textSize: '14',
                textColor: 'primary',
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
           // Rating stars
           Row(
             children: List.generate(5, (index) {
               return Padding(
                 padding: EdgeInsets.only(right: index < 4 ? 4 : 0),
                 child: Container(
                   width: 12,
                   height: 12,
                   decoration: BoxDecoration(
                     color: index < review.rating ? _getStarBackgroundColor(review.rating) : DesignTokens.gray200,
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: Center(
                     child: SvgIcon(
                       svgPath: 'assets/icons_final/star.svg',
                       width: 12,
                       height: 12,
                       color: Colors.white,
                     ),
                   ),
                 ),
               );
             }),
           ),
          
          const SizedBox(height: 8),
          
          // Service description
          Row(
            children: [
              MyText(
                text: 'Dịch vụ : ',
                textStyle: 'body',
                textSize: '12',
                color: DesignTokens.secondaryGreen,
              ),
              MyText(
                text: review.serviceName,
                textStyle: 'body',
                textSize: '12',
                textColor: 'primary',
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Comment
          MyText(
            text: review.comment,
            textStyle: 'body',
            textSize: '12',
            textColor: 'primary',
          ),
        ],
      ),
    );
  }



  Color _getStarBackgroundColor(int rating) {
    if (rating >= 4) {
      return DesignTokens.secondaryGreen;
    } else if (rating >= 3) {
      return DesignTokens.secondaryYellow;
    } else {
      return DesignTokens.secondaryOrange;
    }
  }
}
