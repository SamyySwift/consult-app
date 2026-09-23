import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/pricing_provider.dart';

class Step3ServiceType extends StatefulWidget {
  final VoidCallback onNext;
  const Step3ServiceType({super.key, required this.onNext});

  @override
  State<Step3ServiceType> createState() => _Step3ServiceTypeState();
}

class _Step3ServiceTypeState extends State<Step3ServiceType> {
  late ServiceType _selectedService;
  late TransportMode _selectedMode;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _selectedService = draft.serviceType;
    _selectedMode = draft.transportMode;
  }

  void _submit(BuildContext context) {
    final pricingProvider = context.read<PricingProvider>();
    final standardConfig = pricingProvider.getConfigForServiceType('standard');
    
    double basePrice = 75000;
    if (_selectedService == ServiceType.express) {
      basePrice = pricingProvider.getConfigForServiceType('express')?.basePrice ?? 120000;
    } else if (_selectedService == ServiceType.whiteGlove) {
      basePrice = pricingProvider.getConfigForServiceType('whiteGlove')?.basePrice ?? 200000;
    } else {
      basePrice = standardConfig?.basePrice ?? 75000;
    }
    
    double enclosedAddon = 0;
    if (_selectedMode == TransportMode.enclosed) {
      enclosedAddon = standardConfig?.enclosedAddon ?? 30000;
    }

    context.read<BookingProvider>()
      ..updateServiceType(_selectedService, basePrice)
      ..updateTransportMode(_selectedMode, enclosedAddon);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final pricingProvider = context.watch<PricingProvider>();
    
    if (pricingProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.local_shipping_rounded,
            title: 'Service Type',
            subtitle: 'Choose the shipping speed and transport method',
          ),

          SizedBox(height: 28),

          Text('Shipping Speed', style: _labelStyle(context)),
          SizedBox(height: 12),

          ..._serviceOptions(context).map((opt) {
            final isSelected = _selectedService == opt.type;
            return GestureDetector(
              onTap: () => setState(() => _selectedService = opt.type),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.accent.withValues(alpha: 0.05) : context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? context.colors.accent : context.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.accent.withValues(alpha: 0.12)
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(opt.icon, color: isSelected ? context.colors.accent : context.colors.textSecondary, size: 24),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                opt.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? context.colors.accent : context.colors.textPrimary,
                                ),
                              ),
                              if (opt.badge != null) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: opt.badgeColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    opt.badge!,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(opt.subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                          SizedBox(height: 4),
                          Text(
                            opt.eta,
                            style: TextStyle(fontSize: 11, color: context.colors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${opt.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (m) => '${m[1]},')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? context.colors.accent : context.colors.textPrimary,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: context.colors.accent, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          SizedBox(height: 24),

          Text('Transport Method', style: _labelStyle(context)),
          SizedBox(height: 12),

          Row(
            children: [
              _TransportChip(
                label: 'Open Transport',
                icon: Icons.directions_car_rounded,
                description: 'Standard method, vehicle exposed',
                isSelected: _selectedMode == TransportMode.open,
                extraCost: 0,
                onTap: () => setState(() => _selectedMode = TransportMode.open),
              ),
              SizedBox(width: 12),
              _TransportChip(
                label: 'Enclosed Transport',
                icon: Icons.garage_rounded,
                description: 'Protected container, maximum safety',
                isSelected: _selectedMode == TransportMode.enclosed,
                extraCost: pricingProvider.getConfigForServiceType('standard')?.enclosedAddon ?? 30000,
                onTap: () => setState(() => _selectedMode = TransportMode.enclosed),
              ),
            ],
          ),

          SizedBox(height: 32),

          CustomButton(label: 'Continue', onPressed: () => _submit(context)),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

TextStyle _labelStyle(BuildContext context) => TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary);

List<_ServiceOption> _serviceOptions(BuildContext context) {
  final pricingProvider = context.read<PricingProvider>();
  
  return [
    _ServiceOption(
      type: ServiceType.standard,
      name: 'Standard',
      subtitle: 'Reliable delivery at the best price',
      eta: '5–7 business days',
      icon: Icons.directions_car_rounded,
      price: pricingProvider.getConfigForServiceType('standard')?.basePrice ?? 75000,
      badge: null,
      badgeColor: null,
    ),
    _ServiceOption(
      type: ServiceType.express,
      name: 'Express',
      subtitle: 'Faster delivery with priority handling',
      eta: '2–3 business days',
      icon: Icons.flash_on_rounded,
      price: pricingProvider.getConfigForServiceType('express')?.basePrice ?? 120000,
      badge: 'POPULAR',
      badgeColor: context.colors.accent,
    ),
    _ServiceOption(
      type: ServiceType.whiteGlove,
      name: 'White Glove',
      subtitle: 'Premium door-to-door, full inspection',
      eta: '1–2 business days',
      icon: Icons.star_rounded,
      price: pricingProvider.getConfigForServiceType('whiteGlove')?.basePrice ?? 200000,
      badge: 'PREMIUM',
      badgeColor: Color(0xFF8B5CF6),
    ),
  ];
}

class _ServiceOption {
  final ServiceType type;
  final String name;
  final String subtitle;
  final String eta;
  final IconData icon;
  final double price;
  final String? badge;
  final Color? badgeColor;

  _ServiceOption({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.eta,
    required this.icon,
    required this.price,
    required this.badge,
    required this.badgeColor,
  });
}

class _TransportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final double extraCost;
  final VoidCallback onTap;

  const _TransportChip({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.extraCost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.accent.withValues(alpha: 0.05) : context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? context.colors.accent : context.colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? context.colors.accent : context.colors.textSecondary, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? context.colors.accent : context.colors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
              ),
              if (extraCost > 0) ...[
                SizedBox(height: 6),
                Text(
                  '+₦${(extraCost / 1000).round()}K',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.accent),
                ),
              ],
              if (isSelected) ...[
                SizedBox(height: 6),
                Icon(Icons.check_circle_rounded, color: context.colors.accent, size: 18),
              ],
            ],
          ),
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
