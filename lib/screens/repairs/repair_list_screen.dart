import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/repair_order.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';
import 'repair_form_screen.dart';
import 'repair_detail_screen.dart';

class RepairListScreen extends StatefulWidget {
  const RepairListScreen({super.key});

  @override
  State<RepairListScreen> createState() => _RepairListScreenState();
}

class _RepairListScreenState extends State<RepairListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  bool _isLoading = true;

  final List<String> _statuses = ['All', 'Pending', 'In Progress', 'Completed', 'Paid'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _dbHelper.getRepairOrders();
    final List<Map<String, dynamic>> ordersWithDetails = [];

    final allVehicles = await _dbHelper.getVehicles();

    for (var order in orders) {
      final customer = await _dbHelper.getCustomerById(order.customerId);
      final vehicle = allVehicles.firstWhere((v) => v.id == order.vehicleId);

      ordersWithDetails.add({
        'order': order,
        'customer': customer,
        'vehicle': vehicle,
      });
    }

    setState(() {
      _orders = ordersWithDetails;
      _filteredOrders = ordersWithDetails;
      _isLoading = false;
    });
    _filterOrders();
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _orders.where((item) {
        final order = item['order'] as RepairOrder;
        final customer = item['customer'] as Customer?;
        final vehicle = item['vehicle'] as Vehicle?;

        final matchesSearch = query.isEmpty ||
            order.orderCode.toLowerCase().contains(query) ||
            (customer?.name.toLowerCase().contains(query) ?? false) ||
            (vehicle?.licensePlate.toLowerCase().contains(query) ?? false);

        final matchesStatus = _selectedStatus == 'All' || order.status == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'REPAIR ORDERS',
        mainColor: AppColors.repair,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SearchBarPremium(
              controller: _searchController,
              hintText: 'Order code, customer, license plate...',
              onChanged: (_) => _filterOrders(),
            ),
          ),
          _buildStatusFilter(),
          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredOrders.length} orders',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.assignment_outlined,
                        title: 'No repair orders found',
                        subtitle: 'Create a new repair order',
                        iconColor: AppColors.repair,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final item = _filteredOrders[index];
                          final order = item['order'] as RepairOrder;
                          final customer = item['customer'] as Customer?;
                          final vehicle = item['vehicle'] as Vehicle?;

                          return PremiumCard(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RepairDetailScreen(order: order),
                                ),
                              );
                              if (result == true) _loadOrders();
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order.orderCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    StatusBadge(
                                      label: order.status,
                                      color: _getStatusColor(order.status),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1, color: Colors.grey.shade100),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.repair.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.directions_car_outlined, color: AppColors.repair, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer?.name ?? 'Unknown customer',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            vehicle?.licensePlate ?? 'License plate: N/A',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(locale: 'vi', symbol: '₫').format(order.totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_outlined, size: 14, color: AppColors.textTertiary),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RepairFormScreen()),
          );
          if (result == true) _loadOrders();
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Create New Order'),
        backgroundColor: AppColors.repair,
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedStatus = status);
                  _filterOrders();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'In Progress':
        return AppColors.repair;
      case 'Paid':
        return AppColors.info;
      case 'Pending':
        return AppColors.settings;
      default:
        return AppColors.textSecondary;
    }
  }
}
