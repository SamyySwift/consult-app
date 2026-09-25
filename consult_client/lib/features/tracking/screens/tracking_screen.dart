import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
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
        final selected =
            active.where((b) => b.id == _selectedId).firstOrNull ??
            (active.isNotEmpty ? active.first : null);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              selected == null
                  ? _EmptyTracking()
                  : _TrackingContent(
                      booking: selected,
                      activeBookings: active,
                      onSelectBooking: (b) =>
                          setState(() => _selectedId = b.id),
                    ),
            ],
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
          LatLng(
            (b.pickup.lat + b.dropoff.lat) / 2,
            (b.pickup.lng + b.dropoff.lng) / 2,
          ),
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
    final currentLatLng =
        (booking.driverLat != null && booking.driverLng != null)
        ? LatLng(booking.driverLat!, booking.driverLng!)
        : LatLng(
            (booking.pickup.lat + booking.dropoff.lat) / 2,
            (booking.pickup.lng + booking.dropoff.lng) / 2,
          );

    void recenter() {
      if (booking.driverLat != null && booking.driverLng != null) {
        _mapController.move(
          LatLng(booking.driverLat!, booking.driverLng!),
          14.0,
        );
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
    }

    final stage = booking.status.stage;
    final journey = stage / BookingStatusStage.stageCount;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GlassPageHeader(
            title: 'Track Vehicle',
            actions: [
              GlassIconButton(
                icon: Icons.refresh_rounded,
                semanticLabel: 'Center map on vehicle',
                onTap: recenter,
              ),
            ],
          ),
        ),

        // ── Booking selector (if multiple active) ─────────────────
        if (activeBookings.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(24, 16, 24, 6),
                itemCount: activeBookings.length,
                separatorBuilder: (_, _) => SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final b = activeBookings[i];
                  final isSelected = b.id == booking.id;
                  return GestureDetector(
                    onTap: () => onSelectBooking(b),
                    child: GlassPill(
                      glow: isSelected,
                      tint: isSelected ? context.colors.accent : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        '#${shortRef(b.id)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: GlassContainer(
              radius: 28,
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: currentLatLng,
                        initialZoom:
                            (booking.driverLat != null &&
                                booking.driverLng != null)
                            ? 14.0
                            : 6.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.carpitalconsult.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                pickupLatLng,
                                currentLatLng,
                                dropoffLatLng,
                              ],
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
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.black,
                                  size: 16,
                                ),
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colors.accent.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.local_shipping_rounded,
                                  color: Colors.black,
                                  size: 22,
                                ),
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
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (booking.driverLocationAt != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _FreshnessChip(at: booking.driverLocationAt!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Journey gauge ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: ArcGauge(
                progress: journey,
                value: '${(journey * 100).round()}%',
                label: booking.status.label,
              ),
            ),
          ),
        ),

        // ── Distance and ETA ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: _LiveProgressCard(booking: booking),
          ),
        ),

        // ── Booking + driver ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: GlassContainer(
              radius: 24,
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      GlassContainer(
                        width: 44,
                        height: 44,
                        radius: 15,
                        tint: context.colors.accent,
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: context.colors.accentLight,
                          size: 21,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.vehicle.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Booking #${shortRef(booking.id)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      StatusBadge(status: booking.status, compact: true),
                    ],
                  ),
                  if (booking.driverName != null) ...[
                    SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        GlassContainer(
                          width: 44,
                          height: 44,
                          radius: 22,
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.driverName!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Assigned Driver',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (booking.driverPhone != null)
                          GlassIconButton(
                            icon: Icons.phone_rounded,
                            size: 42,
                            iconColor: context.colors.accent,
                            semanticLabel: 'Call driver',
                            onTap: () =>
                                _callDriver(context, booking.driverPhone!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Status timeline ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 30, 24, 14),
            child: Text(
              'Shipment Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: GlassContainer(
              radius: 24,
              padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _StatusTimeline(status: booking.status),
            ),
          ),
        ),

        // Clear the floating nav bar.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
        ),
      ],
    );
  }
}

Future<void> _callDriver(BuildContext context, String phone) async {
  final uri = Uri(
    scheme: 'tel',
    path: phone.replaceAll(RegExp(r'[^0-9+]'), ''),
  );
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not start a call to $phone')));
  }
}

/// Frosted chip over the map showing how fresh the driver's position is.
/// Rebuilds on a timer so "updated X ago" stays current.
class _FreshnessChip extends StatefulWidget {
  final DateTime at;
  const _FreshnessChip({required this.at});

  @override
  State<_FreshnessChip> createState() => _FreshnessChipState();
}

class _FreshnessChipState extends State<_FreshnessChip> {
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

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(widget.at);
    final isStale = age > _staleAfter;
    final dot = isStale ? context.colors.warning : context.colors.success;

