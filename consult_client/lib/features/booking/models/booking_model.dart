import 'dart:math';
import '../../../core/widgets/status_badge.dart';

enum VehicleType { sedan, suv, truck, van, motorcycle }
enum ServiceType { standard, express, whiteGlove }
enum TransportMode { open, enclosed }

class VehicleDetails {
  final VehicleType type;
  final String make;
  final String model;
  final String year;
  final String color;
  final String vin;

  const VehicleDetails({
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    this.vin = '',
  });

  String get displayName => '$year $make $model';

  String get typeLabel {
    switch (type) {
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.van:
        return 'Van';
      case VehicleType.motorcycle:
        return 'Motorcycle';
    }
  }
}

class BookingLocation {
  final String address;
  final double lat;
  final double lng;
  final DateTime? scheduledDateTime;

  const BookingLocation({
    required this.address,
    required this.lat,
    required this.lng,
    this.scheduledDateTime,
  });
}

class BookingModel {
  final String id;
  final String userId;
  final VehicleDetails vehicle;
  final BookingLocation pickup;
  final BookingLocation dropoff;
  final ServiceType serviceType;
  final TransportMode transportMode;
  final bool hasInsurance;
  final List<String> documentPaths;
  final double basePrice;
  final double insuranceFee;
  final double totalAmount;
  final BookingStatusEnum status;
  final DateTime createdAt;
  final String? driverName;
  final String? driverPhone;
  final String? paymentReference;
  final String? clientSignatureUrl;
  final double? driverLat;
  final double? driverLng;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.vehicle,
    required this.pickup,
    required this.dropoff,
    required this.serviceType,
    required this.transportMode,
    required this.hasInsurance,
    required this.documentPaths,
    required this.basePrice,
    required this.insuranceFee,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.driverName,
    this.driverPhone,
    this.paymentReference,
    this.clientSignatureUrl,
    this.driverLat,
    this.driverLng,
  });

  String get serviceName {
    switch (serviceType) {
      case ServiceType.standard:
        return 'Standard';
      case ServiceType.express:
        return 'Express';
      case ServiceType.whiteGlove:
        return 'White Glove';
    }
  }

  factory BookingModel.fromSupabaseMap(Map<String, dynamic> json) {
    // Parse VehicleType
    VehicleType vehicleType = VehicleType.sedan;
    final vTypeStr = (json['vehicle_type'] as String?)?.toLowerCase();
    for (final t in VehicleType.values) {
      if (t.name.toLowerCase() == vTypeStr) {
        vehicleType = t;
        break;
      }
    }

    // Parse ServiceType
    ServiceType serviceType = ServiceType.standard;
    final sTypeStr = (json['service_type'] as String?)?.toLowerCase();
    if (sTypeStr == 'express') {
      serviceType = ServiceType.express;
    } else if (sTypeStr == 'whiteglove' || sTypeStr == 'white_glove') {
      serviceType = ServiceType.whiteGlove;
    }

    // Parse TransportMode
    TransportMode transportMode = TransportMode.open;
    final tModeStr = (json['transport_mode'] as String?)?.toLowerCase();
    if (tModeStr == 'enclosed') {
      transportMode = TransportMode.enclosed;
    }

    // Parse BookingStatusEnum
    BookingStatusEnum status = BookingStatusEnum.pending;
    final statusStr = (json['status'] as String?)?.toLowerCase();
    switch (statusStr) {
      case 'assigned':
      case 'confirmed':
        status = BookingStatusEnum.confirmed;
        break;
      case 'pickedup':
      case 'picked_up':
        status = BookingStatusEnum.pickedUp;
        break;
      case 'intransit':
      case 'in_transit':
        status = BookingStatusEnum.inTransit;
        break;
      case 'outfordelivery':
      case 'out_for_delivery':
        status = BookingStatusEnum.outForDelivery;
        break;
      case 'delivered':
      case 'completed':
        status = BookingStatusEnum.delivered;
        break;
      case 'cancelled':
        status = BookingStatusEnum.cancelled;
        break;
      default:
        status = BookingStatusEnum.pending;
    }

    final rawDocPaths = json['document_paths'];
    List<String> docPaths = [];
    if (rawDocPaths is List) {
      docPaths = rawDocPaths.map((e) => e.toString()).toList();
    }

    return BookingModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      vehicle: VehicleDetails(
        type: vehicleType,
        make: json['vehicle_make'] as String? ?? '',
        model: json['vehicle_model'] as String? ?? '',
        year: json['vehicle_year'] as String? ?? '',
        color: json['vehicle_color'] as String? ?? '',
        vin: json['vehicle_vin'] as String? ?? '',
      ),
      pickup: BookingLocation(
        address: json['pickup_address'] as String? ?? '',
        lat: (json['pickup_lat'] as num?)?.toDouble() ?? 6.5244,
        lng: (json['pickup_lng'] as num?)?.toDouble() ?? 3.3792,
        scheduledDateTime: json['pickup_datetime'] != null
            ? DateTime.tryParse(json['pickup_datetime'] as String)
            : null,
      ),
      dropoff: BookingLocation(
        address: json['dropoff_address'] as String? ?? '',
        lat: (json['dropoff_lat'] as num?)?.toDouble() ?? 9.0820,
        lng: (json['dropoff_lng'] as num?)?.toDouble() ?? 8.6753,
      ),
      serviceType: serviceType,
      transportMode: transportMode,
      hasInsurance: json['has_insurance'] as bool? ?? false,
      documentPaths: docPaths,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 75000,
      insuranceFee: (json['insurance_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 75000,
      status: status,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      paymentReference: json['payment_reference'] as String?,
      clientSignatureUrl: json['client_signature_url'] as String?,
      driverLat: (json['driver_lat'] as num?)?.toDouble(),
      driverLng: (json['driver_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'user_id': userId,
        'vehicle_type': vehicle.type.name,
        'vehicle_make': vehicle.make,
        'vehicle_model': vehicle.model,
        'vehicle_year': vehicle.year,
        'vehicle_color': vehicle.color,
        'vehicle_vin': vehicle.vin,
        'pickup_address': pickup.address,
        'pickup_lat': pickup.lat,
        'pickup_lng': pickup.lng,
        'pickup_datetime': pickup.scheduledDateTime?.toIso8601String(),
        'dropoff_address': dropoff.address,
        'dropoff_lat': dropoff.lat,
        'dropoff_lng': dropoff.lng,
        'service_type': serviceType.name,
        'transport_mode': transportMode.name,
        'has_insurance': hasInsurance,
        'document_paths': documentPaths,
        'base_price': basePrice,
        'insurance_fee': insuranceFee,
        'total_amount': totalAmount,
        'status': status.name,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'payment_reference': paymentReference,
        'client_signature_url': clientSignatureUrl,
        'driver_lat': driverLat,
        'driver_lng': driverLng,
      };
}

// Draft model while filling the wizard
class BookingDraft {
  VehicleType? vehicleType;
  String? vehicleMake;
  String? vehicleModel;
  String? vehicleYear;
  String? vehicleColor;
  String? vehicleVin;

  String? pickupAddress;
  double? pickupLat;
  double? pickupLng;
  DateTime? pickupDateTime;

  String? dropoffAddress;
  double? dropoffLat;
  double? dropoffLng;

  ServiceType serviceType = ServiceType.standard;
  TransportMode transportMode = TransportMode.open;
  bool hasInsurance = false;
  List<String> documentPaths = [];

  bool get isVehicleComplete =>
      vehicleType != null &&
      vehicleMake != null &&
      vehicleModel != null &&
      vehicleYear != null &&
      vehicleColor != null;

  bool get isLocationComplete =>
      pickupAddress != null &&
      dropoffAddress != null &&
      pickupDateTime != null;

  double basePrice = 75000;
  double enclosedAddon = 0;
  double insuranceAmount = 0;
  
  double get totalPrice => basePrice + enclosedAddon + insuranceAmount;

  Map<String, dynamic> toSupabaseInsertMap(String userId) {
    final bookingId = 'JB${100000 + Random().nextInt(900000)}';
    return {
      'id': bookingId,
      'user_id': userId,
      'vehicle_type': (vehicleType ?? VehicleType.sedan).name,
      'vehicle_make': vehicleMake?.isNotEmpty == true ? vehicleMake! : 'Toyota',
      'vehicle_model': vehicleModel?.isNotEmpty == true ? vehicleModel! : 'Camry',
      'vehicle_year': vehicleYear?.isNotEmpty == true ? vehicleYear! : '2023',
      'vehicle_color': vehicleColor?.isNotEmpty == true ? vehicleColor! : 'Black',
      'vehicle_vin': vehicleVin ?? '',
      'pickup_address': pickupAddress?.isNotEmpty == true ? pickupAddress! : 'Lagos, Nigeria',
      'pickup_lat': pickupLat ?? 6.5244,
      'pickup_lng': pickupLng ?? 3.3792,
      'pickup_datetime': (pickupDateTime ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
      'dropoff_address': dropoffAddress?.isNotEmpty == true ? dropoffAddress! : 'Abuja, Nigeria',
      'dropoff_lat': dropoffLat ?? 9.0820,
      'dropoff_lng': dropoffLng ?? 8.6753,
      'service_type': serviceType.name,
      'transport_mode': transportMode.name,
      'has_insurance': hasInsurance,
      'document_paths': documentPaths,
      'base_price': basePrice,
      'insurance_fee': insuranceAmount,
      'total_amount': totalPrice,
      'status': 'pending',
    };
  }

  BookingModel toBooking(String userId) {
    final id = 'BK${Random().nextInt(999999).toString().padLeft(6, '0')}';
    return BookingModel(
      id: id,
      userId: userId,
      vehicle: VehicleDetails(
        type: vehicleType!,
        make: vehicleMake!,
        model: vehicleModel!,
        year: vehicleYear!,
        color: vehicleColor!,
        vin: vehicleVin ?? '',
      ),
      pickup: BookingLocation(
        address: pickupAddress!,
        lat: pickupLat ?? 6.5244,
        lng: pickupLng ?? 3.3792,
        scheduledDateTime: pickupDateTime,
      ),
      dropoff: BookingLocation(
        address: dropoffAddress!,
        lat: dropoffLat ?? 9.0820,
        lng: dropoffLng ?? 8.6753,
      ),
      serviceType: serviceType,
      transportMode: transportMode,
      hasInsurance: hasInsurance,
      documentPaths: documentPaths,
      basePrice: basePrice,
      insuranceFee: insuranceAmount,
      totalAmount: totalPrice,
      status: BookingStatusEnum.pending,
      createdAt: DateTime.now(),
    );
  }
}
