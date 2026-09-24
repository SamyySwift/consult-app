import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/pricing_provider.dart';
import 'package:intl/intl.dart';

class Step4Insurance extends StatefulWidget {
  final VoidCallback onNext;
  const Step4Insurance({super.key, required this.onNext});

  @override
  State<Step4Insurance> createState() => _Step4InsuranceState();
}

class _Step4InsuranceState extends State<Step4Insurance> {
  late bool _hasInsurance;

  @override
  void initState() {
    super.initState();
    _hasInsurance = context.read<BookingProvider>().draft.hasInsurance;
  }

  void _submit(BuildContext context) {
    final pricingProvider = context.read<PricingProvider>();
    final draft = context.read<BookingProvider>().draft;
    final pctRate = pricingProvider.insurancePercentage;

    double vehicleVal = draft.vehicleValue ?? 0;
    double insuranceAmount = 0;
    if (_hasInsurance) {
      insuranceAmount = vehicleVal > 0 ? (vehicleVal * (pctRate / 100)) : 15000;
    }
    
    context.read<BookingProvider>().updateInsurance(_hasInsurance, insuranceAmount, pctRate);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final pricingProvider = context.watch<PricingProvider>();
    final draft = context.watch<BookingProvider>().draft;
    
    if (pricingProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    final pctRate = pricingProvider.insurancePercentage;

    final double vehicleValue = draft.vehicleValue ?? 0;
    final double calculatedInsurance = _hasInsurance
        ? (vehicleValue > 0 ? (vehicleValue * (pctRate / 100)) : 15000)
        : 0;
    
    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final formattedInsuranceFee = currencyFormatter.format(calculatedInsurance > 0 ? calculatedInsurance : (vehicleValue * (pctRate / 100)));
    final formattedVehicleValue = currencyFormatter.format(vehicleValue);
    final pctLabel = NumberFormat('0.##').format(pctRate); // 20 -> "20", 1.5 -> "1.5"

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.shield_rounded,
            title: 'Insurance',
            subtitle: 'Protect your vehicle during transit',
          ),

          SizedBox(height: 28),

          // Insurance ON card
          GestureDetector(
            onTap: () => setState(() => _hasInsurance = true),
            child: _InsuranceCard(
              isSelected: _hasInsurance,
              title: 'Add Insurance Coverage',
              subtitle: 'Covered at $pctLabel% of your vehicle\'s declared worth ($formattedVehicleValue).',
              price: formattedInsuranceFee,
              features: [
                'Full replacement value coverage based on $formattedVehicleValue vehicle worth',
                'Rate: $pctLabel% of declared vehicle value',
                'Damage from accidents & collisions',
                'Theft & vandalism protection',
                'Weather and natural disaster cover',
                '24/7 claims support',
              ],
              isRecommended: true,
            ),
          ),

          SizedBox(height: 16),

          // Insurance OFF card
          GestureDetector(
            onTap: () => setState(() => _hasInsurance = false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_hasInsurance ? context.colors.errorLight : context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_hasInsurance ? context.colors.error : context.colors.border,
                  width: !_hasInsurance ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !_hasInsurance ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: !_hasInsurance ? context.colors.error : context.colors.textLight,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Decline Insurance',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'I understand that my vehicle will not be covered in the event of damage or loss.',
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          if (_hasInsurance)
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: context.colors.success, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Great choice! Your vehicle ($formattedVehicleValue worth) is protected for $formattedInsuranceFee ($pctLabel%) added to your booking total.',
                      style: TextStyle(fontSize: 12, color: context.colors.success, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 32),

          CustomButton(label: 'Continue', onPressed: () => _submit(context)),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final String price;
  final List<String> features;
  final bool isRecommended;

  const _InsuranceCard({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.features,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.accent.withValues(alpha: 0.04) : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? context.colors.accent : context.colors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? context.colors.accent : context.colors.textLight,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap lets the badge drop to its own line on narrow screens
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      SizedBox(height: 10),
                      // Price sits on its own line: it scales with vehicle worth and can be long
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              price,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? context.colors.accent : context.colors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text('one-time', style: TextStyle(fontSize: 11, color: context.colors.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Features list
          Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            padding: EdgeInsets.all(14),
            child: Column(
              children: features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, color: context.colors.success, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(f, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    ),
                  ],
                ),
              )).toList(),
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
