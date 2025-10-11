class PaymentModel {
  final String transactionId;
  final String qrCode;
  final String qrText;
  final int amount;
  final String expiresAt;
  final int status;
  final String? statusText;
  final String? paidAt;
  final String createdAt;
  final double? pollingTime;
  final bool? finalStatus;
  final int? quotationId;

  PaymentModel({
    required this.transactionId,
    required this.qrCode,
    required this.qrText,
    required this.amount,
    required this.expiresAt,
    required this.status,
    this.statusText,
    this.paidAt,
    required this.createdAt,
    this.pollingTime,
    this.finalStatus,
    this.quotationId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      transactionId: json['transaction_id'] ?? '',
      qrCode: json['qr_code'] ?? '',
      qrText: json['qr_text'] ?? '',
      amount: json['amount'] ?? 0,
      expiresAt: json['expires_at'] ?? '',
      status: json['status'] ?? 1,
      statusText: json['status_text'],
      paidAt: json['paid_at'],
      createdAt: json['created_at'] ?? '',
      pollingTime: json['polling_time']?.toDouble(),
      finalStatus: json['final_status'],
      quotationId: json['quotation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'qr_code': qrCode,
      'qr_text': qrText,
      'amount': amount,
      'expires_at': expiresAt,
      'status': status,
      'status_text': statusText,
      'paid_at': paidAt,
      'created_at': createdAt,
      'polling_time': pollingTime,
      'final_status': finalStatus,
      'quotation_id': quotationId,
    };
  }

  // Payment status constants
  static const int pending = 1;
  static const int completed = 2;
  static const int expired = 3;

  bool get isPending => status == pending;
  bool get isCompleted => status == completed;
  bool get isExpired => status == expired;
}
