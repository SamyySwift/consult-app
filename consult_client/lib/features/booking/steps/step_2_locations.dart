import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';

class Step2Locations extends StatefulWidget {
  final VoidCallback onNext;
  const Step2Locations({super.key, required this.onNext});

  @override
  State<Step2Locations> createState() => _Step2LocationsState();
}

class _Step2LocationsState extends State<Step2Locations> {
  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _pickupCtrl.text = draft.pickupAddress ?? '';
    _dropoffCtrl.text = draft.dropoffAddress ?? '';
    if (draft.pickupDateTime != null) {
      _pickupDate = draft.pickupDateTime;
      _pickupTime = TimeOfDay.fromDateTime(draft.pickupDateTime!);
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _pickupDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _pickupTime = time);
  }

  String get _dateDisplay {
    if (_pickupDate == null) return 'Select pickup date';
    return DateFormat('EEE, MMM d, yyyy').format(_pickupDate!);
  }

  String get _timeDisplay {
    if (_pickupTime == null) return 'Select pickup time';
    final h = _pickupTime!.hourOfPeriod;
    final m = _pickupTime!.minute.toString().padLeft(2, '0');
    final period = _pickupTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null || _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a pickup date and time')),
      );
      return;
    }

    final pickupDateTime = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );

    context.read<BookingProvider>()
      ..updatePickup(
        address: _pickupCtrl.text.trim(),
        lat: 6.5244,
        lng: 3.3792,
        dateTime: pickupDateTime,
      )
      ..updateDropoff(
        address: _dropoffCtrl.text.trim(),
        lat: 9.0820,
        lng: 8.6753,
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
              icon: Icons.location_on_rounded,
              title: 'Pickup & Delivery',
              subtitle: 'Set your vehicle pickup and drop-off locations',
            ),

            SizedBox(height: 28),

            // Route visual
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  // Pickup
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: context.colors.success,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.radio_button_checked, color: Colors.white, size: 16),
                          ),
                          Container(width: 2, height: 40, color: context.colors.border),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: context.colors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              label: 'Pickup Address *',
                              hint: 'Enter full pickup address',
                              controller: _pickupCtrl,
                              validator: (v) => AppValidators.validateRequired(v, field: 'Pickup address'),
                              prefixIcon: null,
                              maxLines: 2,
                            ),
                            SizedBox(height: 12),
                            CustomTextField(
                              label: 'Delivery Address *',
                              hint: 'Enter full delivery address',
                              controller: _dropoffCtrl,
                              validator: (v) => AppValidators.validateRequired(v, field: 'Delivery address'),
                              prefixIcon: null,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Preferred Pickup Date & Time *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _DateTimeChip(
                      icon: Icons.calendar_today_rounded,
                      label: _dateDisplay,
                      isSelected: _pickupDate != null,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _DateTimeChip(
                      icon: Icons.access_time_rounded,
                      label: _timeDisplay,
                      isSelected: _pickupTime != null,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: context.colors.info, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Our driver will contact you 30 minutes before pickup',
                      style: TextStyle(fontSize: 12, color: context.colors.info),
                    ),
                  ),
                ],
              ),
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

class _DateTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _DateTimeChip({required this.icon, required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.accent.withValues(alpha: 0.08) : context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? context.colors.accent : context.colors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? context.colors.accent : context.colors.textLight),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? context.colors.accent : context.colors.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
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
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
