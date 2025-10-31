String formatCurrency(num value) {
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

String formatMessageTime(String timeString) {
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

String formatLicensePlate(String? raw) {
  if (raw == null) return '';
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (cleaned.length <= 5) return cleaned;
  final head = cleaned.substring(0, cleaned.length - 5);
  final tail = cleaned.substring(cleaned.length - 5);
  return '$head-$tail';
}
