import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/database_helper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: now,
        );
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'This Year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      default:
        return DateTimeRange(start: now, end: now);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final range = _getPeriodRange();
    final stats = await _dbHelper.getStatistics(range.start, range.end);
    setState(() {
      _statistics = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: InputDecoration(
                      labelText: 'Select report period',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem(value: period, child: Text(period));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                      _loadStatistics();
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  const Text(
                    'Best-selling Parts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTopParts(),
                  const SizedBox(height: 24),
                  _buildRevenueChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _statistics!['total_revenue'] ?? 0;
    final totalOrders = _statistics!['total_orders'] ?? 0;
    final totalPaid = _statistics!['total_paid'] ?? 0;
    final debt = _statistics!['debt'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Revenue',
                NumberFormat.currency(locale: 'vi', symbol: '₫').format(totalRevenue),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Orders',
                totalOrders.toString(),
                Icons.receipt,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Paid',
                NumberFormat.currency(locale: 'vi', symbol: '₫').format(totalPaid),
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Debt',
                NumberFormat.currency(locale: 'vi', symbol: '₫').format(debt),
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopParts() {
    final topParts = _statistics!['top_parts'] as List<Map<String, dynamic>>;

    if (topParts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No data yet')),
        ),
      );
    }

    return Column(
      children: topParts.map((part) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade700,
              child: Text(
                part['total_sold'].toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(part['name']),
            subtitle: Text('Code: ${part['part_code']}'),
            trailing: Text(
              '${part['total_sold']} sold',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueChart() {
    final totalRevenue = (_statistics!['total_revenue'] ?? 0).toDouble();
    final totalPaid = (_statistics!['total_paid'] ?? 0).toDouble();
    final debt = (_statistics!['debt'] ?? 0).toDouble();

    if (totalRevenue == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Chart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalPaid,
                      title: 'Paid',
                      color: Colors.green,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (debt > 0)
                      PieChartSectionData(
                        value: debt,
                        title: 'Debt',
                        color: Colors.red,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
