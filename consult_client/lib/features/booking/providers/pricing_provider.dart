import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_client.dart';
import '../models/pricing_model.dart';

class PricingProvider extends ChangeNotifier {
  List<PricingConfig> _pricingConfigs = [];
  bool _isLoading = false;
  String? _error;
  double _insurancePercentage = 1.5;

  List<PricingConfig> get pricingConfigs => _pricingConfigs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Admin-configured insurance fee as a percentage of vehicle worth.
  double get insurancePercentage => _insurancePercentage;

  PricingProvider() {
    _fetchPricingConfig();
    _fetchInsurancePercentage();
  }

  Future<void> _fetchInsurancePercentage() async {
    final res = await ApiClient.instance.get('/api/bookings/settings');
    final pct = res.isSuccess && res.data is Map
        ? (res.data['insurance_percentage'] as num?)?.toDouble()
        : null;
    if (pct != null && pct >= 0) {
      _insurancePercentage = pct;
      notifyListeners();
    }
  }

  Future<void> _fetchPricingConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('pricing_config')
          .select()
          .eq('is_active', true)
          .order('base_price', ascending: true);

      _pricingConfigs = (response as List)
          .map((json) => PricingConfig.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to load pricing: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  PricingConfig? getConfigForServiceType(String serviceType) {
    try {
      return _pricingConfigs.firstWhere((c) => c.serviceType == serviceType);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> refreshPricing() async {
    await Future.wait([_fetchPricingConfig(), _fetchInsurancePercentage()]);
  }
}
