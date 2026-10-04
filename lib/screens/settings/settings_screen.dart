import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/settings_helper.dart';
import '../../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  String _garageName = '';
  String _garageAddress = '';
  String _garagePhone = '';
  String _garageEmail = '';
  
  int _totalCustomers = 0;
  int _totalRepairs = 0;
  int _totalParts = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStats();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsHelper.getAllSettings();
    if (mounted) {
      setState(() {
        _garageName = settings['name'] ?? 'GARA NOTE';
        _garageAddress = settings['address'] ?? '';
        _garagePhone = settings['phone'] ?? '';
        _garageEmail = settings['email'] ?? '';
      });
    }
  }

  Future<void> _loadStats() async {
    final customers = await _dbHelper.getCustomers();
    final repairs = await _dbHelper.getRepairOrders();
    final parts = await _dbHelper.getParts();
    
    if (mounted) {
      setState(() {
        _totalCustomers = customers.length;
        _totalRepairs = repairs.length;
        _totalParts = parts.length;
      });
    }
  }

  Future<void> _editGarageInfo() async {
    final nameController = TextEditingController(text: _garageName);
    final addressController = TextEditingController(text: _garageAddress);
    final phoneController = TextEditingController(text: _garagePhone);
    final emailController = TextEditingController(text: _garageEmail);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Garage Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Garage name *',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Please enter garage name')),
                );
                return;
              }
              
              await SettingsHelper.setGarageName(nameController.text.trim());
              await SettingsHelper.setGarageAddress(addressController.text.trim());
              await SettingsHelper.setGaragePhone(phoneController.text.trim());
              await SettingsHelper.setGarageEmail(emailController.text.trim());
              
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Garage information updated')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text(
          'Are you sure you want to delete all data?\n\n'
          'This action CANNOT be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
        _loadStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Garage Information',
            icon: Icons.business,
            color: AppColors.primary,
            children: [
              _buildInfoTile(
                icon: Icons.business,
                title: 'Garage Name',
                value: _garageName,
              ),
              if (_garageAddress.isNotEmpty)
                _buildInfoTile(
                  icon: Icons.location_on,
                  title: 'Address',
                  value: _garageAddress,
                ),
              if (_garagePhone.isNotEmpty)
                _buildInfoTile(
                  icon: Icons.phone,
                  title: 'Phone Number',
                  value: _garagePhone,
                ),
              if (_garageEmail.isNotEmpty)
                _buildInfoTile(
                  icon: Icons.email,
                  title: 'Email',
                  value: _garageEmail,
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _editGarageInfo,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Data Statistics',
            icon: Icons.analytics,
            color: AppColors.secondary,
            children: [
              _buildStatTile(
                icon: Icons.people,
                title: 'Total Customers',
                value: '$_totalCustomers',
                color: Colors.blue,
              ),
              _buildStatTile(
                icon: Icons.build,
                title: 'Total Repair Orders',
                value: '$_totalRepairs',
                color: Colors.orange,
              ),
              _buildStatTile(
                icon: Icons.inventory,
                title: 'Total Parts',
                value: '$_totalParts',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Data',
            icon: Icons.storage,
            color: Colors.orange,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text('Delete All Data'),
                subtitle: const Text('Delete all customers, repair orders, and parts'),
                onTap: _clearAllData,
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'About',
            icon: Icons.info,
            color: Colors.purple,
            children: [
              const ListTile(
                leading: Icon(Icons.app_settings_alt, color: AppColors.primary),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              const ListTile(
                leading: Icon(Icons.code, color: AppColors.secondary),
                title: Text('App'),
                subtitle: Text('Gara Note - Offline garage management'),
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.orange),
                title: const Text('Features'),
                subtitle: const Text('Tap to view'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Features'),
                      content: const SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✓ Customer & vehicle management', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 4),
                            Text('✓ Repair orders & status tracking', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 4),
                            Text('✓ Parts inventory management', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 4),
                            Text('✓ Debt management', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 4),
                            Text('✓ Revenue reports', style: TextStyle(fontSize: 14)),
                            SizedBox(height: 4),
                            Text('✓ Works 100% offline', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
