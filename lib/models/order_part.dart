class OrderPart {
  final int? id;
  final int orderId;
  final int partId;
  final int quantity;
  final double price;
  final double subtotal;

  OrderPart({
    this.id,
    required this.orderId,
    required this.partId,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'part_id': partId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory OrderPart.fromMap(Map<String, dynamic> map) {
    return OrderPart(
      id: map['id'],
      orderId: map['order_id'],
      partId: map['part_id'],
      quantity: map['quantity'],
      price: map['price'],
      subtotal: map['subtotal'],
    );
  }
}
