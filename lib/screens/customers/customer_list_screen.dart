import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _dbHelper.getCustomers();
    setState(() {
      _customers = customers;
      _filteredCustomers = customers;
      _isLoading = false;
    });
  }

  void _searchCustomers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCustomers = _customers);
    } else {
      setState(() {
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.phone.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete customer ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteCustomer(customer.id!);
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'CUSTOMERS',
        mainColor: AppColors.customer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SearchBarPremium(
              controller: _searchController,
              hintText: 'Search name or phone...',
              onChanged: _searchCustomers,
            ),
          ),
          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredCustomers.length} customers',
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
                : _filteredCustomers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: 'No customers yet',
                        subtitle: 'Tap the button below to add a new customer',
                        iconColor: AppColors.customer,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return PremiumCard(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailScreen(customer: customer),
                                ),
                              );
                              _loadCustomers();
                            },
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.featureGradient(AppColors.customer),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      customer.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined, size: 14, color: AppColors.textTertiary),
                                          const SizedBox(width: 4),
                                          Text(
                                            customer.phone,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    color: AppColors.textSecondary,
                                    onPressed: () => _showOptions(customer),
                                    padding: EdgeInsets.zero,
                                  ),
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
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
          if (result == true) _loadCustomers();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add New'),
        backgroundColor: AppColors.customer,
      ),
    );
  }

  void _showOptions(Customer customer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              ),
              title: const Text('Edit Information', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerFormScreen(customer: customer),
                  ),
                );
                if (result == true) _loadCustomers();
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
              title: const Text(
                'Delete Customer',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteCustomer(customer);
              },
            ),
          ],
        ),
      ),
    );
  }
}