    return GlassPill(
      blur: true,
      tint: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dot.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 6),
          Text(
            isStale
                ? 'Last seen ${_formatAgo(age)}'
                : 'Live · updated ${_formatAgo(age)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distance left and a rough arrival estimate.
class _LiveProgressCard extends StatelessWidget {
  // Straight-line distance understates road distance; this is a typical detour factor.
  static const _roadFactor = 1.3;
  // Average truck speed including traffic and stops, for a rough estimate only.
  static const _avgSpeedKmh = 45.0;

  final BookingModel booking;
  const _LiveProgressCard({required this.booking});

  String _formatEta(double hours) {
    final minutes = (hours * 60).round();
    if (minutes < 60) return '${minutes.clamp(1, 59)} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  @override
  Widget build(BuildContext context) {
    final lat = booking.driverLat;
    final lng = booking.driverLng;

    if (lat == null || lng == null) {
      return _card(
        context,
        icon: Icons.gps_not_fixed_rounded,
        highlighted: false,
        title: 'Waiting for the driver\'s location',
        subtitle: 'The map will update live once your driver starts moving.',
      );
    }

    // Before pickup the driver is heading to the pickup point
    final headingToPickup =
        booking.status == BookingStatusEnum.pending ||
        booking.status == BookingStatusEnum.confirmed;
    final target = headingToPickup ? booking.pickup : booking.dropoff;
    final km =
        const Distance().as(
          LengthUnit.Meter,
          LatLng(lat, lng),
          LatLng(target.lat, target.lng),
        ) /
        1000;
    final roadKm = km * _roadFactor;

    final String title;
    final String subtitle;
    if (km < 0.3) {
      title = headingToPickup
          ? 'Driver is at the pickup point'
          : 'Driver is at the delivery address';
      subtitle = 'Arriving now';
    } else {
      final distance = roadKm < 10
          ? roadKm.toStringAsFixed(1)
          : roadKm.round().toString();
      title =
          'About $distance km ${headingToPickup ? 'to pickup' : 'to delivery'}';
      subtitle = 'Estimated arrival in ${_formatEta(roadKm / _avgSpeedKmh)}';
    }

    return _card(
      context,
      icon: Icons.route_rounded,
      highlighted: true,
      title: title,
      subtitle: subtitle,
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required bool highlighted,
    required String title,
    required String subtitle,
  }) {
    return GlassContainer(
      radius: 24,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          GlassContainer(
            width: 44,
            height: 44,
            radius: 15,
            tint: highlighted ? context.colors.accent : null,
            child: Icon(
              icon,
              size: 21,
              color: highlighted
                  ? context.colors.accentLight
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
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
    (
      BookingStatusEnum.confirmed,
      'Booking Confirmed',
      'Your booking has been received',
    ),
    (
      BookingStatusEnum.pickedUp,
      'Vehicle Picked Up',
      'Driver has collected your vehicle',
    ),
    (BookingStatusEnum.inTransit, 'In Transit', 'Your vehicle is on its way'),
    (BookingStatusEnum.outForDelivery, 'Out for Delivery', 'Almost there!'),
    (
      BookingStatusEnum.delivered,
      'Delivered',
      'Your vehicle has been delivered safely',
    ),
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
            indicator: _TimelineDot(complete: isComplete, current: isCurrent),
          ),
          beforeLineStyle: LineStyle(
            color: isComplete
                ? context.colors.accent
                : Colors.white.withValues(alpha: 0.10),
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: isComplete
                ? context.colors.accent
                : Colors.white.withValues(alpha: 0.10),
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
                    color: isComplete || isCurrent
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(
                      alpha: isComplete || isCurrent ? 0.6 : 0.3,
                    ),
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

/// Accent dot for a timeline step: a glowing check when done, a dim ring
/// when upcoming.
class _TimelineDot extends StatelessWidget {
  final bool complete;
  final bool current;
  const _TimelineDot({required this.complete, required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    if (!complete) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.colors.accentGradient,
        boxShadow: current
            ? [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 14)]
            : null,
      ),
      child: Icon(
        current ? Icons.radio_button_checked : Icons.check_rounded,
        size: current ? 14 : 16,
        color: Colors.black,
      ),
    );
  }
}

class _EmptyTracking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassPageHeader(title: 'Track Vehicle'),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.paddingOf(context).bottom,
              ),
              child: GlassEmptyState(
                icon: Icons.my_location_rounded,
                title: 'No Active Shipments',
                subtitle: 'Book a transport to start tracking',
                action: GlassPillButton(
                  icon: Icons.add_rounded,
                  label: 'New Booking',
                  onTap: () => context.push(AppConstants.routeBookingNew),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
