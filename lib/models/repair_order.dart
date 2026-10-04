class RepairOrder {
  final int? id;
  final String orderCode;
  final int customerId;
  final int vehicleId;
  final DateTime orderDate;
  final String status;
  final String repairItems;
  final double laborCost;
  final double discount;
  final double totalAmount;
  final String? technicalNotes;
  final DateTime createdAt;

  RepairOrder({
    this.id,
    required this.orderCode,
    required this.customerId,
    required this.vehicleId,
    required this.orderDate,
    required this.status,
    required this.repairItems,
    required this.laborCost,
    this.discount = 0,
    required this.totalAmount,
    this.technicalNotes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static String normalizeStatus(String status) {
    switch (status) {
      case 'Ch\u1edd s\u1eeda':
        return 'Pending';
      case '\u0110ang s\u1eeda':
        return 'In Progress';
      case 'Ho\u00e0n th\u00e0nh':
        return 'Completed';
      case '\u0110\u00e3 thanh to\u00e1n':
        return 'Paid';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_code': orderCode,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'repair_items': repairItems,
      'labor_cost': laborCost,
      'discount': discount,
      'total_amount': totalAmount,
      'technical_notes': technicalNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RepairOrder.fromMap(Map<String, dynamic> map) {
    return RepairOrder(
      id: map['id'],
      orderCode: map['order_code'],
      customerId: map['customer_id'],
      vehicleId: map['vehicle_id'],
      orderDate: DateTime.parse(map['order_date']),
      status: normalizeStatus(map['status']),
      repairItems: map['repair_items'],
      laborCost: map['labor_cost'],
      discount: map['discount'] ?? 0,
      totalAmount: map['total_amount'],
      technicalNotes: map['technical_notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  RepairOrder copyWith({
    int? id,
    String? orderCode,
    int? customerId,
    int? vehicleId,
    DateTime? orderDate,
    String? status,
    String? repairItems,
    double? laborCost,
    double? discount,
    double? totalAmount,
    String? technicalNotes,
    DateTime? createdAt,
  }) {
    return RepairOrder(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      repairItems: repairItems ?? this.repairItems,
      laborCost: laborCost ?? this.laborCost,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      technicalNotes: technicalNotes ?? this.technicalNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
