import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../../../core/widgets/status_badge.dart';

class BookingProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // The wizard draft being built
  BookingDraft _draft = BookingDraft();

  // All submitted bookings from Supabase
  List<BookingModel> _bookings = [];

  // Current wizard step (0–6)
  int _currentStep = 0;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;

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

  BookingProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    final user = _supabase.auth.currentUser;
    final uid = user?.id ?? defaultDemoClientId;
    fetchBookings(uid);
    subscribeToBookings(uid);

    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        fetchBookings(user.id);
        subscribeToBookings(user.id);
      } else {
        fetchBookings(defaultDemoClientId);
        subscribeToBookings(defaultDemoClientId);
      }
    });
  }

  /// Fetch bookings from Supabase
  Future<void> fetchBookings([String? userId]) async {
    final uid = userId ?? _supabase.auth.currentUser?.id ?? defaultDemoClientId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      _bookings = (data as List)
          .map((json) => BookingModel.fromSupabaseMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching bookings from Supabase: $e');
      _errorMessage = 'Failed to load bookings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribe to real-time status and tracking updates
  void subscribeToBookings(String userId) {
    unsubscribeFromBookings();

    _realtimeChannel = _supabase
        .channel('public:bookings:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              final updatedBooking = BookingModel.fromSupabaseMap(record);
              final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
              if (index >= 0) {
                _bookings[index] = updatedBooking;
              } else {
                _bookings.insert(0, updatedBooking);
              }
              notifyListeners();
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final deletedId = payload.oldRecord['id'] as String?;
              if (deletedId != null) {
                _bookings.removeWhere((b) => b.id == deletedId);
                notifyListeners();
              }
            }
          },
        )
        .subscribe();
  }

  void unsubscribeFromBookings() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
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
  }) {
    _draft.vehicleType = type ?? _draft.vehicleType;
    _draft.vehicleMake = make ?? _draft.vehicleMake;
    _draft.vehicleModel = model ?? _draft.vehicleModel;
    _draft.vehicleYear = year ?? _draft.vehicleYear;
    _draft.vehicleColor = color ?? _draft.vehicleColor;
    _draft.vehicleVin = vin ?? _draft.vehicleVin;
    notifyListeners();
  }

  void updatePickup({
    String? address,
    double? lat,
    double? lng,
    DateTime? dateTime,
  }) {
    _draft.pickupAddress = address ?? _draft.pickupAddress;
    _draft.pickupLat = lat ?? _draft.pickupLat;
    _draft.pickupLng = lng ?? _draft.pickupLng;
    _draft.pickupDateTime = dateTime ?? _draft.pickupDateTime;
    notifyListeners();
  }

  void updateDropoff({String? address, double? lat, double? lng}) {
    _draft.dropoffAddress = address ?? _draft.dropoffAddress;
    _draft.dropoffLat = lat ?? _draft.dropoffLat;
    _draft.dropoffLng = lng ?? _draft.dropoffLng;
    notifyListeners();
  }

  void updateServiceType(ServiceType type, double basePrice) {
    _draft.serviceType = type;
    _draft.basePrice = basePrice;
    notifyListeners();
  }

  void updateTransportMode(TransportMode mode, double enclosedAddon) {
    _draft.transportMode = mode;
    _draft.enclosedAddon = enclosedAddon;
    notifyListeners();
  }

  void updateInsurance(bool hasInsurance, double insuranceAmount) {
    _draft.hasInsurance = hasInsurance;
    _draft.insuranceAmount = insuranceAmount;
    notifyListeners();
  }

  void addDocument(String path) {
    _draft.documentPaths.add(path);
    notifyListeners();
  }

  void removeDocument(int index) {
    _draft.documentPaths.removeAt(index);
    notifyListeners();
  }

  /// Submit booking to Supabase
  Future<BookingModel?> submitBooking(String userId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload local documents if any
      final uploadedUrls = <String>[];
      for (final docPath in _draft.documentPaths) {
        if (docPath.startsWith('http://') || docPath.startsWith('https://')) {
          uploadedUrls.add(docPath);
        } else if (!kIsWeb && File(docPath).existsSync()) {
          try {
            final file = File(docPath);
            final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${docPath.split('/').last}';
            await _supabase.storage.from('documents').upload(fileName, file);
            final publicUrl = _supabase.storage.from('documents').getPublicUrl(fileName);
            uploadedUrls.add(publicUrl);
          } catch (storageError) {
            debugPrint('Document upload notice: $storageError');
            uploadedUrls.add(docPath);
          }
        } else {
          uploadedUrls.add(docPath);
        }
      }

      _draft.documentPaths = uploadedUrls;

      // 2. Insert booking record into Supabase
      final insertMap = _draft.toSupabaseInsertMap(userId);
      final response = await _supabase
          .from('bookings')
          .insert(insertMap)
          .select()
          .single();

      final booking = BookingModel.fromSupabaseMap(response);

      // Check if already in list via realtime, otherwise insert
      if (!_bookings.any((b) => b.id == booking.id)) {
        _bookings.insert(0, booking);
      }

      _isSubmitting = false;
      _draft = BookingDraft(); // Reset draft
      _currentStep = 0;
      notifyListeners();

      return booking;
    } catch (e) {
      debugPrint('Error submitting booking to Supabase: $e');
      _errorMessage = 'Failed to submit booking: $e';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

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
    unsubscribeFromBookings();
    super.dispose();
  }
}
