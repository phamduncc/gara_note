import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/repair_order.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../models/part.dart';
import '../../models/order_part.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';

class RepairFormScreen extends StatefulWidget {
  const RepairFormScreen({super.key});

  @override
  State<RepairFormScreen> createState() => _RepairFormScreenState();
}

class _RepairFormScreenState extends State<RepairFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final TextEditingController _repairItemsController = TextEditingController();
  final TextEditingController _laborCostController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _technicalNotesController = TextEditingController();

  Customer? _selectedCustomer;
  Vehicle? _selectedVehicle;
  String _status = 'Pending';
  List<Customer> _customers = [];
  List<Vehicle> _vehicles = [];
  List<Part> _availableParts = [];
  List<Map<String, dynamic>> _selectedParts = [];

  bool _isLoading = false;

  final List<String> _statuses = ['Pending', 'In Progress', 'Completed', 'Paid'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _repairItemsController.dispose();
    _laborCostController.dispose();
    _discountController.dispose();
    _technicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final customers = await _dbHelper.getCustomers();
    final parts = await _dbHelper.getParts();
    setState(() {
      _customers = customers;
      _availableParts = parts;
    });
  }

  Future<void> _loadVehicles(int customerId) async {
    final vehicles = await _dbHelper.getVehiclesByCustomer(customerId);
    setState(() {
      _vehicles = vehicles;
      _selectedVehicle = null;
    });
  }

  double _calculateTotal() {
    double laborCost = double.tryParse(_laborCostController.text) ?? 0;
    double partsTotal = _selectedParts.fold(0, (sum, item) => sum + item['subtotal']);
    double discount = double.tryParse(_discountController.text) ?? 0;
    return laborCost + partsTotal - discount;
  }

  void _addPart() {
    showDialog(
      context: context,
      builder: (context) {
        Part? selectedPart;
        int quantity = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Part'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Part>(
                    value: selectedPart,
                    decoration: const InputDecoration(
                      labelText: 'Select part',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: _availableParts.map((part) {
                      return DropdownMenuItem(
                        value: part,
                        child: Text('${part.name} (${part.quantity} left)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedPart = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: '1',
                    onChanged: (value) {
                      quantity = int.tryParse(value) ?? 1;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedPart != null && quantity > 0) {
                      if (quantity > selectedPart!.quantity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough stock in inventory'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _selectedParts.add({
                          'part': selectedPart,
                          'quantity': quantity,
                          'price': selectedPart!.sellingPrice,
                          'subtotal': selectedPart!.sellingPrice * quantity,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inventory,
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and vehicle')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderCode = await _dbHelper.generateOrderCode();
      final order = RepairOrder(
        orderCode: orderCode,
        customerId: _selectedCustomer!.id!,
        vehicleId: _selectedVehicle!.id!,
        orderDate: DateTime.now(),
        status: _status,
        repairItems: _repairItemsController.text.trim(),
        laborCost: double.tryParse(_laborCostController.text) ?? 0,
        discount: double.tryParse(_discountController.text) ?? 0,
        totalAmount: _calculateTotal(),
        technicalNotes: _technicalNotesController.text.trim().isEmpty
            ? null
            : _technicalNotesController.text.trim(),
      );

      final orderId = await _dbHelper.insertRepairOrder(order);

      for (var item in _selectedParts) {
        final part = item['part'] as Part;
        await _dbHelper.insertOrderPart(OrderPart(
          orderId: orderId,
          partId: part.id!,
          quantity: item['quantity'],
          price: item['price'],
          subtotal: item['subtotal'],
        ));

        await _dbHelper.updatePart(part.copyWith(
          quantity: part.quantity - item['quantity'] as int,
        ));
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repair order created')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Create Repair Order',
        mainColor: AppColors.repair,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.featureGradient(AppColors.repair),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.repair.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.assignment_add, color: Colors.white, size: 32),
              ),
            ),

            // Customer & Vehicle
            _buildFormCard([
              const SectionHeader(title: 'CUSTOMER & VEHICLE'),
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Select customer *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                items: _customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text('${customer.name} - ${customer.phone}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCustomer = value);
                  if (value != null) _loadVehicles(value.id!);
                },
                validator: (value) => value == null ? 'Please select a customer' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Vehicle>(
                value: _selectedVehicle,
                decoration: InputDecoration(
                  labelText: 'Select vehicle *',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  hintText: _selectedCustomer == null
                      ? 'Select a customer first'
                      : _vehicles.isEmpty
                          ? 'This customer has no vehicles'
                          : 'Select vehicle',
                ),
                items: _vehicles.isEmpty
                    ? null
                    : _vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle,
                          child: Text('${vehicle.licensePlate} - ${vehicle.brand}'),
                        );
                      }).toList(),
                onChanged: _selectedCustomer == null || _vehicles.isEmpty
                    ? null
                    : (value) => setState(() => _selectedVehicle = value),
                validator: (value) => value == null ? 'Please select a vehicle' : null,
              ),
            ]),
            const SizedBox(height: 16),

            // Repair Items
            _buildFormCard([
              const SectionHeader(title: 'REPAIR DETAILS'),
              TextFormField(
                controller: _repairItemsController,
                decoration: const InputDecoration(
                  labelText: 'Repair items *',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter repair items' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _technicalNotesController,
                decoration: const InputDecoration(
                  labelText: 'Technical notes',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 16),

            // Parts
            _buildFormCard([
              Row(
                children: [
                  const Expanded(child: SectionHeader(title: 'REPLACEMENT PARTS')),
                  TextButton.icon(
                    onPressed: _addPart,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.inventory),
                  ),
                ],
              ),
              if (_selectedParts.isNotEmpty)
                ..._selectedParts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final part = item['part'] as Part;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inventory.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.inventory.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(part.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${item['quantity']} x ${currencyFormat.format(item['price'])}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item['subtotal']),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _selectedParts.removeAt(index)),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: AppColors.error, size: 18),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ]),
            const SizedBox(height: 16),

            // Cost
            _buildFormCard([
              const SectionHeader(title: 'COSTS'),
              TextFormField(
                controller: _laborCostController,
                decoration: const InputDecoration(
                  labelText: 'Labor cost *',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter labor cost' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  prefixIcon: Icon(Icons.discount_outlined),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outlined),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
            ]),
            const SizedBox(height: 16),

            // Total Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryLine('Parts', currencyFormat.format(_selectedParts.fold(0.0, (sum, item) => sum + item['subtotal']))),
                  _buildSummaryLine('Labor', currencyFormat.format(double.tryParse(_laborCostController.text) ?? 0)),
                  _buildSummaryLine('Discount', currencyFormat.format(double.tryParse(_discountController.text) ?? 0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.white.withOpacity(0.2)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Due',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        currencyFormat.format(_calculateTotal()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GradientButton(
              label: 'CREATE REPAIR ORDER',
              icon: Icons.check,
              gradient: AppColors.featureGradient(AppColors.repair),
              onPressed: _isLoading ? null : _saveOrder,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          Text(value, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
