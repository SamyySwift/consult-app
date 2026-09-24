import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class Step6ReviewPay extends StatefulWidget {
  final VoidCallback onNext;
  const Step6ReviewPay({super.key, required this.onNext});

  @override
  State<Step6ReviewPay> createState() => _Step6ReviewPayState();
}

class _Step6ReviewPayState extends State<Step6ReviewPay> {
  int _selectedPayment = 0; // 0=card, 1=bank, 2=ussd

  String _fmt(double amount) {
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final draft = prov.draft;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.receipt_long_rounded,
                title: 'Review & Pay',
                subtitle: 'Confirm your booking details before payment',
              ),

              SizedBox(height: 24),

              // Order summary card
              _SummaryCard(
                vehicle: '${draft.vehicleYear} ${draft.vehicleMake} ${draft.vehicleModel}',
                vehicleType: draft.vehicleType?.toString().split('.').last ?? '',
                vehicleColor: draft.vehicleColor ?? '',
                vehicleWorth: _fmt(draft.vehicleValue ?? 0),
                pickup: draft.pickupAddress ?? '',
                dropoff: draft.dropoffAddress ?? '',
                pickupDate: draft.pickupDateTime != null
                    ? DateFormat('EEE, MMM d • h:mm a').format(draft.pickupDateTime!)
                    : '',
                service: _serviceLabel(draft.serviceType),
                transport: draft.transportMode == TransportMode.enclosed ? 'Enclosed' : 'Open',
                insurance: draft.hasInsurance ? 'Yes (${_fmt(draft.computedInsuranceFee)})' : 'No',
              ),

              SizedBox(height: 16),

              // Pricing breakdown
              _PriceCard(
                basePrice: draft.basePrice,
                enclosedAddon: draft.enclosedAddon,
                insuranceFee: draft.computedInsuranceFee,
                total: draft.totalPrice,
                fmtFn: _fmt,
              ),

              SizedBox(height: 24),

              Text(
                'Payment Method',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              ),
              SizedBox(height: 12),

              // Paystack methods
              ..._paymentMethods.asMap().entries.map((entry) {
                final i = entry.key;
                final method = entry.value;
                final isSelected = _selectedPayment == i;

                return GestureDetector(
                  onTap: () => setState(() => _selectedPayment = i),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.accent.withValues(alpha: 0.04) : context.colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? context.colors.accent : context.colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(method.icon, color: isSelected ? context.colors.accent : context.colors.textSecondary, size: 22),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                              Text(method.subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle_rounded, color: context.colors.accent, size: 20),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 8),

              // Paystack branding
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: context.colors.textLight),
                  SizedBox(width: 6),
                  Text(
                    'Secured by Paystack',
                    style: TextStyle(fontSize: 12, color: context.colors.textLight, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Pay button
              Column(
                children: [
                  CustomButton(
                    label: 'Pay ${_fmt(draft.totalPrice)}',
                    onPressed: widget.onNext,
                    icon: Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'By paying, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: context.colors.textLight),
                  ),
                ],
              ),

              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.standard: return 'Standard';
      case ServiceType.express: return 'Express';
      case ServiceType.whiteGlove: return 'White Glove';
    }
  }
}

const _paymentMethods = [
  _PaymentMethod(Icons.credit_card_rounded, 'Card Payment', 'Visa, Mastercard, Verve'),
  _PaymentMethod(Icons.account_balance_rounded, 'Bank Transfer', 'Direct bank account transfer'),
  _PaymentMethod(Icons.dialpad_rounded, 'USSD', 'Pay via USSD shortcode'),
];

class _PaymentMethod {
  final IconData icon;
  final String label;
  final String subtitle;
  const _PaymentMethod(this.icon, this.label, this.subtitle);
}

class _SummaryCard extends StatelessWidget {
  final String vehicle, vehicleType, vehicleColor, vehicleWorth, pickup, dropoff, pickupDate, service, transport, insurance;
  const _SummaryCard({
    required this.vehicle, required this.vehicleType, required this.vehicleColor, required this.vehicleWorth,
    required this.pickup, required this.dropoff, required this.pickupDate,
    required this.service, required this.transport, required this.insurance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          _SummaryRow(icon: Icons.directions_car_rounded, label: 'Vehicle', value: vehicle),
          _SummaryRow(icon: Icons.palette_rounded, label: 'Color', value: vehicleColor),
          _SummaryRow(icon: Icons.payments_rounded, label: 'Vehicle Worth', value: vehicleWorth),
          _SummaryRow(icon: Icons.radio_button_on, label: 'Pickup', value: pickup, valueMaxLines: 2),
          _SummaryRow(icon: Icons.location_on_rounded, label: 'Delivery', value: dropoff, valueMaxLines: 2),
          if (pickupDate.isNotEmpty)
            _SummaryRow(icon: Icons.schedule_rounded, label: 'Date', value: pickupDate),
          _SummaryRow(icon: Icons.local_shipping_rounded, label: 'Service', value: service),
          _SummaryRow(icon: Icons.garage_rounded, label: 'Transport', value: transport),
          _SummaryRow(icon: Icons.shield_rounded, label: 'Insurance', value: insurance, isLast: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final int valueMaxLines;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.valueMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: valueMaxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: context.colors.textLight),
              SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(label, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                  textAlign: TextAlign.right,
                  maxLines: valueMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double basePrice, enclosedAddon, insuranceFee, total;
  final String Function(double) fmtFn;

  const _PriceCard({
    required this.basePrice, required this.enclosedAddon,
    required this.insuranceFee, required this.total, required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _PriceRow('Base Price', fmtFn(basePrice), Colors.white70),
          if (enclosedAddon > 0) _PriceRow('Enclosed Transport', '+${fmtFn(enclosedAddon)}', Colors.white70),
          if (insuranceFee > 0) _PriceRow('Insurance', '+${fmtFn(insuranceFee)}', Colors.white70),
          Divider(color: Colors.white24, height: 20),
          Row(
            children: [
              Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Spacer(),
              Text(
                fmtFn(total),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.colors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: color)),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
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
          width: 44, height: 44,
          decoration: BoxDecoration(color: context.colors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
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
