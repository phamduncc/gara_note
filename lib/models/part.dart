class Part {
  final int? id;
  final String name;
  final String partCode;
  final String vehicleType;
  final double purchasePrice;
  final double sellingPrice;
  final int quantity;
  final int minQuantity;
  final String? supplier;
  final DateTime createdAt;

  Part({
    this.id,
    required this.name,
    required this.partCode,
    required this.vehicleType,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    this.minQuantity = 5,
    this.supplier,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static String normalizeVehicleType(String vehicleType) {
    if (vehicleType == String.fromCharCodes([67, 104, 117, 110, 103])) {
      return 'General';
    }

    switch (vehicleType) {
      case 'Xe m\u00e1y':
        return 'Motorcycle';
      case '\u00d4 t\u00f4':
        return 'Car';
      default:
        return vehicleType;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'part_code': partCode,
      'vehicle_type': vehicleType,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'supplier': supplier,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'],
      name: map['name'],
      partCode: map['part_code'],
      vehicleType: normalizeVehicleType(map['vehicle_type']),
      purchasePrice: map['purchase_price'],
      sellingPrice: map['selling_price'],
      quantity: map['quantity'],
      minQuantity: map['min_quantity'] ?? 5,
      supplier: map['supplier'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Part copyWith({
    int? id,
    String? name,
    String? partCode,
    String? vehicleType,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    int? minQuantity,
    String? supplier,
    DateTime? createdAt,
  }) {
    return Part(
      id: id ?? this.id,
      name: name ?? this.name,
      partCode: partCode ?? this.partCode,
      vehicleType: vehicleType ?? this.vehicleType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      supplier: supplier ?? this.supplier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isLowStock => quantity <= minQuantity;
}
