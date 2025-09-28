/// Định dạng biển số: ví dụ "30A12345" -> "30A-12345"
/// Quy tắc đơn giản:
/// - Loại bỏ mọi ký tự không phải chữ hoặc số
/// - Nếu độ dài > 5, chèn dấu gạch trước 5 ký tự cuối
/// - Nếu không đủ, trả về nguyên bản đã làm sạch
String formatLicensePlate(String? raw) {
  if (raw == null) return '';
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (cleaned.length <= 5) return cleaned;
  final head = cleaned.substring(0, cleaned.length - 5);
  final tail = cleaned.substring(cleaned.length - 5);
  return '$head-$tail';
}


