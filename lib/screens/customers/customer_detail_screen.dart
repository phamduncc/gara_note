import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../models/repair_order.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';
import 'vehicle_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Vehicle> _vehicles = [];
  List<RepairOrder> _repairHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final vehicles = await _dbHelper.getVehiclesByCustomer(widget.customer.id!);
    final List<RepairOrder> allOrders = [];
    
    for (var vehicle in vehicles) {
      final orders = await _dbHelper.getRepairOrdersByVehicle(vehicle.id!);
      allOrders.addAll(orders);
    }
    
    allOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    setState(() {
      _vehicles = vehicles;
      _repairHistory = allOrders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: GradientAppBar(
          title: widget.customer.name,
          mainColor: AppColors.customer,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info & Vehicles'),
              Tab(text: 'Repair History'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildInfoTab(),
                  _buildHistoryTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Customer info card
        SectionCard(
          title: 'Information',
          icon: Icons.person_outlined,
          color: AppColors.customer,
          children: [
            InfoRow(icon: Icons.person_outlined, label: 'Full name', value: widget.customer.name, iconColor: AppColors.customer),
            InfoRow(icon: Icons.phone_outlined, label: 'Phone number', value: widget.customer.phone, iconColor: AppColors.customer),
            if (widget.customer.address != null)
              InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: widget.customer.address!, iconColor: AppColors.customer),
            if (widget.customer.notes != null)
              InfoRow(icon: Icons.note_outlined, label: 'Notes', value: widget.customer.notes!, iconColor: AppColors.customer),
          ],
        ),
        
        // Vehicles section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'VEHICLES', icon: Icons.directions_car_outlined),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleFormScreen(customerId: widget.customer.id!),
                  ),
                );
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Vehicle'),
              style: TextButton.styleFrom(foregroundColor: AppColors.customer),
            ),
          ],
        ),
        if (_vehicles.isEmpty)
          const EmptyStateWidget(
            icon: Icons.directions_car_outlined,
            title: 'No vehicles yet',
            subtitle: 'Add a vehicle for this customer',
            iconColor: AppColors.customer,
          )
        else
          ..._vehicles.map((vehicle) => PremiumCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.featureGradient(
                          vehicle.vehicleType == 'Motorcycle'
                              ? AppColors.repair
                              : AppColors.customer,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        vehicle.vehicleType == 'Motorcycle' ? Icons.motorcycle : Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.licensePlate,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.brand} • ${vehicle.vehicleType}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vehicle.currentKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${vehicle.currentKm} km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryMedium,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_repairHistory.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'No repair history yet',
        subtitle: 'Repair orders will appear here',
        iconColor: AppColors.repair,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _repairHistory.length,
      itemBuilder: (context, index) {
        final order = _repairHistory[index];
        return PremiumCard(
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
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  StatusBadge(
                    label: order.status,
                    color: _getStatusColor(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(order.orderDate),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.repairItems,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  NumberFormat.currency(locale: 'vi', symbol: '₫').format(order.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
