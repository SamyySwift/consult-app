
import '../../../core/theme/driver_colors.dart';
import 'package:flutter/material.dart';

/// Job statuses for admin-assigned driver flow.
/// Drivers do NOT browse/accept jobs — they are assigned by the admin.
enum JobStatus {
  assigned,   // Admin assigned it; driver has not yet confirmed
  confirmed,  // Driver acknowledged the assignment
  pickedUp,   // Vehicle has been picked up from client
  inTransit,  // Vehicle is en-route to destination
  completed,  // Delivery done
  cancelled,  // Job cancelled by admin or client
}

enum VehicleType { sedan, suv, truck, van, motorcycle }
enum ServiceType { standard, express, whiteGlove }
enum TransportMode { open, enclosed }

class JobLocation {
  final String address;
  final double lat;
  final double lng;
  final DateTime? scheduledAt;

  const JobLocation({
    required this.address,
    required this.lat,
    required this.lng,
    this.scheduledAt,
  });
}

class VehicleInfo {
  final VehicleType type;
  final String make;
  final String model;
  final String year;
  final String color;
  final double vehicleValue;

  const VehicleInfo({
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    this.vehicleValue = 0,
  });

  String get displayName => '$year $make $model';

  IconData get icon {
    switch (type) {
      case VehicleType.sedan:     return Icons.directions_car_rounded;
      case VehicleType.suv:       return Icons.car_rental_rounded;
      case VehicleType.truck:     return Icons.local_shipping_rounded;
      case VehicleType.van:       return Icons.airport_shuttle_rounded;
      case VehicleType.motorcycle:return Icons.two_wheeler_rounded;
    }
  }
}

class JobModel {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final VehicleInfo vehicle;
  final JobLocation pickup;
  final JobLocation dropoff;
  final ServiceType serviceType;
  final TransportMode transportMode;
  final bool hasInsurance;
  final double totalAmount;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? confirmedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;
  final String? clientSignatureBase64;
  final DateTime? clientAcknowledgedAt;
  final String? pickupConditionDesc;
  final List<String>? pickupConditionImages;
  final String? pickupConditionAudio;

  const JobModel({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.vehicle,
    required this.pickup,
    required this.dropoff,
    required this.serviceType,
    required this.transportMode,
    required this.hasInsurance,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.confirmedAt,
    this.pickedUpAt,
    this.completedAt,
    this.clientSignatureBase64,
    this.clientAcknowledgedAt,
    this.pickupConditionDesc,
    this.pickupConditionImages,
    this.pickupConditionAudio,
  });

  String get serviceLabel {
    switch (serviceType) {
      case ServiceType.standard:   return 'Standard';
      case ServiceType.express:    return 'Express';
      case ServiceType.whiteGlove: return 'White Glove';
    }
  }

  String get transportModeLabel {
    switch (transportMode) {
      case TransportMode.open:     return 'Open Transport';
      case TransportMode.enclosed: return 'Enclosed Transport';
    }
  }

  Color get statusColor {
    switch (status) {
      case JobStatus.assigned:  return DriverColors.warning;
      case JobStatus.confirmed: return DriverColors.info;
      case JobStatus.pickedUp:  return DriverColors.info;
      case JobStatus.inTransit: return DriverColors.jobActive;
      case JobStatus.completed: return DriverColors.jobCompleted;
      case JobStatus.cancelled: return DriverColors.jobCancelled;
    }
  }

  String get statusLabel {
    switch (status) {
      case JobStatus.assigned:  return 'Assigned';
      case JobStatus.confirmed: return 'Confirmed';
      case JobStatus.pickedUp:  return 'Picked Up';
      case JobStatus.inTransit: return 'In Transit';
      case JobStatus.completed: return 'Delivered';
      case JobStatus.cancelled: return 'Cancelled';
    }
  }

