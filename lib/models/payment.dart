class Payment {
  final int? id;
  final int orderId;
  final int customerId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? notes;

  Payment({
    this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
  });

  static String normalizePaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case 'Ti\u1ec1n m\u1eb7t':
        return 'Cash';
      case 'Chuy\u1ec3n kho\u1ea3n':
        return 'Bank Transfer';
      case 'Th\u1ebb':
        return 'Card';
      default:
        return paymentMethod;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      orderId: map['order_id'],
      customerId: map['customer_id'],
      amount: map['amount'],
      paymentDate: DateTime.parse(map['payment_date']),
      paymentMethod: normalizePaymentMethod(map['payment_method']),
      notes: map['notes'],
    );
  }
}
