import 'dart:convert';
import 'package:flutter/foundation.dart';

class DebugLogger {
  DebugLogger._();

  /// In JSON dài theo từng khối để tránh bị cắt trong console/Logcat.
  /// - [tag]: tiêu đề cho log
  /// - [data]: object Map/List hoặc bất kỳ; sẽ cố gắng stringify đẹp
  /// - [chunkSize]: kích thước mỗi khối, mặc định 800 ký tự
  /// - [highlightYellow]: nếu true, bọc log bằng ANSI màu vàng (nếu terminal hỗ trợ)
  static void largeJson(
    String tag,
    dynamic data, {
    int chunkSize = 800,
    bool highlightYellow = true,
  }) {
    try {
      String pretty;
      if (data is String) {
        pretty = data;
      } else {
        pretty = const JsonEncoder.withIndent('  ').convert(data);
      }
      if (pretty.isEmpty) {
        final start = highlightYellow ? '\x1B[33m' : '';
        final end = highlightYellow ? '\x1B[0m' : '';
        debugPrint('$start$tag <empty>$end');
        return;
      }
      final int total = pretty.length;
      int part = 1;
      final start = highlightYellow ? '\x1B[33m' : '';
      final end = highlightYellow ? '\x1B[0m' : '';
      for (int i = 0; i < total; i += chunkSize) {
        final endIndex = (i + chunkSize < total) ? i + chunkSize : total;
        debugPrint('${start}$tag [$part] ${pretty.substring(i, endIndex)}${end}');
        part++;
      }
    } catch (e) {
      final start = highlightYellow ? '\x1B[33m' : '';
      final end = highlightYellow ? '\x1B[0m' : '';
      debugPrint('${start}$tag <failed to print: $e>${end}');
    }
  }
}


