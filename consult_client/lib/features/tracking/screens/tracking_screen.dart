import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_utils.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/tap_target.dart';

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
  static const _sheetMax = 0.88;

  GoogleMapController? _mapController;

  /// Sheet height as a fraction of the screen, tracked separately so dragging
  /// the sheet only rebuilds the controls riding above it, not the map.
  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.3);

  /// Collapsed sheet height, set each build from the screen and nav size.
  double _sheetMin = 0.3;

  /// Map padding: the camera centres and fits within it, and the Google logo
  /// sits at its bottom-left corner. Updated on each fit to match the sheet.
  EdgeInsets? _mapPadding;

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  BitmapDescriptor? _driverIcon;

  /// Keep the camera on the driver as live positions arrive. Turned off as
  /// soon as the user pans the map themselves.
  bool _follow = true;

  RoadRoute? _route;

  BookingModel get _booking => widget.booking;
  LatLng get _pickup => LatLng(_booking.pickup.lat, _booking.pickup.lng);
  LatLng get _dropoff => LatLng(_booking.dropoff.lat, _booking.dropoff.lng);
  LatLng? get _driver =>
      (_booking.driverLat != null && _booking.driverLng != null)
      ? LatLng(_booking.driverLat!, _booking.driverLng!)
      : null;

  /// Picked up or later: the vehicle is on the pickup → drop-off leg.
  bool get _afterPickup => _booking.status.stage >= 2;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIcons();
  }

  @override
  void dispose() {
    _sheetExtent.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    final accent = context.colors.accent;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final icons = await Future.wait([
      MarkerIcons.circle(
        size: 14,
        pixelRatio: pixelRatio,
        color: accent,
        borderColor: Colors.black,
        borderWidth: 2,
        glow: accent.withValues(alpha: 0.7),
        glowBlur: 10,
        halo: accent.withValues(alpha: 0.25),
        haloSize: 30,
      ),
      MarkerIcons.circle(
        size: 40,
        pixelRatio: pixelRatio,
        color: const Color(0xFF1A1C1B),
        borderColor: Colors.white.withValues(alpha: 0.35),
        borderWidth: 1.5,
        icon: Icons.location_on_rounded,
        iconSize: 20,
        glow: Colors.black.withValues(alpha: 0.5),
        glowBlur: 8,
      ),
      MarkerIcons.circle(
        size: 48,
        pixelRatio: pixelRatio,
        gradient: context.colors.accentGradient,
        borderColor: Colors.black,
        borderWidth: 2,
        icon: Icons.local_shipping_rounded,
        iconColor: Colors.black,
        iconSize: 22,
        glow: accent.withValues(alpha: 0.6),
        glowBlur: 18,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _pickupIcon = icons[0];
      _dropoffIcon = icons[1];
      _driverIcon = icons[2];
    });
  }

  @override
  void didUpdateWidget(covariant _TrackingContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.booking.id != widget.booking.id) {
      setState(() {
        _route = null;
        _follow = true;
      });
      _loadRoute();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
      return;
    }

    final driver = _driver;
    final moved =
        oldWidget.booking.driverLat != widget.booking.driverLat ||
        oldWidget.booking.driverLng != widget.booking.driverLng;
    if (moved && driver != null && _follow) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(driver));
    }
  }

  Future<void> _loadRoute() async {
    final bookingId = _booking.id;
    final route = await RouteService.instance.fetch(_pickup, _dropoff);
    if (!mounted || _booking.id != bookingId || route == null) return;
    setState(() => _route = route);
    if (!_follow || _driver == null) _fitAll();
  }

  /// The part of the map not covered by the header on top or the sheet at
  /// the bottom.
  EdgeInsets _visibleArea() {
    final size = MediaQuery.sizeOf(context);
    final top =
        MediaQuery.paddingOf(context).top +
        90 +
        (widget.activeBookings.length > 1 ? 56 : 0);
    final bottom = size.height * math.max(_sheetExtent.value, _sheetMin) + 12;
    return EdgeInsets.fromLTRB(0, top, 0, bottom);
  }

  void _fitAll() {
    if (_mapController == null) return;
    setState(() => _mapPadding = _visibleArea());
    // After the rebuild, so the new padding reaches the map before the fit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _mapController;
      if (!mounted || controller == null) return;
      final driver = _driver;
      // The extra edge keeps the route clear of the controls above the sheet
      fitPoints(controller, [_pickup, _dropoff, ?driver, ...?_route?.points], edge: 56);
    });
  }

  void _showWholeRoute() {
    setState(() => _follow = false);
    _fitAll();
  }

  Future<void> _followDriver() async {
    final driver = _driver;
    final controller = _mapController;
    if (driver == null || controller == null) {
      _fitAll();
      return;
    }
    setState(() => _follow = true);
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(CameraUpdate.newLatLngZoom(driver, math.max(zoom, 13)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final driver = _driver;
    final route = _route;
    final routeIndex = (route != null && driver != null)
        ? route.nearestIndex(driver)
        : null;
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Keep at least the ETA card visible above the floating nav bar.
    final sheetMin = _sheetMin = math
        .max(0.3, (MediaQuery.paddingOf(context).bottom + 150) / screenHeight)
        .clamp(0.3, 0.5);
    final multiple = widget.activeBookings.length > 1;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        _sheetExtent.value = n.extent;
        return false;
      },
      child: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────
          Positioned.fill(
            // The map doesn't say whether a camera move came from the user,
            // so watch for a drag directly to stop following the driver.
            child: Listener(
              onPointerMove: (_) {
                if (_follow) setState(() => _follow = false);
              },
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (_pickup.latitude + _dropoff.latitude) / 2,
                    (_pickup.longitude + _dropoff.longitude) / 2,
                  ),
                  zoom: 11,
                ),
                style: darkMapStyle,
                padding: _mapPadding ?? _visibleArea(),
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _fitAll();
                },
                polylines: _polylines(routeIndex),
                markers: _markers(),
              ),
            ),
          ),

          // ── Header over the map ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height:
                    MediaQuery.paddingOf(context).top + (multiple ? 190 : 140),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassPageHeader(title: 'Track Vehicle'),
                if (multiple) _bookingChips(),
                if (booking.driverLocationAt != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: _FreshnessChip(at: booking.driverLocationAt!),
                  ),
              ],
            ),
          ),

          // ── Controls riding just above the sheet ─────────────────
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _sheetExtent,
              builder: (context, extent, _) {
                // The sheet only reports its extent once dragged, so never
                // place the controls below its collapsed height.
                final bottom = screenHeight * math.max(extent, sheetMin) + 12;
                // Once the sheet covers most of the map, get out of the way
                // of the header instead of riding up over it.
                final hidden = extent > 0.55;
                return IgnorePointer(
                  ignoring: hidden,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: hidden ? 0 : 1,
                    child: Stack(
                      children: [
                        Positioned(
                          right: 16,
                          bottom: bottom,
                          child: Column(
                            children: [
                              GlassIconButton(
                                icon: _follow
                                    ? Icons.navigation_rounded
                                    : Icons.navigation_outlined,
                                iconColor: _follow
                                    ? context.colors.accent
                                    : Colors.white,
                                semanticLabel: 'Follow driver',
                                onTap: _followDriver,
                              ),
                              SizedBox(height: 10),
                              GlassIconButton(
                                icon: Icons.zoom_out_map_rounded,
                                semanticLabel: 'Show whole route',
                                onTap: _showWholeRoute,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Details sheet ───────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: sheetMin,
            minChildSize: sheetMin,
            maxChildSize: _sheetMax,
            snap: true,
            builder: (context, scrollController) => _DetailsSheet(
              scrollController: scrollController,
              children: [
                _LiveProgressCard(
                  booking: booking,
                  route: route,
                  routeIndex: routeIndex,
                ),
                SizedBox(height: 12),
                _bookingCard(),
                Padding(
                  padding: EdgeInsets.fromLTRB(4, 28, 4, 14),
                  child: Text(
                    'Shipment Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: _StatusTimeline(status: booking.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Polyline> _polylines(int? routeIndex) {
    final accent = context.colors.accent;
    final driver = _driver;
    final route = _route;
    final dashed = [PatternItem.dash(10), PatternItem.gap(8)];

    if (route == null) {
      // No road route yet (or routing unavailable): straight dashed legs.
      return {
        Polyline(
          polylineId: const PolylineId('straight'),
          points: [
            if (!_afterPickup) ?driver,
            _pickup,
            if (_afterPickup) ?driver,
            _dropoff,
          ],
          color: accent.withValues(alpha: 0.8),
          width: 3,
          patterns: dashed,
        ),
      };
    }

    // Split at the driver once they're on the pickup → drop-off leg, so the
    // stretch already driven reads as done.
    final split = (_afterPickup && routeIndex != null) ? routeIndex : 0;
    final driven = route.points.sublist(0, split + 1);
    final remaining = route.points.sublist(split);

    return {
      if (driven.length > 1)
        Polyline(
          polylineId: const PolylineId('driven'),
          points: driven,
          color: Colors.white.withValues(alpha: 0.35),
          width: 4,
        ),
      Polyline(
        polylineId: const PolylineId('remaining-glow'),
        points: remaining,
        color: accent.withValues(alpha: 0.22),
        width: 14,
        zIndex: 1,
      ),
      Polyline(
        polylineId: const PolylineId('remaining'),
        points: remaining,
        color: accent,
        width: 4,
        zIndex: 2,
      ),
      if (!_afterPickup && driver != null)
        Polyline(
          polylineId: const PolylineId('to-pickup'),
          points: [driver, _pickup],
          color: Colors.white.withValues(alpha: 0.7),
          width: 3,
          patterns: dashed,
          zIndex: 3,
        ),
    };
  }

  Set<Marker> _markers() {
    final driver = _driver;
    return {
      if (_pickupIcon != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup,
          icon: _pickupIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      if (_dropoffIcon != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoff,
          icon: _dropoffIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      if (driver != null && _driverIcon != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          icon: _driverIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
    };
  }

  Widget _bookingChips() {
    // Several bookings can be for the same car, so repeated names also show
    // the short booking reference to tell them apart.
    final nameCounts = <String, int>{};
    for (final b in widget.activeBookings) {
      nameCounts.update(b.vehicle.displayName, (n) => n + 1, ifAbsent: () => 1);
    }

    return SizedBox(
      // 14 top padding + a 44pt tap target per chip.
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(24, 14, 24, 0),
        itemCount: widget.activeBookings.length,
        separatorBuilder: (_, _) => SizedBox(width: 8),
        itemBuilder: (context, i) {
          final b = widget.activeBookings[i];
          final isSelected = b.id == _booking.id;
          return TapTarget(
            onTap: () => widget.onSelectBooking(b),
            child: GlassPill(
              blur: true,
              glow: isSelected,
              tint: isSelected ? context.colors.accent : null,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 15,
                    color: isSelected
                        ? context.colors.accentLight
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 6),
                  Text.rich(
                    TextSpan(
                      text: b.vehicle.displayName,
                      children: [
                        if (nameCounts[b.vehicle.displayName]! > 1)
                          TextSpan(
                            text: '  #${shortRef(b.id)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bookingCard() {
    final booking = _booking;
    return SurfaceCard(
      radius: 24,
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.directions_car_rounded,
                iconSize: 21,
                radius: 15,
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
                        color: Colors.white.withValues(alpha: 0.55),
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
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            SizedBox(height: 16),
            Row(
              children: [
                IconTile(icon: Icons.person_rounded, iconSize: 22, radius: 22),
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
                    iconColor: context.colors.accent,
                    semanticLabel: 'Call driver',
                    onTap: () => _callDriver(context, booking.driverPhone!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Dark frosted sheet holding the trip details, with a grab handle on top.
class _DetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final List<Widget> children;

  const _DetailsSheet({required this.scrollController, required this.children});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(32));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xE60D0E0E),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: ListView(
            controller: scrollController,
            // Clear the floating nav bar at the bottom.
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
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
          Flexible(
            child: Text(
              isStale
                  ? 'Last seen ${_formatAgo(age)}'
                  : 'Live · updated ${_formatAgo(age)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Distance left and an arrival estimate: measured along the road once the
/// vehicle is picked up and a route is available, otherwise a rough
/// straight-line guess.
class _LiveProgressCard extends StatelessWidget {
  // Straight-line distance understates road distance; this is a typical detour factor.
  static const _roadFactor = 1.3;
  // Average truck speed including traffic and stops, for a rough estimate only.
  static const _avgSpeedKmh = 45.0;

  final BookingModel booking;
  final RoadRoute? route;

  /// Index of the route point nearest the driver, when [route] is known.
  final int? routeIndex;

  const _LiveProgressCard({required this.booking, this.route, this.routeIndex});

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
    final km = metersBetween(LatLng(lat, lng), LatLng(target.lat, target.lng)) / 1000;
    final route = this.route;
    final routeIndex = this.routeIndex;
    final onRoute = !headingToPickup && route != null && routeIndex != null;
    final roadKm = onRoute
        ? route.remainingFromM(routeIndex) / 1000
        : km * _roadFactor;
    final hours = onRoute
        ? route.durationS * (roadKm * 1000 / route.distanceM) / 3600
        : roadKm / _avgSpeedKmh;

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
      subtitle = 'Estimated arrival in ${_formatEta(hours)}';
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
    return SurfaceCard(
      radius: 24,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconTile(icon: icon, iconSize: 21, radius: 15, accent: highlighted),
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

class _TimelineStep {
  final BookingStatusEnum status;
  final IconData icon;
  final String title;
  final String subtitle;
  const _TimelineStep(this.status, this.icon, this.title, this.subtitle);
}

/// Journey steps as large icon capsules down the left: done steps are tinted
/// and joined by a dashed line, the current step is a tall glowing pill, and
/// upcoming steps are dim.
class _StatusTimeline extends StatelessWidget {
  final BookingStatusEnum status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    _TimelineStep(
      BookingStatusEnum.confirmed,
      Icons.event_available_rounded,
      'Booking Confirmed',
      'Your booking has been received',
    ),
    _TimelineStep(
      BookingStatusEnum.pickedUp,
      Icons.key_rounded,
      'Vehicle Picked Up',
      'Driver has collected your vehicle',
    ),
    _TimelineStep(
      BookingStatusEnum.inTransit,
      Icons.local_shipping_rounded,
      'In Transit',
      'Your vehicle is on its way',
    ),
    _TimelineStep(
      BookingStatusEnum.outForDelivery,
      Icons.near_me_rounded,
      'Out for Delivery',
      'Almost there!',
    ),
    _TimelineStep(
      BookingStatusEnum.delivered,
      Icons.verified_rounded,
      'Delivered',
      'Your vehicle has been delivered safely',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Steps are in journey order, so a step is done once the booking's
    // stage reaches it (stage 1 = confirmed … 5 = delivered).
    final stage = status.stage;
    final next = stage < _steps.length ? _steps[stage] : null;

    return Column(
      children: [
        // Not confirmed yet: the hint leads into the first step.
        if (stage == 0 && next != null) _NextUpRow(title: next.title),
        for (var i = 0; i < _steps.length; i++) ...[
          _TimelineRow(
            step: _steps[i],
            state: i + 1 < stage
                ? _StepState.done
                : i + 1 == stage
                ? _StepState.current
                : _StepState.upcoming,
            // Dashed while the journey has passed this link, solid ahead.
            connector: i == _steps.length - 1
                ? null
                : (i + 2 <= stage ? _Connector.dashed : _Connector.solid),
          ),
          if (next != null && i + 1 == stage) _NextUpRow(title: next.title),
        ],
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

enum _Connector { dashed, solid }

class _TimelineRow extends StatelessWidget {
  static const _railWidth = 60.0;

  final _TimelineStep step;
  final _StepState state;
  final _Connector? connector;

  const _TimelineRow({
    required this.step,
    required this.state,
    required this.connector,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    final isCurrent = state == _StepState.current;
    final isDone = state == _StepState.done;

    final Widget capsule = Container(
      width: _railWidth,
      height: isCurrent ? 92 : _railWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_railWidth / 2),
        gradient: isCurrent ? context.colors.accentGradient : null,
        color: isCurrent
            ? null
            : isDone
            ? accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        border: isCurrent
            ? null
            : Border.all(
                color: isDone
                    ? accent.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.10),
              ),
        boxShadow: isCurrent
            ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 22)]
            : null,
      ),
      child: Icon(
        step.icon,
        size: 26,
        color: isCurrent
            ? Colors.black
            : isDone
            ? context.colors.accentLight
            : Colors.white.withValues(alpha: 0.35),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                capsule,
                if (connector != null)
                  Expanded(
                    child: _ConnectorLine(
                      dashed: connector == _Connector.dashed,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isCurrent ? 18 : 8, bottom: 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrent ? 'Happening now' : step.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? accent
                          : Colors.white.withValues(alpha: isDone ? 0.5 : 0.3),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white.withValues(
                        alpha: state == _StepState.upcoming ? 0.45 : 1,
                      ),
                    ),
                  ),
                  if (isCurrent) ...[
                    SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Next up" hint sitting on the rail between the current and next step.
class _NextUpRow extends StatelessWidget {
  final String title;
  const _NextUpRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _TimelineRow._railWidth,
            child: const _ConnectorLine(dashed: false),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 22),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: 'Next up: ',
                        children: [
                          TextSpan(
                            text: title,
                            style: TextStyle(
                              color: context.colors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical rail segment centred in the icon column.
class _ConnectorLine extends StatelessWidget {
  final bool dashed;
  const _ConnectorLine({required this.dashed});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RailPainter(
        dashed: dashed,
        color: dashed
            ? context.colors.accent.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.12),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RailPainter extends CustomPainter {
  final bool dashed;
  final Color color;
  _RailPainter({required this.dashed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 4 : 3
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    const dash = 7.0;
    const gap = 6.0;
    for (var y = gap / 2; y < size.height; y += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dash, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.dashed != dashed || old.color != color;
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
