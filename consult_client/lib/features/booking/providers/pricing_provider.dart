import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pricing_model.dart';

class PricingProvider extends ChangeNotifier {
  List<PricingConfig> _pricingConfigs = [];
  bool _isLoading = false;
  String? _error;

  List<PricingConfig> get pricingConfigs => _pricingConfigs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PricingProvider() {
    _fetchPricingConfig();
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
    await _fetchPricingConfig();
  }
}
