import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';

class TrackingScreen extends StatefulWidget {
  /// Booking to show first, e.g. from a booking card's Track button.
  final String? bookingId;

  const TrackingScreen({super.key, this.bookingId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Store the id, not the model: live location updates replace the booking
  // object, and a held reference would keep showing the old position.
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.bookingId;
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookingId != null && widget.bookingId != oldWidget.bookingId) {
      _selectedId = widget.bookingId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final active = prov.activeBookings;
        final selected = active.where((b) => b.id == _selectedId).firstOrNull ??
            (active.isNotEmpty ? active.first : null);

        return Scaffold(
          backgroundColor: context.colors.background,
          body: selected == null
              ? _EmptyTracking()
              : _TrackingContent(
                  booking: selected,
                  activeBookings: active,
                  onSelectBooking: (b) => setState(() => _selectedId = b.id),
                ),
        );
      },
    );
  }
}

class _TrackingContent extends StatefulWidget {
  final BookingModel booking;
  final List<BookingModel> activeBookings;
  final void Function(BookingModel) onSelectBooking;

  const _TrackingContent({
    required this.booking,
    required this.activeBookings,
    required this.onSelectBooking,
  });

  @override
  State<_TrackingContent> createState() => _TrackingContentState();
}

class _TrackingContentState extends State<_TrackingContent> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant _TrackingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final oldLat = oldWidget.booking.driverLat;
    final oldLng = oldWidget.booking.driverLng;
    final newLat = widget.booking.driverLat;
    final newLng = widget.booking.driverLng;

    if (oldWidget.booking.id != widget.booking.id) {
      // Switched to another booking: jump to its driver, or its route midpoint
      final b = widget.booking;
      if (newLat != null && newLng != null) {
        _mapController.move(LatLng(newLat, newLng), 14.0);
      } else {
        _mapController.move(
          LatLng((b.pickup.lat + b.dropoff.lat) / 2, (b.pickup.lng + b.dropoff.lng) / 2),
          6.0,
        );
      }
      return;
    }

    if (newLat != null && newLng != null) {
      if (oldLat != newLat || oldLng != newLng) {
        // Safely move map if driver location changed
        _mapController.move(LatLng(newLat, newLng), _mapController.camera.zoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final activeBookings = widget.activeBookings;
    final onSelectBooking = widget.onSelectBooking;

    final pickupLatLng = LatLng(booking.pickup.lat, booking.pickup.lng);
    final dropoffLatLng = LatLng(booking.dropoff.lat, booking.dropoff.lng);

    // Use live driver position if available, else fallback to midway
    final currentLatLng = (booking.driverLat != null && booking.driverLng != null)
      ? LatLng(booking.driverLat!, booking.driverLng!)
      : LatLng(
          (booking.pickup.lat + booking.dropoff.lat) / 2,
          (booking.pickup.lng + booking.dropoff.lng) / 2,
        );

    return CustomScrollView(
      slivers: [
        // ── App bar — clean, flat ────────────────────────────────
        SliverAppBar(
          expandedHeight: 0,
          pinned: true,
          backgroundColor: context.colors.background,
          surfaceTintColor: Colors.transparent,
          title: Text('Track Vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 12),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  if (booking.driverLat != null && booking.driverLng != null) {
                    _mapController.move(LatLng(booking.driverLat!, booking.driverLng!), 14.0);
                  } else {
                    _mapController.move(currentLatLng, 6.0);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Map centered on vehicle'),
                      backgroundColor: context.colors.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        // ── Booking selector (if multiple active) ─────────────────
        if (activeBookings.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: activeBookings.length,
                itemBuilder: (context, i) {
                  final b = activeBookings[i];
                  final isSelected = b.id == booking.id;
                  return GestureDetector(
                    onTap: () => onSelectBooking(b),
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.accent : context.colors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${b.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // ── Map ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 260,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLatLng,
                  initialZoom: (booking.driverLat != null && booking.driverLng != null) ? 14.0 : 6.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.carpitalconsult.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [pickupLatLng, currentLatLng, dropoffLatLng],
                        color: context.colors.accent,
                        strokeWidth: 3.0,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Pickup
                      Marker(
                        point: pickupLatLng,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Icon(Icons.radio_button_checked, color: Colors.black, size: 16),
                        ),
                      ),
                      // Current
                      Marker(
                        point: currentLatLng,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: context.colors.accent.withValues(alpha: 0.4), blurRadius: 10)],
                          ),
                          child: Icon(Icons.local_shipping_rounded, color: Colors.black, size: 22),
                        ),
                      ),
                      // Dropoff
                      Marker(
                        point: dropoffLatLng,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.textLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Icon(Icons.location_on, color: Colors.black, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Distance, ETA and position freshness ───────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _LiveProgressCard(booking: booking),
          ),
        ),

        // ── Booking info card ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${booking.id}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        booking.vehicle.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: context.colors.textLight),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                StatusBadge(status: booking.status),
              ],
            ),
          ),
        ),

        // ── Driver card ───────────────────────────────────────────
        if (booking.driverName != null)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded, color: context.colors.accent, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.driverName!,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        Text('Assigned Driver', style: TextStyle(fontSize: 12, color: context.colors.textLight)),
                      ],
                    ),
                  ),
                  if (booking.driverPhone != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _callDriver(context, booking.driverPhone!),
                        icon: Icon(Icons.phone_rounded, size: 18, color: context.colors.accent),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // ── Status timeline ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Shipment Timeline',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _StatusTimeline(status: booking.status),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

Future<void> _callDriver(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start a call to $phone')),
    );
  }
}

