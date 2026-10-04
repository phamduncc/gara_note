import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/repair_order.dart';
import '../models/part.dart';
import '../models/order_part.dart';
import '../models/payment.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gara_note.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        full_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        vehicle_type TEXT NOT NULL,
        brand TEXT NOT NULL,
        license_plate TEXT UNIQUE NOT NULL,
        frame_number TEXT,
        engine_number TEXT,
        current_km INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE repair_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_code TEXT UNIQUE NOT NULL,
        customer_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        order_date TEXT NOT NULL,
        status TEXT NOT NULL,
        repair_items TEXT NOT NULL,
        labor_cost REAL NOT NULL,
        discount REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        technical_notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        part_code TEXT UNIQUE NOT NULL,
        vehicle_type TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        min_quantity INTEGER DEFAULT 5,
        supplier TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        part_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES repair_orders (id),
        FOREIGN KEY (part_id) REFERENCES parts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (order_id) REFERENCES repair_orders (id),
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'owner',
      'full_name': 'Manager',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehicles', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  Future<List<Vehicle>> getVehiclesByCustomer(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehicles', where: 'customer_id = ?', whereArgs: [customerId]);
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  Future<Vehicle?> getVehicleByLicensePlate(String licensePlate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehicles', where: 'license_plate = ?', whereArgs: [licensePlate]);
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update('vehicles', vehicle.toMap(), where: 'id = ?', whereArgs: [vehicle.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRepairOrder(RepairOrder order) async {
    final db = await database;
    return await db.insert('repair_orders', order.toMap());
  }

  Future<List<RepairOrder>> getRepairOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('repair_orders', orderBy: 'order_date DESC');
    return List.generate(maps.length, (i) => RepairOrder.fromMap(maps[i]));
  }

  Future<List<RepairOrder>> getRepairOrdersByVehicle(int vehicleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('repair_orders', where: 'vehicle_id = ?', whereArgs: [vehicleId], orderBy: 'order_date DESC');
    return List.generate(maps.length, (i) => RepairOrder.fromMap(maps[i]));
  }

  Future<RepairOrder?> getRepairOrderByCode(String orderCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('repair_orders', where: 'order_code = ?', whereArgs: [orderCode]);
    if (maps.isEmpty) return null;
    return RepairOrder.fromMap(maps.first);
  }

  Future<int> updateRepairOrder(RepairOrder order) async {
    final db = await database;
    return await db.update('repair_orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<int> deleteRepairOrder(int id) async {
    final db = await database;
    return await db.delete('repair_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> generateOrderCode() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM repair_orders');
    final count = result.first['count'] as int;
    final now = DateTime.now();
    return 'RO${now.year}${now.month.toString().padLeft(2, '0')}${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<int> insertPart(Part part) async {
    final db = await database;
    return await db.insert('parts', part.toMap());
  }

  Future<List<Part>> getParts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parts', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Part.fromMap(maps[i]));
  }

  Future<List<Part>> getLowStockParts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM parts WHERE quantity <= min_quantity');
    return List.generate(maps.length, (i) => Part.fromMap(maps[i]));
  }

  Future<Part?> getPartById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Part.fromMap(maps.first);
  }

  Future<int> updatePart(Part part) async {
    final db = await database;
    return await db.update('parts', part.toMap(), where: 'id = ?', whereArgs: [part.id]);
  }

  Future<int> deletePart(int id) async {
    final db = await database;
    return await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Part>> searchParts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parts',
      where: 'name LIKE ? OR part_code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Part.fromMap(maps[i]));
  }

  Future<int> insertOrderPart(OrderPart orderPart) async {
    final db = await database;
    return await db.insert('order_parts', orderPart.toMap());
  }

  Future<List<OrderPart>> getOrderParts(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('order_parts', where: 'order_id = ?', whereArgs: [orderId]);
    return List.generate(maps.length, (i) => OrderPart.fromMap(maps[i]));
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsByOrder(int orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payments', where: 'order_id = ?', whereArgs: [orderId]);
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<List<Payment>> getPaymentsByCustomer(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('payments', where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'payment_date DESC');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<User?> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<Map<String, dynamic>> getStatistics(DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    final revenueResult = await db.rawQuery('''
      SELECT SUM(total_amount) as total_revenue, COUNT(*) as total_orders
      FROM repair_orders
      WHERE order_date BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final paidResult = await db.rawQuery('''
      SELECT SUM(amount) as total_paid
      FROM payments
      WHERE payment_date BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final topParts = await db.rawQuery('''
      SELECT p.name, p.part_code, SUM(op.quantity) as total_sold
      FROM order_parts op
      JOIN parts p ON op.part_id = p.id
      JOIN repair_orders ro ON op.order_id = ro.id
      WHERE ro.order_date BETWEEN ? AND ?
      GROUP BY p.id
      ORDER BY total_sold DESC
      LIMIT 5
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final totalRevenue = (revenueResult.first['total_revenue'] as num?) ?? 0;
    final totalPaid = (paidResult.first['total_paid'] as num?) ?? 0;
    
    return {
      'total_revenue': totalRevenue,
      'total_orders': revenueResult.first['total_orders'] ?? 0,
      'total_paid': totalPaid,
      'debt': totalRevenue - totalPaid,
      'top_parts': topParts,
    };
  }

  Future<List<Map<String, dynamic>>> getDebtList() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        c.id, c.name, c.phone,
        COALESCE(SUM(ro.total_amount), 0) as total_amount,
        COALESCE(SUM(p.amount), 0) as total_paid,
        COALESCE(SUM(ro.total_amount), 0) - COALESCE(SUM(p.amount), 0) as debt
      FROM customers c
      LEFT JOIN repair_orders ro ON c.id = ro.customer_id
      LEFT JOIN payments p ON c.id = p.customer_id
      GROUP BY c.id
      HAVING debt > 0
      ORDER BY debt DESC
    ''');
    return result;
  }

  Future<int> getCustomerCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return result.first['count'] as int;
  }

  Future<int> getActiveRepairCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM repair_orders WHERE status NOT IN ('Paid', '\u0110\u00e3 thanh to\u00e1n')",
    );
    return result.first['count'] as int;
  }

  Future<int> getLowStockCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM parts WHERE quantity <= min_quantity');
    return result.first['count'] as int;
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'gara_note.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
