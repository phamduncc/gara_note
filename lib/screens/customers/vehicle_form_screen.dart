import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/vehicle.dart';
import '../../utils/app_theme.dart';
import '../../utils/shared_widgets.dart';

class VehicleFormScreen extends StatefulWidget {
  final int customerId;
  final Vehicle? vehicle;

  const VehicleFormScreen({
    super.key,
    required this.customerId,
    this.vehicle,
  });

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _licensePlateController;
  late TextEditingController _brandController;
  late TextEditingController _frameNumberController;
  late TextEditingController _engineNumberController;
  late TextEditingController _currentKmController;

  String _vehicleType = 'Motorcycle';
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['Motorcycle', 'Car'];
  final List<String> _motorcycleBrands = ['Honda', 'Yamaha', 'Suzuki', 'SYM', 'Piaggio', 'Other'];
  final List<String> _carBrands = ['Toyota', 'Honda', 'Mazda', 'Hyundai', 'Kia', 'Ford', 'VinFast', 'Other'];

  @override
  void initState() {
    super.initState();
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate);
    _brandController = TextEditingController(text: widget.vehicle?.brand);
    _frameNumberController = TextEditingController(text: widget.vehicle?.frameNumber);
    _engineNumberController = TextEditingController(text: widget.vehicle?.engineNumber);
    _currentKmController = TextEditingController(
      text: widget.vehicle?.currentKm?.toString(),
    );
    if (widget.vehicle != null) {
      _vehicleType = widget.vehicle!.vehicleType;
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _brandController.dispose();
    _frameNumberController.dispose();
    _engineNumberController.dispose();
    _currentKmController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      customerId: widget.customerId,
      vehicleType: _vehicleType,
      brand: _brandController.text.trim(),
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      frameNumber: _frameNumberController.text.trim().isEmpty ? null : _frameNumberController.text.trim(),
      engineNumber: _engineNumberController.text.trim().isEmpty ? null : _engineNumberController.text.trim(),
      currentKm: _currentKmController.text.trim().isEmpty ? null : int.parse(_currentKmController.text.trim()),
    );

    try {
      if (widget.vehicle == null) {
        await _dbHelper.insertVehicle(vehicle);
      } else {
        await _dbHelper.updateVehicle(vehicle);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle == null ? 'Vehicle added' : 'Vehicle updated'),
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
    final brands = _vehicleType == 'Motorcycle' ? _motorcycleBrands : _carBrands;
    final isEdit = widget.vehicle != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: isEdit ? 'Edit Vehicle' : 'Add Vehicle',
        mainColor: AppColors.customer,
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
                  gradient: AppColors.featureGradient(AppColors.customer),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.customer.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _vehicleType == 'Motorcycle' ? Icons.motorcycle : Icons.directions_car,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            _buildFormCard([
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _vehicleType = value!;
                    _brandController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: brands.contains(_brandController.text) ? _brandController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Brand *',
                  prefixIcon: Icon(Icons.branding_watermark_outlined),
                ),
                items: brands.map((brand) {
                  return DropdownMenuItem(value: brand, child: Text(brand));
                }).toList(),
                onChanged: (value) {
                  setState(() => _brandController.text = value!);
                },
                validator: (value) {
                  if (_brandController.text.isEmpty) {
                    return 'Please select a brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'License plate *',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter license plate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frameNumberController,
                decoration: const InputDecoration(
                  labelText: 'Frame number',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _engineNumberController,
                decoration: const InputDecoration(
                  labelText: 'Engine number',
                  prefixIcon: Icon(Icons.settings_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentKmController,
                decoration: const InputDecoration(
                  labelText: 'Current mileage',
                  prefixIcon: Icon(Icons.speed_outlined),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
              ),
            ]),
            const SizedBox(height: 24),
            GradientButton(
              label: isEdit ? 'UPDATE' : 'ADD VEHICLE',
              icon: isEdit ? Icons.check : Icons.add,
              gradient: AppColors.featureGradient(AppColors.customer),
              onPressed: _isLoading ? null : _saveVehicle,
              isLoading: _isLoading,
            ),
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
      child: Column(children: children),
    );
  }
}