/// Distance left, a rough arrival estimate, and how recent the driver's
/// position is. Rebuilds on a timer so "updated X ago" stays current.
class _LiveProgressCard extends StatefulWidget {
  final BookingModel booking;
  const _LiveProgressCard({required this.booking});

  @override
  State<_LiveProgressCard> createState() => _LiveProgressCardState();
}

class _LiveProgressCardState extends State<_LiveProgressCard> {
  // Straight-line distance understates road distance; this is a typical detour factor.
  static const _roadFactor = 1.3;
  // Average truck speed including traffic and stops, for a rough estimate only.
  static const _avgSpeedKmh = 45.0;
  static const _staleAfter = Duration(minutes: 2);

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatAgo(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds.clamp(1, 59)}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  String _formatEta(double hours) {
    final minutes = (hours * 60).round();
    if (minutes < 60) return '${minutes.clamp(1, 59)} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final lat = booking.driverLat;
    final lng = booking.driverLng;

    if (lat == null || lng == null) {
      return _card(
        context,
        icon: Icons.gps_not_fixed_rounded,
        iconColor: context.colors.textLight,
        title: 'Waiting for the driver\'s location',
        subtitle: 'The map will update live once your driver starts moving.',
      );
    }

    // Before pickup the driver is heading to the pickup point
    final headingToPickup = booking.status == BookingStatusEnum.pending ||
        booking.status == BookingStatusEnum.confirmed;
    final target = headingToPickup ? booking.pickup : booking.dropoff;
    final km = const Distance().as(LengthUnit.Meter, LatLng(lat, lng), LatLng(target.lat, target.lng)) / 1000;
    final roadKm = km * _roadFactor;

    final String title;
    final String subtitle;
    if (km < 0.3) {
      title = headingToPickup ? 'Driver is at the pickup point' : 'Driver is at the delivery address';
      subtitle = 'Arriving now';
    } else {
      final distance = roadKm < 10 ? roadKm.toStringAsFixed(1) : roadKm.round().toString();
      title = 'About $distance km ${headingToPickup ? 'to pickup' : 'to delivery'}';
      subtitle = 'Estimated arrival in ${_formatEta(roadKm / _avgSpeedKmh)}';
    }

    final at = booking.driverLocationAt;
    final age = at != null ? DateTime.now().difference(at) : null;
    final isStale = age != null && age > _staleAfter;

    return _card(
      context,
      icon: Icons.route_rounded,
      iconColor: context.colors.accent,
      title: title,
      subtitle: subtitle,
      footer: age == null
          ? null
          : Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isStale ? context.colors.warning : context.colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  isStale ? 'Last seen ${_formatAgo(age)}' : 'Live · updated ${_formatAgo(age)}',
                  style: TextStyle(fontSize: 11, color: context.colors.textLight),
                ),
              ],
            ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? footer,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                if (footer != null) ...[SizedBox(height: 8), footer],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final BookingStatusEnum status;
  _StatusTimeline({required this.status});

  final _steps = [
    (BookingStatusEnum.confirmed, 'Booking Confirmed', 'Your booking has been received'),
    (BookingStatusEnum.pickedUp, 'Vehicle Picked Up', 'Driver has collected your vehicle'),
    (BookingStatusEnum.inTransit, 'In Transit', 'Your vehicle is on its way'),
    (BookingStatusEnum.outForDelivery, 'Out for Delivery', 'Almost there!'),
    (BookingStatusEnum.delivered, 'Delivered', 'Your vehicle has been delivered safely'),
  ];

  bool _isComplete(BookingStatusEnum step) {
    final order = [
      BookingStatusEnum.pending,
      BookingStatusEnum.confirmed,
      BookingStatusEnum.pickedUp,
      BookingStatusEnum.inTransit,
      BookingStatusEnum.outForDelivery,
      BookingStatusEnum.delivered,
    ];
    return order.indexOf(status) >= order.indexOf(step);
  }

  bool _isCurrent(BookingStatusEnum step) {
    return status == step;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.asMap().entries.map((entry) {
        final i = entry.key;
        final (stepStatus, title, subtitle) = entry.value;
        final isComplete = _isComplete(stepStatus);
        final isCurrent = _isCurrent(stepStatus);

        return TimelineTile(
          axis: TimelineAxis.vertical,
          alignment: TimelineAlign.start,
          isFirst: i == 0,
          isLast: i == _steps.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 28,
            height: 28,
            color: isComplete ? context.colors.accent : (isCurrent ? context.colors.accent : context.colors.surfaceVariant),
            iconStyle: isComplete
                ? IconStyle(color: Colors.black, iconData: Icons.check_rounded, fontSize: 16)
                : isCurrent
                    ? IconStyle(color: Colors.black, iconData: Icons.radio_button_checked, fontSize: 14)
                    : null,
          ),
          beforeLineStyle: LineStyle(
            color: isComplete ? context.colors.accent : context.colors.surfaceVariant,
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: isComplete ? context.colors.accent : context.colors.surfaceVariant,
            thickness: 2,
          ),
          endChild: Container(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isComplete || isCurrent ? Colors.white : context.colors.textLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isComplete || isCurrent ? context.colors.textSecondary : context.colors.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyTracking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Track Vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.my_location_outlined, size: 64, color: context.colors.textLight),
            SizedBox(height: 16),
            Text('No Active Shipments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            SizedBox(height: 6),
            Text('Book a transport to start tracking', style: TextStyle(color: context.colors.textLight)),
          ],
        ),
      ),
    );
  }
}
