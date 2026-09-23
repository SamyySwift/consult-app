import 'package:intl/intl.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/widgets/status_badge.dart';

enum DocumentType {
  orderRequest,
  proofOfHandover,
  vehicleRegistration,
  inspectionReport,
}

class OrderRequestDocument {
  final String documentNumber;
  final String bookingId;
  final DateTime issuedAt;
  final String vehicleName;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleYear;
  final String vehicleColor;
  final String vehicleVin;
  final String vehicleType;
  final String clientName;
  final String clientPhone;
  final String pickupAddress;
  final DateTime? pickupScheduledAt;
  final String dropoffAddress;
  final String serviceType;
  final String transportMode;
  final bool hasInsurance;
  final double basePrice;
  final double insuranceFee;
  final double totalAmount;
  final String paymentReference;
  final BookingStatusEnum status;

  const OrderRequestDocument({
    required this.documentNumber,
    required this.bookingId,
    required this.issuedAt,
    required this.vehicleName,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.vehicleVin,
    required this.vehicleType,
    required this.clientName,
    required this.clientPhone,
    required this.pickupAddress,
    this.pickupScheduledAt,
    required this.dropoffAddress,
    required this.serviceType,
    required this.transportMode,
    required this.hasInsurance,
    required this.basePrice,
    required this.insuranceFee,
    required this.totalAmount,
    required this.paymentReference,
    required this.status,
  });

  String get formattedIssuedDate =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(issuedAt);

  String get formattedTotalAmount {
    return '₦${totalAmount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{3})(?=\d)'),
              (m) => '${m[1]},',
            )}';
  }

  factory OrderRequestDocument.fromBooking(
    BookingModel booking, {
    String clientName = 'AutoMove Client',
    String clientPhone = '+234 800 000 0000',
  }) {
    return OrderRequestDocument(
      documentNumber: 'REQ-${booking.id}-${booking.createdAt.year}',
      bookingId: booking.id,
      issuedAt: booking.createdAt,
      vehicleName: booking.vehicle.displayName,
      vehicleMake: booking.vehicle.make,
      vehicleModel: booking.vehicle.model,
      vehicleYear: booking.vehicle.year,
      vehicleColor: booking.vehicle.color,
      vehicleVin: booking.vehicle.vin.isNotEmpty
          ? booking.vehicle.vin
          : 'VIN-VERIFIED-AUTOMOVE',
      vehicleType: booking.vehicle.typeLabel,
      clientName: clientName,
      clientPhone: clientPhone,
      pickupAddress: booking.pickup.address,
      pickupScheduledAt: booking.pickup.scheduledDateTime,
      dropoffAddress: booking.dropoff.address,
      serviceType: booking.serviceName,
      transportMode: booking.transportMode == TransportMode.enclosed
          ? 'Enclosed Carrier'
          : 'Open Multi-Car Carrier',
      hasInsurance: booking.hasInsurance,
      basePrice: booking.basePrice,
      insuranceFee: booking.insuranceFee,
      totalAmount: booking.totalAmount,
      paymentReference: booking.paymentReference ?? 'REF-${booking.id}',
      status: booking.status,
    );
  }
}

class ProofOfHandoverDocument {
  final String certificateNumber;
  final String bookingId;
  final DateTime? handoverDate;
  final String vehicleName;
  final String vehicleVin;
  final String vehicleColor;
  final String deliveryAddress;
  final String driverName;
  final String driverPhone;
  final String? clientSignatureBase64;
  final bool isGoodConditionAcknowledged;
  final bool isInspectionCompleted;
  final bool isDelivered;

  const ProofOfHandoverDocument({
    required this.certificateNumber,
    required this.bookingId,
    this.handoverDate,
    required this.vehicleName,
    required this.vehicleVin,
    required this.vehicleColor,
    required this.deliveryAddress,
    required this.driverName,
    required this.driverPhone,
    this.clientSignatureBase64,
    this.isGoodConditionAcknowledged = true,
    this.isInspectionCompleted = true,
    this.isDelivered = false,
  });

  String get formattedHandoverDate => handoverDate != null
      ? DateFormat('MMM dd, yyyy • hh:mm a').format(handoverDate!)
      : 'Pending Handover';

  factory ProofOfHandoverDocument.fromBooking(
    BookingModel booking, {
    String? signatureBase64,
  }) {
    final isDone = booking.status == BookingStatusEnum.delivered;

    return ProofOfHandoverDocument(
      certificateNumber: 'POD-${booking.id}-CERT',
      bookingId: booking.id,
      handoverDate: isDone ? booking.createdAt.add(const Duration(days: 2)) : null,
      vehicleName: booking.vehicle.displayName,
      vehicleVin: booking.vehicle.vin.isNotEmpty
          ? booking.vehicle.vin
          : 'VIN-VERIFIED',
      vehicleColor: booking.vehicle.color,
      deliveryAddress: booking.dropoff.address,
      driverName: booking.driverName ?? 'Assigned Logistics Captain',
      driverPhone: booking.driverPhone ?? '+234 812 345 6789',
      clientSignatureBase64: signatureBase64,
      isGoodConditionAcknowledged: isDone,
      isInspectionCompleted: isDone,
      isDelivered: isDone,
    );
  }
}
