import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/models/messaging/messaging_models.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/utils/status/quotation_status.dart';
import 'package:gara/utils/status/status_widget.dart';
import 'package:gara/widgets/fullscreen_image_viewer.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

// Helper functions moved from chat_room_screen.dart
String _formatMessageTime(String timeString) {
  try {
    final time = DateTime.parse(timeString);
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    return timeString;
  }
}

String _formatCurrency(num value) {
  final digits = value.toInt().toString();
  final buffer = StringBuffer();
  final len = digits.length;
  for (int i = 0; i < len; i++) {
    buffer.write(digits[i]);
    final nextPos = len - i - 1;
    final isThousandBreak = nextPos % 3 == 0 && i != len - 1;
    if (isThousandBreak) buffer.write('.');
  }
  return buffer.toString();
}

class MessageBubble extends StatelessWidget {
  final MessageData message;
  final int currentUserId;
  final RoomData? room;

  // Message states
  final bool isFailed;
  final bool isRetrying;
  final bool isPending;
  final double uploadProgress;

  // Callbacks
  final VoidCallback onRetrySendText;
  final VoidCallback onRetrySendMedia;

  // Thumbnail states for local media display
  final Map<String, String?> videoThumbnails;
  final Map<String, bool> generatingThumbnails;
  final Map<String, double> videoAspectRatios;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.room,
    required this.isFailed,
    required this.isRetrying,
    required this.isPending,
    required this.uploadProgress,
    required this.onRetrySendText,
    required this.onRetrySendMedia,
    required this.videoThumbnails,
    required this.generatingThumbnails,
    required this.videoAspectRatios,
  });

  bool get isMe => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final type = int.tryParse(message.messageType ?? '1') ?? 1;

    // Route to the correct bubble type
    switch (type) {
      case 2:
        return _buildMediaBubble(context);
      case 3:
        return _buildMediaBubble(context);
      case 4:
      case 6:
        return _buildCenterLine(message.message);
      case 7:
        return _buildCenterLine(message.message, color: DesignTokens.alertError);
      case 5:
        return _buildBookingCard(context);
      case 1:
      default:
        return _buildTextBubble(context);
    }
  }

  // --- Bubble Types ---

  Widget _buildTextBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? DesignTokens.surfaceBrand : DesignTokens.surfacePrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: !isMe ? Border.all(color: DesignTokens.borderSecondary) : null,
                  ),
                  child: MyText(
                    text: message.message,
                    textStyle: 'body',
                    textSize: '14',
                    textColor: isMe ? 'invert' : 'primary',
                  ),
                ),
                const SizedBox(height: 4),
                _buildMessageStatus(onRetry: onRetrySendText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBubble(BuildContext context) {
    final mediaUrl = message.fileUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) _buildAvatar(),
              Flexible(
                child: Builder(
                  builder: (context) {
                    final maxWidth = MediaQuery.of(context).size.width * 0.6;
                    final content = _buildMediaContent(context, mediaUrl);

                    return SizedBox(
                      width: maxWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: isMe
                            ? content
                            : Container(
                                color: DesignTokens.surfaceSecondary,
                                child: content,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 48), // align time with media, not avatar
            child: _buildMessageStatus(onRetry: onRetrySendMedia),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    final md = message.metadata ?? const {};
    DebugLogger.largeJson('[MessageBubble] buildBookingCard metadata', {
      'messageId': message.messageId,
      'metadata': md,
    });
    final garageName = (md['garage_name'] ?? md['garage'] ?? 'Smart Auto Care').toString();
    final time = (md['time'] ?? md['booking_time'] ?? md['schedule_time'] ?? '').toString();
    final priceNum = int.tryParse((md['price'] ?? md['quotation']?['price'] ?? '0').toString()) ?? 0;
    final statusString = (md['deposit_status'] ?? '').toString();
    final statusValue = int.tryParse(statusString) ?? 4;
    final quotationStatus = QuotationStatus.fromValue(statusValue);

    return Column(
      children: [
        if (message.message.isNotEmpty) _buildCenterLine(message.message),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: DesignEffects.medCardShadow,
                border: Border.all(color: DesignTokens.borderBrandSecondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MyText(text: garageName, textStyle: 'head', textSize: '14', textColor: 'primary'),
                      ),
                      StatusWidget(status: quotationStatus, type: StatusType.quotation),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MyText(text: 'Thời gian:', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                      ),
                      MyText(
                        text: time.isNotEmpty ? time : '—',
                        textStyle: 'title',
                        textSize: '14',
                        textColor: 'primary',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: MyText(text: 'Giá:', textStyle: 'body', textSize: '14', textColor: 'tertiary')),
                      MyText(
                        text: '${_formatCurrency(priceNum)}đ',
                        textStyle: 'head',
                        textSize: '16',
                        textColor: 'brand',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterLine(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [MyText(text: text, textStyle: 'label', textSize: '12', color: color ?? DesignTokens.textTertiary)],
      ),
    );
  }

  // --- UI Components & Helpers ---

  Widget _buildAvatar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: DesignTokens.primaryBlue, borderRadius: BorderRadius.circular(20)),
          child: (room?.otherUserAvatar != null && room!.otherUserAvatar!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    room!.otherUserAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _defaultAvatarIcon(),
                  ),
                )
              : _defaultAvatarIcon(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _defaultAvatarIcon() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: SvgIcon(
        svgPath: 'assets/icons_final/profile.svg',
        size: 20,
        color: Colors.white,
        fit: BoxFit.scaleDown,
      ),
    );
  }

  Widget _buildMessageStatus({required VoidCallback onRetry}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isMe && isFailed) ...[
          GestureDetector(
            onTap: onRetry,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  padding: const EdgeInsets.all(2),
                  child: SvgIcon(
                    svgPath: 'assets/icons_final/reload.svg',
                    size: 12,
                    color: DesignTokens.primaryBlue,
                  ),
                ),
                MyText(text: "Thử lại", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (isMe && isRetrying) ...[
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue)),
              ),
              const SizedBox(width: 4),
              MyText(text: "Đang thử lại...", textStyle: 'body', textSize: '12', textColor: 'placeholder'),
            ],
          ),
          const SizedBox(width: 6),
        ],
        MyText(
          text: _formatMessageTime(message.createdAt),
          textStyle: 'body',
          textSize: '12',
          textColor: 'placeholder',
        ),
        if (isMe && isPending) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
              value: isPending && uploadProgress > 0 ? uploadProgress : null,
            ),
          ),
        ],
      ],
    );
  }

  // --- Media Content Handling ---

  Widget _buildMediaContent(BuildContext context, String mediaUrl) {
    final isLocalFile = mediaUrl.isNotEmpty &&
        !mediaUrl.startsWith('http') &&
        !mediaUrl.startsWith('[') &&
        mediaUrl.contains('/') &&
        !mediaUrl.contains('storage.googleapis.com');

    if (isLocalFile) {
      final filePaths = mediaUrl.split(',');
      return _buildLocalMediaThumbnails(context, filePaths);
    } else if (mediaUrl.isNotEmpty) {
      try {
        final urls = _parseFileUrls(mediaUrl);
        if (urls.isNotEmpty) {
          return _buildServerMediaThumbnails(context, urls);
        }
      } catch (e) {
        // Fallback for single URL
        final messageType = int.tryParse(message.messageType ?? '1') ?? 1;
        if (messageType == 3) {
          return _buildVideoThumbnailWidget(videoUrl: mediaUrl, size: double.infinity, expand: true);
        } else {
          return Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildErrorMedia('Không tải được ảnh'),
          );
        }
      }
    }
    // Fallback
    return _buildErrorMedia(message.message);
  }

  Widget _buildErrorMedia(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MyText(
        text: text,
        textStyle: 'body',
        textSize: '12',
        textColor: isMe ? 'invert' : 'tertiary',
      ),
    );
  }

  List<String> _parseFileUrls(String mediaUrl) {
    try {
      if (mediaUrl.startsWith('[') && mediaUrl.endsWith(']')) {
        final List<dynamic> urls = json.decode(mediaUrl);
        return urls.map((url) => url.toString()).toList();
      }
      return [mediaUrl];
    } catch (e) {
      return [mediaUrl];
    }
  }

  List<String> _parseThumbnailUrls(String? thumbnails) {
    if (thumbnails == null || thumbnails.isEmpty) return [];
    try {
      if (thumbnails.startsWith('[') && thumbnails.endsWith(']')) {
        final List<dynamic> parsed = json.decode(thumbnails);
        return parsed.map((e) => e.toString().trim()).toList();
      } else {
        return thumbnails.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    } catch (e) {
      DebugLogger.log('[MessageBubble] Error parsing thumbnail URLs: $e');
      return thumbnails.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }

  // --- Server Media ---

  Widget _buildServerMediaThumbnails(BuildContext context, List<String> urls) {
    final messageType = int.tryParse(message.messageType ?? '1') ?? 1;
    final isVideo = messageType == 3;
    final thumbnailUrls = isVideo ? _parseThumbnailUrls(message.thumbnails) : <String>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 4.0;
        final columns = urls.length == 1 ? 1 : 2;
        final itemWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        final List<FileInfo> files = urls.take(4).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final url = entry.value;
          final name = url.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => 'media_$i');
          return FileInfo(id: i, name: name, path: url, timeUpload: '', fileType: isVideo ? 'video' : 'image');
        }).toList();

        return Container(
          width: maxWidth,
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
            children: urls.take(4).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              String? thumbnailUrl;
              if (isVideo && thumbnailUrls.isNotEmpty) {
                thumbnailUrl = thumbnailUrls.length > index ? thumbnailUrls[index] : thumbnailUrls.first;
              }
              final child = isVideo
                  ? _buildVideoThumbnailWidget(thumbnailUrl: thumbnailUrl, videoUrl: url, size: itemWidth)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: itemWidth,
                      height: itemWidth,
                      errorBuilder: (context, error, stackTrace) => Container(
                          width: itemWidth,
                          height: itemWidth,
                          color: DesignTokens.surfaceSecondary,
                          child: const Icon(Icons.broken_image, size: 20)),
                    );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FullscreenImageViewer(files: files, initialIndex: index)),
                  );
                },
                child: Container(
                  width: itemWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DesignTokens.borderSecondary),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- Local Media ---

  Widget _buildLocalMediaThumbnails(BuildContext context, List<String> filePaths) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 4.0;
        final columns = filePaths.length == 1 ? 1 : 2;
        final contentWidth = (maxWidth - 16).clamp(0.0, double.infinity); // Padding 8
        final itemWidth = (contentWidth - spacing * (columns - 1)) / columns;
        final isSingle = filePaths.length == 1;

        final List<FileInfo> files = filePaths.take(4).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final path = entry.value;
          final name = path.split('/').last;
          final isVid = path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov');
          return FileInfo(id: i, name: name, path: path, timeUpload: '', fileType: isVid ? 'video' : 'image');
        }).toList();

        return Container(
          width: maxWidth,
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
            children: filePaths.take(4).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value;
              final file = File(path);
              final isVideo = path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov');

              final double singleVideoHeight =
                  (isVideo && isSingle) ? (contentWidth / (videoAspectRatios[file.path] ?? 16 / 9)) : itemWidth;

              final mediaChild = isVideo
                  ? _buildVideoThumbnailForLocalFile(file,
                      width: itemWidth, height: singleVideoHeight, expand: isSingle)
                  : Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: itemWidth,
                      height: itemWidth,
                      errorBuilder: (context, error, stackTrace) => Container(
                          width: itemWidth,
                          height: itemWidth,
                          color: DesignTokens.surfaceSecondary,
                          child: const Icon(Icons.broken_image, size: 20)),
                    );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FullscreenImageViewer(files: files, initialIndex: index)),
                  );
                },
                child: Container(
                  width: isSingle ? contentWidth : itemWidth,
                  height: isSingle ? singleVideoHeight : itemWidth,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      mediaChild,
                      if (isPending)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: uploadProgress > 0 ? uploadProgress : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- Video Thumbnail Widgets ---

  Widget _buildVideoThumbnailForLocalFile(File file, {double? width, double? height, bool expand = false}) {
    final videoPath = file.path;
    final thumbnailPath = videoThumbnails[videoPath];
    final isGeneratingThumbnail = generatingThumbnails[videoPath] ?? false;

    if (isGeneratingThumbnail) {
      return Container(
        width: width,
        height: height,
        color: DesignTokens.surfaceSecondary,
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (thumbnailPath != null) {
      return _buildVideoThumbnailWidget(
        thumbnailUrl: thumbnailPath,
        videoUrl: file.path,
        width: width,
        height: height,
        expand: expand,
      );
    }

    return _buildDefaultVideoIcon(size: width ?? 60, fileSize: _getFileSize(file));
  }

  Widget _buildVideoThumbnailWidget({
    String? thumbnailUrl,
    required String videoUrl,
    double? size,
    double? width,
    double? height,
    bool expand = false,
    bool showPlayIcon = true,
  }) {
    final w = width ?? size ?? 60;
    final h = height ?? size ?? 60;

    Widget imageWidget;
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      if (thumbnailUrl.startsWith('http')) {
        imageWidget = Image.network(thumbnailUrl,
            fit: BoxFit.cover, width: w, height: h, errorBuilder: (c, e, s) => _buildDefaultVideoIcon(size: w));
      } else {
        imageWidget = Image.file(File(thumbnailUrl),
            fit: BoxFit.cover, width: w, height: h, errorBuilder: (c, e, s) => _buildDefaultVideoIcon(size: w));
      }
    } else {
      imageWidget = _buildDefaultVideoIcon(size: w);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (expand) Positioned.fill(child: imageWidget) else imageWidget,
        if (showPlayIcon) _buildPlayIconOverlay(),
      ],
    );
  }

  Widget _buildPlayIconOverlay({double size = 24, double iconSize = 16}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
      child: Icon(Icons.play_arrow, color: Colors.white, size: iconSize),
    );
  }

  Widget _buildDefaultVideoIcon({double size = 60, String? fileSize}) {
    return Container(
      width: size,
      height: size,
      color: DesignTokens.surfaceSecondary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_file, size: 20, color: DesignTokens.primaryBlue),
          if (fileSize != null && fileSize.isNotEmpty) ...[
            const SizedBox(height: 2),
            MyText(text: fileSize, textStyle: 'body', textSize: '10', textColor: 'tertiary'),
          ],
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      if (file.existsSync()) {
        return '${(file.lengthSync() / 1024 / 1024).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      //
    }
    return '';
  }
}
