import 'package:flutter/material.dart';
import 'package:gara/widgets/skeleton.dart';
import 'package:gara/theme/index.dart';

class MessagesSkeleton extends StatelessWidget {
  final ScrollController? scrollController;
  const MessagesSkeleton({Key? key, this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DesignTokens.borderSecondary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.line(height: 14, width: 140),
                      const SizedBox(height: 6),
                      Skeleton.line(height: 10, width: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
