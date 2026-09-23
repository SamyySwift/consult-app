import 'package:flutter/material.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/widgets/status_badge.dart';

class VehicleRecord {
  final String id;
  final String make;
  final String model;
  final String year;
  final String color;
  final VehicleType type;
  final String vin;
  final String plateNumber;
  final List<BookingModel> bookingHistory;

  const VehicleRecord({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.type,
    this.vin = '',
    this.plateNumber = '',
    this.bookingHistory = const [],
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

  IconData get iconData {
    switch (type) {
      case VehicleType.sedan:
        return Icons.directions_car_rounded;
      case VehicleType.suv:
        return Icons.airport_shuttle_rounded;
      case VehicleType.truck:
        return Icons.local_shipping_rounded;
      case VehicleType.van:
        return Icons.directions_bus_rounded;
      case VehicleType.motorcycle:
        return Icons.two_wheeler_rounded;
    }
  }

  BookingModel? get latestBooking =>
      bookingHistory.isNotEmpty ? bookingHistory.first : null;

  int get totalTransports => bookingHistory.length;

  bool get isCurrentlyInTransit => bookingHistory.any((b) =>
      b.status == BookingStatusEnum.inTransit ||
      b.status == BookingStatusEnum.outForDelivery ||
      b.status == BookingStatusEnum.pickedUp ||
      b.status == BookingStatusEnum.confirmed);

  /// Factory helper that groups a client's booking list into distinct vehicle profiles
  static List<VehicleRecord> extractFromBookings(List<BookingModel> bookings) {
    final Map<String, List<BookingModel>> map = {};

    for (final b in bookings) {
      final key = '${b.vehicle.year}_${b.vehicle.make}_${b.vehicle.model}_${b.vehicle.vin}'.toLowerCase();
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(b);
    }

    final records = <VehicleRecord>[];
    map.forEach((key, bList) {
      // Sort newest first
      bList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final primary = bList.first;
      records.add(VehicleRecord(
        id: 'VEH-${primary.vehicle.make.toUpperCase()}-${primary.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
        make: primary.vehicle.make,
        model: primary.vehicle.model,
        year: primary.vehicle.year,
        color: primary.vehicle.color,
        type: primary.vehicle.type,
        vin: primary.vehicle.vin.isNotEmpty ? primary.vehicle.vin : 'VIN-NOT-SPECIFIED',
        plateNumber: '',
        bookingHistory: bList,
      ));
    });

    return records;
  }
}
