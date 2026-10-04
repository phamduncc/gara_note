class Vehicle {
  final int? id;
  final int customerId;
  final String vehicleType;
  final String brand;
  final String licensePlate;
  final String? frameNumber;
  final String? engineNumber;
  final int? currentKm;
  final DateTime createdAt;

  Vehicle({
    this.id,
    required this.customerId,
    required this.vehicleType,
    required this.brand,
    required this.licensePlate,
    this.frameNumber,
    this.engineNumber,
    this.currentKm,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static String normalizeVehicleType(String vehicleType) {
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
      'customer_id': customerId,
      'vehicle_type': vehicleType,
      'brand': brand,
      'license_plate': licensePlate,
      'frame_number': frameNumber,
      'engine_number': engineNumber,
      'current_km': currentKm,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      customerId: map['customer_id'],
      vehicleType: normalizeVehicleType(map['vehicle_type']),
      brand: map['brand'],
      licensePlate: map['license_plate'],
      frameNumber: map['frame_number'],
      engineNumber: map['engine_number'],
      currentKm: map['current_km'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Vehicle copyWith({
    int? id,
    int? customerId,
    String? vehicleType,
    String? brand,
    String? licensePlate,
    String? frameNumber,
    String? engineNumber,
    int? currentKm,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      licensePlate: licensePlate ?? this.licensePlate,
      frameNumber: frameNumber ?? this.frameNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      currentKm: currentKm ?? this.currentKm,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
