import 'package:gara/config.dart';

/// Chuẩn hoá đường dẫn ảnh:
/// - Nếu null hoặc rỗng -> null
/// - Nếu đã là http/https -> giữ nguyên
/// - Nếu là đường dẫn tương đối (bắt đầu bằng '/' hoặc không) -> thêm origin từ Config.baseUrl
String? resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  final trimmed = path.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = Uri.parse(Config.baseUrl);
  final origin = base.hasPort
      ? '${base.scheme}://${base.host}:${base.port}'
      : '${base.scheme}://${base.host}';
  if (trimmed.startsWith('/')) {
    return origin + trimmed;
  }
  return '$origin/$trimmed';
}