  /// Safely parses a value that may be a String or num into a double.
  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  factory JobModel.fromSupabaseMap(Map<String, dynamic> map) {
    JobStatus parseStatus(String? s) {
      switch (s) {
        case 'pending':
        case 'assigned':
          return JobStatus.assigned;
        case 'confirmed':
          return JobStatus.confirmed;
        case 'pickedUp':
        case 'picked_up':
          return JobStatus.pickedUp;
        case 'inTransit':
        case 'in_transit':
        case 'outForDelivery':
          return JobStatus.inTransit;
        case 'delivered':
        case 'completed':
          return JobStatus.completed;
        case 'cancelled':
          return JobStatus.cancelled;
        default:
          return JobStatus.assigned;
      }
    }

    VehicleType parseVehicleType(String? category) {
      switch (category?.toLowerCase()) {
        case 'suv':
          return VehicleType.suv;
        case 'truck':
          return VehicleType.truck;
        case 'van':
          return VehicleType.van;
        case 'motorcycle':
          return VehicleType.motorcycle;
        default:
          return VehicleType.sedan;
      }
    }

    ServiceType parseServiceType(String? tier) {
      switch (tier) {
        case 'express':
          return ServiceType.express;
        case 'whiteGlove':
        case 'white_glove':
          return ServiceType.whiteGlove;
        default:
          return ServiceType.standard;
      }
    }

    TransportMode parseTransportMode(String? mode) {
      return mode?.toLowerCase() == 'enclosed'
          ? TransportMode.enclosed
          : TransportMode.open;
    }

    final userProfile = map['profiles'] as Map<String, dynamic>?;
    final customerName = userProfile?['full_name'] as String? ??
        map['client_name'] as String? ??
        map['recipient_name'] as String? ??
        'Consult Client';
    final customerPhone = userProfile?['phone'] as String? ??
        map['client_phone'] as String? ??
        map['recipient_phone'] as String? ??
        '+234 800 000 0000';

    return JobModel(
      id: map['id']?.toString() ?? 'BK-0000',
      customerId: map['user_id']?.toString() ?? '',
      customerName: customerName,
      customerPhone: customerPhone,
      vehicle: VehicleInfo(
        type: parseVehicleType(map['vehicle_type'] ?? map['vehicle_category']),
        make: map['vehicle_make']?.toString() ?? 'Vehicle',
        model: map['vehicle_model']?.toString() ?? '',
        year: map['vehicle_year']?.toString() ?? '2024',
        color: map['vehicle_color']?.toString() ?? 'Black',
        vehicleValue: _parseDouble(map['vehicle_value'], 0.0),
      ),
      pickup: JobLocation(
        address: map['pickup_address']?.toString() ?? 'Pickup Location',
        lat: _parseDouble(map['pickup_lat'] ?? map['pickup_latitude'], 6.5244),
        lng: _parseDouble(map['pickup_lng'] ?? map['pickup_longitude'], 3.3792),
        scheduledAt: map['pickup_datetime'] != null
            ? DateTime.tryParse(map['pickup_datetime'].toString())
            : (map['pickup_date'] != null ? DateTime.tryParse(map['pickup_date'].toString()) : null),
      ),
      dropoff: JobLocation(
        address: map['dropoff_address']?.toString() ?? 'Destination Location',
        lat: _parseDouble(map['dropoff_lat'] ?? map['dropoff_latitude'], 9.0765),
        lng: _parseDouble(map['dropoff_lng'] ?? map['dropoff_longitude'], 7.3986),
        scheduledAt: null,
      ),
      serviceType: parseServiceType(map['service_type'] ?? map['service_tier']),
      transportMode: parseTransportMode(map['transport_mode'] ?? map['transport_type']),
      hasInsurance: map['has_insurance'] ?? map['insurance_covered'] ?? false,
      totalAmount: _parseDouble(map['total_amount'] ?? map['total_price'], 0.0),
      status: parseStatus(map['status']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedAt: map['assigned_at'] != null
          ? DateTime.tryParse(map['assigned_at'].toString())
          : (map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null),
      confirmedAt: map['confirmed_at'] != null ? DateTime.tryParse(map['confirmed_at'].toString()) : null,
      pickedUpAt: map['picked_up_at'] != null ? DateTime.tryParse(map['picked_up_at'].toString()) : null,
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
      clientSignatureBase64: map['client_signature_url']?.toString(),
      clientAcknowledgedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
      pickupConditionDesc: map['pickup_condition_desc']?.toString(),
      pickupConditionImages: map['pickup_condition_images'] != null ? List<String>.from(map['pickup_condition_images'] as List) : null,
      pickupConditionAudio: map['pickup_condition_audio']?.toString(),
    );
  }

  IconData get statusIcon {
    switch (status) {
      case JobStatus.assigned:  return Icons.assignment_rounded;
      case JobStatus.confirmed: return Icons.check_circle_rounded;
      case JobStatus.pickedUp:  return Icons.local_shipping_rounded;
      case JobStatus.inTransit: return Icons.moving_rounded;
      case JobStatus.completed: return Icons.task_alt_rounded;
      case JobStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  bool get isActive =>
      status == JobStatus.confirmed ||
      status == JobStatus.pickedUp ||
      status == JobStatus.inTransit;

  JobModel copyWith({JobStatus? status, DateTime? confirmedAt, DateTime? pickedUpAt, DateTime? completedAt, String? clientSignatureBase64, DateTime? clientAcknowledgedAt, String? pickupConditionDesc, List<String>? pickupConditionImages, String? pickupConditionAudio}) {
    return JobModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicle: vehicle,
      pickup: pickup,
      dropoff: dropoff,
      serviceType: serviceType,
      transportMode: transportMode,
      hasInsurance: hasInsurance,
      totalAmount: totalAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      assignedAt: assignedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      completedAt: completedAt ?? this.completedAt,
      clientSignatureBase64: clientSignatureBase64 ?? this.clientSignatureBase64,
      clientAcknowledgedAt: clientAcknowledgedAt ?? this.clientAcknowledgedAt,
      pickupConditionDesc: pickupConditionDesc ?? this.pickupConditionDesc,
      pickupConditionImages: pickupConditionImages ?? this.pickupConditionImages,
      pickupConditionAudio: pickupConditionAudio ?? this.pickupConditionAudio,
    );
  }
}

// Mock data — all jobs are assigned by admin, no "available" browsing
List<JobModel> generateMockJobs() {
  return [
    // New assignment — driver hasn't confirmed yet
    JobModel(
      id: 'JB00921',
      customerId: 'cust_1',
      customerName: 'Emeka Obi',
      customerPhone: '+234 805 123 4567',
      vehicle: const VehicleInfo(
        type: VehicleType.suv,
        make: 'Toyota',
        model: 'Prado',
        year: '2021',
        color: 'White',
      ),
      pickup: JobLocation(
        address: '15 Adeola Hopewell St, Victoria Island, Lagos',
        lat: 6.4281,
        lng: 3.4219,
        scheduledAt: DateTime.now().add(const Duration(hours: 3)),
      ),
      dropoff: const JobLocation(
        address: '23 Aguiyi-Ironsi St, Maitama, Abuja',
        lat: 9.0765,
        lng: 7.4983,
      ),
      serviceType: ServiceType.express,
      transportMode: TransportMode.enclosed,
      hasInsurance: true,
      totalAmount: 165000,
      status: JobStatus.assigned,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      assignedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    // Currently in transit
    JobModel(
      id: 'JB00744',
      customerId: 'cust_3',
      customerName: 'Bola Adeyemi',
      customerPhone: '+234 903 456 7890',
      vehicle: const VehicleInfo(
        type: VehicleType.sedan,
        make: 'Ford',
        model: 'Mustang',
        year: '2022',
        color: 'Black',
      ),
      pickup: JobLocation(
        address: 'Plot 12 Lekki Phase 1, Lagos',
        lat: 6.4281,
        lng: 3.5225,
        scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      dropoff: const JobLocation(
        address: '44 GRA, Port Harcourt',
        lat: 4.8156,
        lng: 7.0498,
      ),
      serviceType: ServiceType.whiteGlove,
      transportMode: TransportMode.enclosed,
      hasInsurance: true,
      totalAmount: 245000,
      status: JobStatus.inTransit,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      assignedAt: DateTime.now().subtract(const Duration(hours: 26)),
      confirmedAt: DateTime.now().subtract(const Duration(hours: 25)),
      pickedUpAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    // Completed delivery
    JobModel(
      id: 'JB00612',
      customerId: 'cust_4',
      customerName: 'Chioma Eze',
      customerPhone: '+234 811 222 3333',
      vehicle: const VehicleInfo(
        type: VehicleType.sedan,
        make: 'Mercedes',
        model: 'C300',
        year: '2022',
        color: 'Navy Blue',
      ),
      pickup: JobLocation(
        address: '10 Marina, Lagos Island',
        lat: 6.4530,
        lng: 3.4006,
        scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      dropoff: const JobLocation(
        address: '55 Independence Way, Kaduna',
        lat: 10.5264,
        lng: 7.4395,
      ),
      serviceType: ServiceType.express,
      transportMode: TransportMode.enclosed,
      hasInsurance: true,
      totalAmount: 180000,
      status: JobStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      assignedAt: DateTime.now().subtract(const Duration(days: 4)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 3, hours: 23)),
      pickedUpAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      clientAcknowledgedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // Another completed
    JobModel(
      id: 'JB00501',
      customerId: 'cust_5',
      customerName: 'Tunde Fashola',
      customerPhone: '+234 807 654 3210',
      vehicle: const VehicleInfo(
        type: VehicleType.suv,
        make: 'Lexus',
        model: 'LX 570',
        year: '2020',
        color: 'Pearl White',
      ),
      pickup: JobLocation(
        address: 'Ikeja City Mall, Lagos',
        lat: 6.6018,
        lng: 3.3515,
        scheduledAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      dropoff: const JobLocation(
        address: 'Trans Amadi Industrial Estate, Port Harcourt',
        lat: 4.8242,
        lng: 7.0336,
      ),
      serviceType: ServiceType.standard,
      transportMode: TransportMode.open,
      hasInsurance: false,
      totalAmount: 95000,
      status: JobStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      assignedAt: DateTime.now().subtract(const Duration(days: 9)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 9)),
      pickedUpAt: DateTime.now().subtract(const Duration(days: 8, hours: 4)),
      completedAt: DateTime.now().subtract(const Duration(days: 7)),
      clientAcknowledgedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
}
