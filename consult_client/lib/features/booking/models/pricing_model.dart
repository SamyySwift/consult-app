class PricingConfig {
  final String id;
  final String serviceType;
  final String name;
  final double basePrice;
  final double enclosedAddon;
  final double insuranceRate;

  PricingConfig({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.basePrice,
    required this.enclosedAddon,
    required this.insuranceRate,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      id: json['id'] ?? '',
      serviceType: json['service_type'] ?? '',
      name: json['name'] ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      enclosedAddon: (json['enclosed_addon'] as num?)?.toDouble() ?? 0,
      insuranceRate: (json['insurance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}
