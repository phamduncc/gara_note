import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _debtList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebtList();
  }

  Future<void> _loadDebtList() async {
    setState(() => _isLoading = true);
    final debtList = await _dbHelper.getDebtList();
    setState(() {
      _debtList = debtList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt = _debtList.fold(0.0, (sum, item) => sum + (item['debt'] as num));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Management'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'TOTAL DEBT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.currency(locale: 'vi', symbol: '₫').format(totalDebt),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_debtList.length} customers with unpaid balances',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _debtList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No outstanding debts',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _debtList.length,
                        itemBuilder: (context, index) {
                          final item = _debtList[index];
                          final debt = item['debt'] as num;
                          final totalAmount = item['total_amount'] as num;
                          final totalPaid = item['total_paid'] as num;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade700,
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                item['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone: ${item['phone']}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(totalAmount)}',
                                  ),
                                  Text(
                                    'Paid: ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(totalPaid)}',
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Outstanding',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    NumberFormat.currency(locale: 'vi', symbol: '₫').format(debt),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
