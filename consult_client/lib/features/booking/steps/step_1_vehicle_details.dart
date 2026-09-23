import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

/// Forces all typed characters to uppercase.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

const _vehicleTypes = [
  (VehicleType.sedan, 'Sedan', Icons.directions_car_rounded),
  (VehicleType.suv, 'SUV', Icons.car_rental_rounded),
  (VehicleType.truck, 'Truck', Icons.local_shipping_rounded),
  (VehicleType.van, 'Van', Icons.airport_shuttle_rounded),
  (VehicleType.motorcycle, 'Motorcycle', Icons.two_wheeler_rounded),
];

class Step1VehicleDetails extends StatefulWidget {
  final VoidCallback onNext;
  const Step1VehicleDetails({super.key, required this.onNext});

  @override
  State<Step1VehicleDetails> createState() => _Step1VehicleDetailsState();
}

class _Step1VehicleDetailsState extends State<Step1VehicleDetails> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  VehicleType? _selectedType;
  int _vinLength = 0;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _selectedType = draft.vehicleType;
    _makeCtrl.text = draft.vehicleMake ?? '';
    _modelCtrl.text = draft.vehicleModel ?? '';
    _yearCtrl.text = draft.vehicleYear ?? '';
    _colorCtrl.text = draft.vehicleColor ?? '';
    _vinCtrl.text = (draft.vehicleVin ?? '').toUpperCase();
    _vinLength = _vinCtrl.text.length;
    _vinCtrl.addListener(() {
      setState(() => _vinLength = _vinCtrl.text.length);
    });
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _vinCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    context.read<BookingProvider>().updateVehicleDetails(
          type: _selectedType,
          make: _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year: _yearCtrl.text.trim(),
          color: _colorCtrl.text.trim(),
          vin: _vinCtrl.text.trim(),
        );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.directions_car_rounded,
              title: 'Vehicle Details',
              subtitle: 'Tell us about the vehicle being transported',
            ),

            SizedBox(height: 24),

            // Vehicle type grid
            Text(
              'Vehicle Type *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),
            SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _vehicleTypes.map((item) {
                final (type, label, icon) = item;
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.accent.withValues(alpha: 0.08) : context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? context.colors.accent : context.colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 20, color: isSelected ? context.colors.accent : context.colors.textSecondary),
                        SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? context.colors.accent : context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Make *',
                    hint: 'e.g. Toyota',
                    controller: _makeCtrl,
                    validator: (v) => AppValidators.validateRequired(v, field: 'Make'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Model *',
                    hint: 'e.g. Prado',
                    controller: _modelCtrl,
                    validator: (v) => AppValidators.validateRequired(v, field: 'Model'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Year *',
                    hint: 'e.g. 2021',
                    controller: _yearCtrl,
                    validator: AppValidators.validateYear,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Color *',
                    hint: 'e.g. White',
                    controller: _colorCtrl,
                    validator: (v) => AppValidators.validateRequired(v, field: 'Color'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            CustomTextField(
              label: 'VIN Number (Optional)',
              hint: '17-character VIN',
              controller: _vinCtrl,
              validator: AppValidators.validateVin,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              inputFormatters: [
                _UpperCaseFormatter(),
                LengthLimitingTextInputFormatter(17),
              ],
            ),

            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found on the dashboard or door frame of your vehicle',
                  style: TextStyle(fontSize: 12, color: context.colors.textLight),
                ),
                Text(
                  '$_vinLength / 17',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _vinLength == 17
                        ? context.colors.accent
                        : context.colors.textLight,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            CustomButton(label: 'Continue', onPressed: _submit),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.colors.accent, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
