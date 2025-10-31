import 'package:flutter/material.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/text.dart';

class MediaOptionsBottomSheet extends StatelessWidget {
  final int imageCount;
  final int videoCount;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickVideo;

  const MediaOptionsBottomSheet({
    Key? key,
    required this.imageCount,
    required this.videoCount,
    this.onPickImage,
    this.onPickVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(text: 'Chọn phương thức', textStyle: 'head', textSize: '16', textColor: 'primary'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MyButton(
                  text: imageCount >= 3 ? 'Đã đủ ảnh (3/3)' : 'Chọn ảnh ($imageCount/3)',
                  onPressed: imageCount >= 3 ? null : onPickImage,
                  buttonType: imageCount >= 3 ? ButtonType.disable : ButtonType.primary,
                  height: 40,
                  textStyle: 'label',
                  textSize: '14',
                  textColor: 'invert',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyButton(
                  text: videoCount >= 3 ? 'Đã đủ video (3/3)' : 'Chọn video ($videoCount/3)',
                  onPressed: videoCount >= 3 ? null : onPickVideo,
                  buttonType: videoCount >= 3 ? ButtonType.disable : ButtonType.secondary,
                  height: 40,
                  textStyle: 'label',
                  textSize: '14',
                  textColor: 'primary',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
