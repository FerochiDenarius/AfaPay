class TransactionPreview {
  const TransactionPreview({
    required this.type,
    required this.amount,
    required this.status,
    required this.time,
    this.currency = 'NGN',
  });

  final String type;
  final double amount;
  final String status;
  final DateTime time;
  final String currency;

  factory TransactionPreview.fromJson(Map<String, dynamic> json) {
    final rawTime =
        json['time'] as String? ??
        json['createdAt'] as String? ??
        json['updatedAt'] as String?;

    return TransactionPreview(
      type: json['type'] as String? ?? 'transaction',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      time: DateTime.tryParse(rawTime ?? '') ?? DateTime.now(),
      currency: json['currency'] as String? ?? 'NGN',
    );
  }
}
