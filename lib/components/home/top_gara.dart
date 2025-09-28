import 'package:flutter/material.dart';
import 'package:gara/models/gara/gara_model.dart';
import 'package:gara/theme/color.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class TopGara extends StatelessWidget {
  const TopGara({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: MyColors.white['c900']!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  MyText(
                    text: 'Top Gara',
                    textStyle: 'title',
                    textSize: '16',
                    textColor: 'primary',
                  ),
                  MyText(
                    text: ' • ',
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'tertiary',
                  ),
                  MyText(
                    text: 'Theo tuần',
                    textStyle: 'body',
                    textSize: '12',
                    textColor: 'tertiary',
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to see more
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
          // Top Gara List
           Column(
             children: [
               // Header row với #, Garage, số việc trong tuần
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                 child: Row(
                   children: [
                     // # column
                     SizedBox(
                       width: 32,
                       child: MyText(
                         text: '#',
                         textStyle: 'body',
                         textSize: '12',
                         textColor: 'tertiary',
                       ),
                     ),
                     const SizedBox(width: 16),
                     // Garage column
                     Expanded(
                       child: MyText(
                         text: 'Garage',
                         textStyle: 'body',
                         textSize: '12',
                         textColor: 'tertiary',
                       ),
                     ),
                     // Số việc trong tuần column
                     MyText(
                       text: 'Số việc trong tuần',
                       textStyle: 'body',
                       textSize: '12',
                       textColor: 'tertiary',
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 8),
              _buildTopGaraItem(
                rank: 1,
                gara: GaraModel(
                  image: 'assets/images/gara_image_default.png',
                  title: 'Vietnam care',
                  description: 'Gara chuyên nghiệp',
                ),
                weeklyJobs: 15,
              ),
              const SizedBox(height: 12),
              _buildTopGaraItem(
                rank: 2,
                gara: GaraModel(
                  image: 'assets/images/gara_image_default.png',
                  title: 'Vietnam care',
                  description: 'Gara chuyên nghiệp',
                ),
                weeklyJobs: 15,
              ),
              const SizedBox(height: 12),
              _buildTopGaraItem(
                rank: 3,
                gara: GaraModel(
                  image: 'assets/images/gara_image_default.png',
                  title: 'Vietnam care',
                  description: 'Gara chuyên nghiệp',
                ),
                weeklyJobs: 15,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopGaraItem({
    required int rank,
    required GaraModel gara,
    required int weeklyJobs,
  }) {
    // Chọn SVG icon dựa trên rank
    String rankSvgPath;
    String rankSvgPath2;
    switch (rank) {
      case 1:
        rankSvgPath = 'assets/icons_final/top1.svg';
        rankSvgPath2 = 'assets/icons_final/vtop1.svg';
        break;
      case 2:
        rankSvgPath = 'assets/icons_final/top2.svg';
        rankSvgPath2 = 'assets/icons_final/vtop2.svg';
        break;
      case 3:
        rankSvgPath = 'assets/icons_final/top3.svg';
        rankSvgPath2 = 'assets/icons_final/vtop3.svg';
        break;
      default:
        rankSvgPath = 'assets/icons_final/top3.svg';
        rankSvgPath2 = 'assets/icons_final/vtop3.svg';
    }

    return Container(
      // height: 48,
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(rank), // #006FFD
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rank Number
          SizedBox(
            width: 32,
            child: MyText(
              text: rank.toString(),
              textStyle: 'title',
              textSize: '14',
              textColor: 'primary',
            ),
          ),
            // Ranking Badge với SVG
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/gara_image_default.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 32,
                            height: 32,
                            color: DesignTokens.gray100,
                            child: Icon(
                              Icons.garage,
                              color: DesignTokens.gray500,
                              size: 16,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // SVG background
                  SvgIcon(
                    svgPath: rankSvgPath,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                  // Avatar image ở chính giữa
                  
                ],
              ),
            ),
          const SizedBox(width: 16),
          
          // Garage Name
          Expanded(
            child: Row(
              children: [
                MyText(
                  text: gara.title!,
                  textStyle: 'title',
                  textSize: '14',
                  textColor: 'primary',
                ),
                SizedBox(width: 8),
                SvgIcon(
                  svgPath: rankSvgPath2,
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          
          
          
          // Weekly Jobs Count
          MyText(
            text: weeklyJobs.toString(),
            textStyle: 'body',
            textSize: '16',
            textColor: 'secondary',
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(int rank) {
    switch (rank) {
      case 1:
        return DesignTokens.primaryBlue;
      case 2:
        return DesignTokens.primaryBlue2;
      case 3:
        return DesignTokens.primaryBlue3;
      default:
        return DesignTokens.primaryBlue4;
    }
  }
     
}
