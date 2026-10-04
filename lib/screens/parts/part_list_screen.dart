import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/part.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';
import 'part_form_screen.dart';

class PartListScreen extends StatefulWidget {
  const PartListScreen({super.key});

  @override
  State<PartListScreen> createState() => _PartListScreenState();
}

class _PartListScreenState extends State<PartListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Part> _parts = [];
  List<Part> _filteredParts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showLowStockOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    setState(() => _isLoading = true);
    final parts = await _dbHelper.getParts();
    setState(() {
      _parts = parts;
      _filteredParts = parts;
      _isLoading = false;
    });
    _filterParts();
  }

  void _filterParts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParts = _parts.where((part) {
        final matchesSearch = query.isEmpty ||
            part.name.toLowerCase().contains(query) ||
            part.partCode.toLowerCase().contains(query);
        final matchesStock = !_showLowStockOnly || part.isLowStock;
        return matchesSearch && matchesStock;
      }).toList();
    });
  }

  Future<void> _deletePart(Part part) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete part ${part.name}?'),
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
      await _dbHelper.deletePart(part.id!);
      _loadParts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _parts.where((p) => p.isLowStock).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'PARTS INVENTORY',
        mainColor: AppColors.inventory,
      ),
      body: Column(
        children: [
          if (lowStockCount > 0 && !_showLowStockOnly)
            _buildLowStockWarning(lowStockCount),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: SearchBarPremium(
              controller: _searchController,
              hintText: 'Part name or code...',
              onChanged: (_) => _filterParts(),
            ),
          ),
          _buildFilterChips(),
          // Count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredParts.length} parts',
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
                : _filteredParts.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'Inventory is empty',
                        subtitle: 'Add new parts to inventory',
                        iconColor: AppColors.inventory,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredParts.length,
                        itemBuilder: (context, index) {
                          final part = _filteredParts[index];
                          return PremiumCard(
                            borderColor: part.isLowStock ? AppColors.error.withOpacity(0.2) : null,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PartFormScreen(part: part),
                                ),
                              );
                              if (result == true) _loadParts();
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: part.isLowStock
                                        ? AppColors.featureGradient(AppColors.error)
                                        : AppColors.featureGradient(AppColors.inventory),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    part.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        part.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Code: ${part.partCode}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(locale: 'vi', symbol: '₫').format(part.sellingPrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: part.isLowStock
                                            ? AppColors.error
                                            : AppColors.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Stock: ${part.quantity}',
                                        style: TextStyle(
                                          color: part.isLowStock ? Colors.white : AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
            MaterialPageRoute(builder: (_) => const PartFormScreen()),
          );
          if (result == true) _loadParts();
        },
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add New'),
        backgroundColor: AppColors.inventory,
      ),
    );
  }

  Widget _buildLowStockWarning(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  '$count parts are running low!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _showLowStockOnly = true);
              _filterParts();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('View Now', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: !_showLowStockOnly,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _showLowStockOnly = false;
                  _filterParts();
                });
              }
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: !_showLowStockOnly ? Colors.white : AppColors.textPrimary,
              fontWeight: !_showLowStockOnly ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: !_showLowStockOnly ? AppColors.primary : Colors.grey.shade200,
              ),
            ),
            showCheckmark: false,
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Low Stock'),
            selected: _showLowStockOnly,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _showLowStockOnly = true;
                  _filterParts();
                });
              }
            },
            selectedColor: AppColors.error,
            labelStyle: TextStyle(
              color: _showLowStockOnly ? Colors.white : AppColors.textPrimary,
              fontWeight: _showLowStockOnly ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _showLowStockOnly ? AppColors.error : Colors.grey.shade200,
              ),
            ),
            showCheckmark: false,
          ),
        ],
      ),
    );
  }
}
