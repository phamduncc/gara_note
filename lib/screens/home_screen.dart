import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';
import 'customers/customer_list_screen.dart';
import 'repairs/repair_list_screen.dart';
import 'parts/part_list_screen.dart';
import 'debts/debt_list_screen.dart';
import 'reports/report_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _customerCount = 0;
  int _activeRepairCount = 0;
  int _lowStockCount = 0;
  double _todayRevenue = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final stats = await _dbHelper.getStatistics(startOfDay, endOfDay);
    final customers = await _dbHelper.getCustomerCount();
    final repairs = await _dbHelper.getActiveRepairCount();
    final lowStock = await _dbHelper.getLowStockCount();

    if (mounted) {
      setState(() {
        _todayRevenue = (stats['total_revenue'] as num).toDouble();
        _customerCount = customers;
        _activeRepairCount = repairs;
        _lowStockCount = lowStock;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ===== Hero AppBar =====
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'GARA NOTE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Icon(
                          Icons.car_repair,
                          size: 220,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: -20,
                        child: Icon(
                          Icons.build_circle_outlined,
                          size: 120,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.secondary.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.secondary.withOpacity(0.5),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Active',
                                          style: TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Hello, Manager!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currencyFormat.format(_todayRevenue),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Today's revenue",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Main Content =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(),
                    const SizedBox(height: 28),
                    const Text(
                      'FEATURES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuGrid(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Active',
              _activeRepairCount.toString(),
              Icons.build_circle_outlined,
              AppColors.repair,
            ),
          ),
          _buildStatDivider(),
          Expanded(
            child: _buildStatItem(
              'Customers',
              _customerCount.toString(),
              Icons.people_alt_outlined,
              AppColors.customer,
            ),
          ),
          _buildStatDivider(),
          Expanded(
            child: _buildStatItem(
              'Low Stock',
              _lowStockCount.toString(),
              Icons.inventory_2_outlined,
              _lowStockCount > 0 ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 50,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: [
        _buildMenuCard(
          context,
          title: 'Repair\nOrders',
          icon: Icons.assignment_outlined,
          color: AppColors.repair,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RepairListScreen()),
          ).then((_) => _loadStats()),
        ),
        _buildMenuCard(
          context,
          title: 'Customers\n& Vehicles',
          icon: Icons.directions_car_outlined,
          color: AppColors.customer,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerListScreen()),
          ).then((_) => _loadStats()),
        ),
        _buildMenuCard(
          context,
          title: 'Parts\nInventory',
          icon: Icons.inventory_2_outlined,
          color: AppColors.inventory,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PartListScreen()),
          ).then((_) => _loadStats()),
        ),
        _buildMenuCard(
          context,
          title: 'Customer\nDebts',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.debt,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DebtListScreen()),
          ).then((_) => _loadStats()),
        ),
        _buildMenuCard(
          context,
          title: 'Reports\nAnalytics',
          icon: Icons.bar_chart_outlined,
          color: AppColors.report,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          ).then((_) => _loadStats()),
        ),
        _buildMenuCard(
          context,
          title: 'System\nSettings',
          icon: Icons.settings_outlined,
          color: AppColors.settings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ).then((_) => _loadStats()),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: color.withOpacity(0.08),
          highlightColor: color.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.12),
                        color.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
