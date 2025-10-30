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
