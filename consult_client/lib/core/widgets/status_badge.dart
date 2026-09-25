import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BookingStatusEnum {
  pending,
  confirmed,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  cancelled,
}

class StatusBadge extends StatelessWidget {
  final BookingStatusEnum status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: config.dotColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(BuildContext context, BookingStatusEnum status) {
    switch (status) {
      case BookingStatusEnum.pending:
        return _StatusConfig('Pending', context.colors.warningLight, context.colors.warning);
      case BookingStatusEnum.confirmed:
        return _StatusConfig('Confirmed', context.colors.infoLight, context.colors.info);
      case BookingStatusEnum.pickedUp:
        return _StatusConfig('Picked Up', context.colors.infoLight, context.colors.info);
      case BookingStatusEnum.inTransit:
        return _StatusConfig('In Transit', context.colors.accent.withValues(alpha: 0.12), context.colors.accent);
      case BookingStatusEnum.outForDelivery:
        return _StatusConfig('Out for Delivery', context.colors.accent.withValues(alpha: 0.12), context.colors.accent);
      case BookingStatusEnum.delivered:
        return _StatusConfig('Delivered', context.colors.successLight, context.colors.success);
      case BookingStatusEnum.cancelled:
        return _StatusConfig('Cancelled', context.colors.errorLight, context.colors.error);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color dotColor;
  _StatusConfig(this.label, this.bgColor, this.dotColor);
}

extension BookingStatusStage on BookingStatusEnum {
  /// Number of steps in a shipment's journey (Confirmed → Delivered).
  static const int stageCount = 5;

  /// How many journey steps are done: 0 for pending or cancelled, 5 once
  /// delivered.
  int get stage => switch (this) {
        BookingStatusEnum.pending || BookingStatusEnum.cancelled => 0,
        BookingStatusEnum.confirmed => 1,
        BookingStatusEnum.pickedUp => 2,
        BookingStatusEnum.inTransit => 3,
        BookingStatusEnum.outForDelivery => 4,
        BookingStatusEnum.delivered => 5,
      };

  /// The vehicle is with a driver, so there's a live position to follow.
  bool get isTrackable => switch (this) {
        BookingStatusEnum.pickedUp ||
        BookingStatusEnum.inTransit ||
        BookingStatusEnum.outForDelivery => true,
        _ => false,
      };

  String get label => switch (this) {
        BookingStatusEnum.pending => 'Pending',
        BookingStatusEnum.confirmed => 'Confirmed',
        BookingStatusEnum.pickedUp => 'Picked Up',
        BookingStatusEnum.inTransit => 'In Transit',
        BookingStatusEnum.outForDelivery => 'Out for Delivery',
        BookingStatusEnum.delivered => 'Delivered',
        BookingStatusEnum.cancelled => 'Cancelled',
      };
}
