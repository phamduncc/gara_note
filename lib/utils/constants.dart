class AppConstants {
  static const String appName = 'GARA NOTE';
  static const String appVersion = '1.0.0';
  
  static const List<String> vehicleTypes = ['Motorcycle', 'Car'];
  static const List<String> motorcycleBrands = [
    'Honda', 'Yamaha', 'Suzuki', 'SYM', 'Piaggio', 'Other'
  ];
  static const List<String> carBrands = [
    'Toyota', 'Honda', 'Mazda', 'Hyundai', 'Kia', 'Ford', 'VinFast', 'Other'
  ];
  static const List<String> orderStatuses = [
    'Pending', 'In Progress', 'Completed', 'Paid'
  ];
  static const List<String> paymentMethods = [
    'Cash', 'Bank Transfer', 'Card'
  ];
  
  static const int defaultMinStock = 5;
}
