import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/repair_order.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../models/order_part.dart';
import '../../models/part.dart';
import '../../models/payment.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';

class RepairDetailScreen extends StatefulWidget {
  final RepairOrder order;

  const RepairDetailScreen({super.key, required this.order});

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Customer? _customer;
  Vehicle? _vehicle;
  List<Map<String, dynamic>> _orderParts = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final customer = await _dbHelper.getCustomerById(widget.order.customerId);
    final vehicles = await _dbHelper.getVehicles();
    final vehicle = vehicles.firstWhere((v) => v.id == widget.order.vehicleId);
    final orderParts = await _dbHelper.getOrderParts(widget.order.id!);
    final payments = await _dbHelper.getPaymentsByOrder(widget.order.id!);

    final List<Map<String, dynamic>> partsWithDetails = [];
    for (var op in orderParts) {
      final part = await _dbHelper.getPartById(op.partId);
      partsWithDetails.add({'orderPart': op, 'part': part});
    }

    setState(() {
      _customer = customer;
      _vehicle = vehicle;
      _orderParts = partsWithDetails;
      _payments = payments;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus() async {
    final statuses = ['Pending', 'In Progress', 'Completed', 'Paid'];
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isSelected = status == widget.order.status;
            return ListTile(
              leading: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                status,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != widget.order.status) {
      await _dbHelper.updateRepairOrder(widget.order.copyWith(status: newStatus));
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _addPayment() async {
    final amountController = TextEditingController();
    final paymentMethods = ['Cash', 'Bank Transfer', 'Card'];
    String selectedMethod = 'Cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  suffixText: '₫',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  prefixIcon: Icon(Icons.payment_outlined),
                ),
                items: paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedMethod = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount != null && amount > 0) {
        final payment = Payment(
          orderId: widget.order.id!,
          customerId: widget.order.customerId,
          amount: amount,
          paymentDate: DateTime.now(),
          paymentMethod: selectedMethod,
        );

        await _dbHelper.insertPayment(payment);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment added')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalPaid = _payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final remaining = widget.order.totalAmount - totalPaid;
    final currencyFormat = NumberFormat.currency(locale: 'vi', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: widget.order.orderCode,
        mainColor: AppColors.repair,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _updateStatus,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status & Info Card
          SectionCard(
            title: 'Order Information',
            icon: Icons.assignment_outlined,
            color: AppColors.repair,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  StatusBadge(
                    label: widget.order.status,
                    color: _getStatusColor(widget.order.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoRow(icon: Icons.person_outlined, label: 'Customer', value: _customer?.name ?? 'N/A', iconColor: AppColors.customer),
              InfoRow(icon: Icons.phone_outlined, label: 'Phone number', value: _customer?.phone ?? 'N/A', iconColor: AppColors.customer),
              InfoRow(icon: Icons.directions_car_outlined, label: 'Vehicle', value: '${_vehicle?.licensePlate} - ${_vehicle?.brand}', iconColor: AppColors.repair),
              InfoRow(icon: Icons.calendar_today_outlined, label: 'Created at', value: DateFormat('dd/MM/yyyy HH:mm').format(widget.order.orderDate), iconColor: AppColors.info),
            ],
          ),

          // Repair details
          SectionCard(
            title: 'Repair Details',
            icon: Icons.build_outlined,
            color: AppColors.repair,
            children: [
              InfoRow(icon: Icons.build_circle_outlined, label: 'Repair items', value: widget.order.repairItems, iconColor: AppColors.repair),
              if (widget.order.technicalNotes != null)
                InfoRow(icon: Icons.note_outlined, label: 'Technical notes', value: widget.order.technicalNotes!, iconColor: AppColors.repair),
            ],
          ),

          // Parts
          SectionCard(
            title: 'Parts',
            icon: Icons.inventory_2_outlined,
            color: AppColors.inventory,
            children: [
              if (_orderParts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No parts', style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ..._orderParts.map((item) {
                  final op = item['orderPart'] as OrderPart;
                  final part = item['part'] as Part?;
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
                              Text(
                                part?.name ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                '${op.quantity} x ${currencyFormat.format(op.price)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(op.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),

          // Total Summary Card
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
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Labor', currencyFormat.format(widget.order.laborCost)),
                _buildSummaryRow('Discount', currencyFormat.format(widget.order.discount)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.white.withOpacity(0.2)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      currencyFormat.format(widget.order.totalAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSummaryRow('Paid', currencyFormat.format(totalPaid), valueColor: AppColors.secondary),
                _buildSummaryRow(
                  'Remaining',
                  currencyFormat.format(remaining),
                  valueColor: remaining > 0 ? AppColors.accent : AppColors.secondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payments
          SectionCard(
            title: 'Payment History',
            icon: Icons.payment_outlined,
            color: AppColors.success,
            children: [
              if (_payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No payments yet', style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ..._payments.map((payment) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payment.paymentMethod,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(payment.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addPayment,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
