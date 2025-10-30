import 'package:flutter/material.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/utils/url.dart';
import 'package:video_player/video_player.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<FileInfo> files;
  final int initialIndex;

  const FullscreenImageViewer({super.key, required this.files, this.initialIndex = 0});

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late final TransformationController _transformController;
  int _currentIndex = 0;
  bool _isZoomed = false;
  Offset? _lastDoubleTapPos;
  double _dragDy = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, (widget.files.length - 1).clamp(0, widget.files.length));
    _pageController = PageController(initialPage: _currentIndex);
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaFiles = widget.files.where((f) => f.isImage || f.isVideo).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_currentIndex + 1}/${mediaFiles.length}'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          _dragDy += details.delta.dy;
        },
        onVerticalDragEnd: (details) {
          if (_dragDy > 80 || details.primaryVelocity != null && details.primaryVelocity! > 800) {
            Navigator.maybePop(context);
          }
          _dragDy = 0.0;
        },
        child: PageView.builder(
          controller: _pageController,
          physics: _isZoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          itemCount: mediaFiles.length,
          onPageChanged: (i) {
            setState(() {
              _currentIndex = i;
              _isZoomed = false;
              _transformController.value = Matrix4.identity();
            });
          },
          itemBuilder: (context, index) {
            final file = mediaFiles[index];
            final url = resolveImageUrl(file.path);
            if (url == null) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48));
            }

            if (file.isVideo) {
              return _VideoViewer(url: url);
            } else {
              return StatefulBuilder(
                builder: (context, setLocalState) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTapDown: (details) => _lastDoubleTapPos = details.localPosition,
                    onDoubleTap: () {
                      final targetScale = _isZoomed ? 1.0 : 2.0;
                      final focal = _lastDoubleTapPos ?? Offset.zero;
                      // Tạo ma trận để zoom vào vị trí double-tap
                      final m = Matrix4.identity();
                      if (targetScale > 1.0) {
                        m.translate(-focal.dx * (targetScale - 1), -focal.dy * (targetScale - 1));
                      }
                      m.scale(targetScale);
                      setState(() {
                        _transformController.value = m;
                        _isZoomed = targetScale > 1.0;
                      });
                    },
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      panEnabled: _isZoomed,
                      scaleEnabled: true,
                      minScale: 1.0,
                      maxScale: 5.0,
                      boundaryMargin: _isZoomed ? const EdgeInsets.all(80) : EdgeInsets.zero,
                      clipBehavior: Clip.none,
                      onInteractionUpdate: (details) {
                        final m = _transformController.value;
                        final scale = m.getMaxScaleOnAxis();
                        final nowZoomed = scale > 1.01;
                        if (nowZoomed != _isZoomed) {
                          setState(() => _isZoomed = nowZoomed);
                        }
                      },
                      onInteractionEnd: (_) {
                        // Nếu về lại scale 1 thì reset ma trận để cố định vị trí
                        final m = _transformController.value;
                        if (m.getMaxScaleOnAxis() <= 1.01) {
                          _transformController.value = Matrix4.identity();
                          if (_isZoomed) setState(() => _isZoomed = false);
                        }
                      },
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final String url;

  const _VideoViewer({required this.url});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  final TransformationController _videoTransform = TransformationController();
  bool _videoZoomed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller!.initialize();
      _duration = _controller!.value.duration;
      _controller!.addListener(() {
        final v = _controller!;
        if (!mounted) return;
        setState(() {
          _position = v.value.position;
          _isPlaying = v.value.isPlaying;
        });
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      DebugLogger.log('[FullscreenImageViewer] Error initializing video: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text('Không thể tải video', style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }

    final totalMs = _duration.inMilliseconds.clamp(1, 1 << 31);
    final value = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: InteractiveViewer(
                transformationController: _videoTransform,
                panEnabled: _videoZoomed,
                minScale: 1.0,
                maxScale: 4.0,
                onInteractionUpdate: (_) {
                  final scale = _videoTransform.value.getMaxScaleOnAxis();
                  final nowZoomed = scale > 1.01;
                  if (nowZoomed != _videoZoomed) {
                    setState(() => _videoZoomed = nowZoomed);
                  }
                },
                onInteractionEnd: (_) {
                  final scale = _videoTransform.value.getMaxScaleOnAxis();
                  if (scale <= 1.01) {
                    _videoTransform.value = Matrix4.identity();
                    if (_videoZoomed) setState(() => _videoZoomed = false);
                  }
                },
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          // Play/Pause overlay
          Center(
            child: AnimatedOpacity(
              opacity: _isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
              ),
            ),
          ),
          // Seek bar + controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: value.isNaN ? 0.0 : value,
                        onChanged: (v) {
                          final target = Duration(milliseconds: (v * _duration.inMilliseconds).toInt());
                          _controller?.seekTo(target);
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                    Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}
