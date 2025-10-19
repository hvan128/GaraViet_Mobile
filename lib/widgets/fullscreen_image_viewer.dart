import 'package:flutter/material.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/utils/url.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<FileInfo> files;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.files,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late final TransformationController _transformController;
  int _currentIndex = 0;
  bool _isZoomed = false;
  Offset? _lastDoubleTapPos;

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
    final imageFiles = widget.files.where((f) => f.isImage).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_currentIndex + 1}/${imageFiles.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: _isZoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        itemCount: imageFiles.length,
        onPageChanged: (i) {
          setState(() {
            _currentIndex = i;
            _isZoomed = false;
            _transformController.value = Matrix4.identity();
          });
        },
        itemBuilder: (context, index) {
          final url = resolveImageUrl(imageFiles[index].path);
          if (url == null) {
            return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48));
          }
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
        },
      ),
    );
  }
}



