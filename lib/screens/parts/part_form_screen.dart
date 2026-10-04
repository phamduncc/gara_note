import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/part.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';

class PartFormScreen extends StatefulWidget {
  final Part? part;

  const PartFormScreen({super.key, this.part});

  @override
  State<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends State<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _nameController;
  late TextEditingController _partCodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _supplierController;

  String _vehicleType = 'Motorcycle';
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['Motorcycle', 'Car', 'General'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.part?.name);
    _partCodeController = TextEditingController(text: widget.part?.partCode);
    _purchasePriceController = TextEditingController(
      text: widget.part?.purchasePrice.toString(),
    );
    _sellingPriceController = TextEditingController(
      text: widget.part?.sellingPrice.toString(),
    );
    _quantityController = TextEditingController(
      text: widget.part?.quantity.toString(),
    );
    _minQuantityController = TextEditingController(
      text: widget.part?.minQuantity.toString() ?? '5',
    );
    _supplierController = TextEditingController(text: widget.part?.supplier);

    if (widget.part != null) {
      _vehicleType = widget.part!.vehicleType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partCodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final part = Part(
      id: widget.part?.id,
      name: _nameController.text.trim(),
      partCode: _partCodeController.text.trim().toUpperCase(),
      vehicleType: _vehicleType,
      purchasePrice: double.parse(_purchasePriceController.text),
      sellingPrice: double.parse(_sellingPriceController.text),
      quantity: int.parse(_quantityController.text),
      minQuantity: int.parse(_minQuantityController.text),
      supplier: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
    );

    try {
      if (widget.part == null) {
        await _dbHelper.insertPart(part);
      } else {
        await _dbHelper.updatePart(part);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.part == null ? 'Part added' : 'Part updated'),
          ),
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
    final isEdit = widget.part != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: isEdit ? 'Edit Part' : 'Add Part',
        mainColor: AppColors.inventory,
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
                  gradient: AppColors.featureGradient(AppColors.inventory),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.inventory.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 32),
              ),
            ),

            // Basic Info
            _buildFormCard([
              const SectionHeader(title: 'BASIC INFORMATION'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Part name *',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter part name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partCodeController,
                decoration: const InputDecoration(
                  labelText: 'Part code *',
                  prefixIcon: Icon(Icons.qr_code_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter part code' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _vehicleType = value!),
              ),
            ]),
            const SizedBox(height: 16),

            // Pricing
            _buildFormCard([
              const SectionHeader(title: 'PRICING'),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'Purchase price *',
                  prefixIcon: Icon(Icons.shopping_cart_outlined),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter purchase price' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Selling price *',
                  prefixIcon: Icon(Icons.sell_outlined),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter selling price' : null,
              ),
            ]),
            const SizedBox(height: 16),

            // Inventory
            _buildFormCard([
              const SectionHeader(title: 'INVENTORY'),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Stock quantity *',
                  prefixIcon: Icon(Icons.storage_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter quantity' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Minimum quantity *',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                  helperText: 'Warn when quantity <= this value',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter minimum quantity' : null,
              ),
            ]),
            const SizedBox(height: 16),

            // Supplier
            _buildFormCard([
              const SectionHeader(title: 'SUPPLIER'),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            GradientButton(
              label: isEdit ? 'UPDATE' : 'ADD PART',
              icon: isEdit ? Icons.check : Icons.add,
              gradient: AppColors.featureGradient(AppColors.inventory),
              onPressed: _isLoading ? null : _savePart,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
          ],
        ),
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
