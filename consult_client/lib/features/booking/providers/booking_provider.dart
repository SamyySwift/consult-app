import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/tracking_socket.dart';

class BookingProvider extends ChangeNotifier {
  // The wizard draft being built
  BookingDraft _draft = BookingDraft();

  // All submitted bookings from API
  List<BookingModel> _bookings = [];

  // Current wizard step (0–6)
  int _currentStep = 0;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  BookingDraft get draft => _draft;
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<BookingModel> get activeBookings => _bookings
      .where((b) =>
          b.status != BookingStatusEnum.delivered &&
          b.status != BookingStatusEnum.cancelled)
      .toList();

  List<BookingModel> get completedBookings => _bookings
      .where((b) =>
          b.status == BookingStatusEnum.delivered ||
          b.status == BookingStatusEnum.cancelled)
      .toList();

  static const String defaultDemoClientId = 'b0000000-0000-0000-0000-000000000001';

  StreamSubscription<DriverLocationUpdate>? _locationSub;

  BookingProvider() {
    fetchBookings();
    _startPolling();
    _startRealtimeTracking();
  }

  /// Driver positions arrive over the socket, so this only needs to catch
  /// non-location changes (status, driver assignment) and cover reconnect gaps.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchBookings(silent: true);
    });
  }

  void _startRealtimeTracking() {
    _locationSub = TrackingSocket.instance.updates.listen(_applyDriverLocation);
    TrackingSocket.instance.connect();
  }

  void _applyDriverLocation(DriverLocationUpdate update) {
    final index = _bookings.indexWhere((b) => b.id == update.bookingId);
    if (index == -1) return;

    _bookings[index] =
        _bookings[index].copyWithDriverLocation(update.lat, update.lng);
    notifyListeners();
  }

  /// Fetch bookings from Railway API
  Future<void> fetchBookings({String? userId, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final endpoint = userId != null ? '/api/bookings?userId=$userId' : '/api/bookings';
      final res = await ApiClient.instance.get(endpoint);

      if (res.isSuccess && res.data != null) {
        final List<dynamic> data = res.data as List<dynamic>;
        _bookings = data
            .map((json) => BookingModel.fromSupabaseMap(json as Map<String, dynamic>))
            .toList();

        TrackingSocket.instance
            .subscribeTo(activeBookings.map((b) => b.id));
      }
    } catch (e) {
      debugPrint('Error fetching bookings from API: $e');
      if (!silent) {
        _errorMessage = 'Failed to load bookings: $e';
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 6) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void updateVehicleDetails({
    VehicleType? type,
    String? make,
    String? model,
    String? year,
    String? color,
    String? vin,
    double? vehicleValue,
  }) {
    _draft.vehicleType = type ?? _draft.vehicleType;
    _draft.vehicleMake = make ?? _draft.vehicleMake;
    _draft.vehicleModel = model ?? _draft.vehicleModel;
    _draft.vehicleYear = year ?? _draft.vehicleYear;
    _draft.vehicleColor = color ?? _draft.vehicleColor;
    _draft.vehicleVin = vin ?? _draft.vehicleVin;
    _draft.vehicleValue = vehicleValue ?? _draft.vehicleValue;
    notifyListeners();
  }

  void updatePickup({
    required String address,
    required double lat,
    required double lng,
    required DateTime dateTime,
  }) {
    _draft.pickupAddress = address;
    _draft.pickupLat = lat;
    _draft.pickupLng = lng;
    _draft.pickupDateTime = dateTime;
    notifyListeners();
  }

  void updateDropoff({
    required String address,
    required double lat,
    required double lng,
  }) {
    _draft.dropoffAddress = address;
    _draft.dropoffLat = lat;
    _draft.dropoffLng = lng;
    notifyListeners();
  }

  void updateServiceType(ServiceType serviceType, [double? basePrice]) {
    _draft.serviceType = serviceType;
    if (basePrice != null) _draft.basePrice = basePrice;
    notifyListeners();
  }

  void updateTransportMode(TransportMode transportMode, [double? enclosedAddon]) {
    _draft.transportMode = transportMode;
    if (enclosedAddon != null) _draft.enclosedAddon = enclosedAddon;
    notifyListeners();
  }

  void updateInsurance(bool hasInsurance, [double? insuranceAmount, double? insurancePercentage]) {
    _draft.hasInsurance = hasInsurance;
    if (insuranceAmount != null) _draft.insuranceAmount = insuranceAmount;
    if (insurancePercentage != null) _draft.insurancePercentage = insurancePercentage;
    notifyListeners();
  }

  void addDocument(String path) {
    if (!_draft.documentPaths.contains(path)) {
      _draft.documentPaths.add(path);
      notifyListeners();
    }
  }

  void removeDocument(int index) {
    if (index >= 0 && index < _draft.documentPaths.length) {
      _draft.documentPaths.removeAt(index);
      notifyListeners();
    }
  }

  /// Submit the booking draft to Railway API
  Future<BookingModel?> submitBooking(String userId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertMap = _draft.toSupabaseInsertMap(userId);
      final res = await ApiClient.instance.post('/api/bookings', insertMap);

      if (res.isSuccess && res.data != null) {
        final resData = res.data as Map<String, dynamic>;
        final bookingJson = (resData['booking'] ?? resData) as Map<String, dynamic>;
        final booking = BookingModel.fromSupabaseMap(bookingJson);

        if (!_bookings.any((b) => b.id == booking.id)) {
          _bookings.insert(0, booking);
        }

        _isSubmitting = false;
        _draft = BookingDraft();
        _currentStep = 0;
        notifyListeners();

        return booking;
      } else {
        throw Exception(res.errorMessage ?? 'Failed to submit booking');
      }
    } catch (e) {
      debugPrint('Error submitting booking to API: $e');
      _errorMessage = 'Failed to submit booking: $e';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel booking via Railway API
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final res = await ApiClient.instance.post('/api/bookings/$bookingId/cancel', {});

      if (res.isSuccess) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index >= 0) {
          final b = _bookings[index];
          _bookings[index] = BookingModel(
            id: b.id,
            userId: b.userId,
            vehicle: b.vehicle,
            pickup: b.pickup,
            dropoff: b.dropoff,
            serviceType: b.serviceType,
            transportMode: b.transportMode,
            hasInsurance: b.hasInsurance,
            documentPaths: b.documentPaths,
            basePrice: b.basePrice,
            insuranceFee: b.insuranceFee,
            totalAmount: b.totalAmount,
            status: BookingStatusEnum.cancelled,
            createdAt: b.createdAt,
            driverName: b.driverName,
            driverPhone: b.driverPhone,
            paymentReference: b.paymentReference,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  void resetDraft() {
    _draft = BookingDraft();
    _currentStep = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }
}
