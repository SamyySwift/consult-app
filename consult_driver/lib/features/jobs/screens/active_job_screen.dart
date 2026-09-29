import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/network/route_service.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/location_required_banner.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/links.dart';
import '../../../core/utils/marker_images.dart';
import '../../../core/widgets/surface.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';
import '../widgets/job_ui.dart';
import 'delivery_acknowledgement_sheet.dart';
import 'pickup_condition_form.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _nav = NavigationService.instance;
  StreamSubscription<NavLeg>? _arrivalSub;
  bool _startingNav = false;

  @override
  void initState() {
    super.initState();
    _arrivalSub = _nav.arrivals.listen(_onArrival);
  }

  @override
  void dispose() {
    _arrivalSub?.cancel();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  void _onArrival(NavLeg leg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161616),
        content: Text(
          leg == NavLeg.toPickup
              ? "You've arrived at the pickup point. Confirm the vehicle pickup below."
              : "You've arrived at the delivery address. Complete the handover below.",
        ),
      ),
    );
  }

  /// The leg the driver would navigate next for [job], if any.
  NavLeg? _legFor(JobModel job) => switch (job.status) {
    JobStatus.confirmed => NavLeg.toPickup,
    JobStatus.inTransit => NavLeg.toDropoff,
    _ => null,
  };

  Future<void> _startNavigation(JobModel job, NavLeg leg) async {
    if (_startingNav) return;
    final ok = await DriverLocationAccess.ensure(
      context,
      reason: 'Turn-by-turn directions and your client\'s tracking use your location.',
    );
    if (!ok || !mounted) return;

    setState(() => _startingNav = true);
    final target = leg == NavLeg.toPickup ? job.pickup : job.dropoff;
    final result = await _nav.start(
      leg: leg,
      lat: target.lat,
      lng: target.lng,
      title: target.address.split(',').first,
    );
    if (!mounted) return;
    setState(() => _startingNav = false);

    if (!result.started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF161616),
          duration: const Duration(seconds: 8),
          content: Text(result.message ?? 'Navigation couldn\'t start.'),
          action: SnackBarAction(
            label: 'Google Maps',
            textColor: DriverColors.accent,
            onPressed: () => _openInGoogleMaps(target),
          ),
        ),
      );
    }
  }

  /// Fallback when in-app navigation can't run: hand the trip to Google Maps.
  void _openInGoogleMaps(JobLocation target) {
    openLink(
      context,
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${target.lat},${target.lng}',
        'travelmode': 'driving',
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JobProvider>();
    final job = prov.activeJob;

    if (job == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const Positioned.fill(child: AuroraBackground()),
            Column(
              children: [
                GlassPageHeader(
                  title: 'Active Mission',
                  showBack: true,
                  onBack: _goBack,
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: GlassEmptyState(
                        icon: Icons.navigation_outlined,
                        title: 'No active mission selected.',
                        subtitle: 'Confirm an assigned job to start navigating it here.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _nav.guiding,
      builder: (context, guiding, _) {
        final leg = _legFor(job);
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(child: _JobMap(job: job, guiding: guiding)),

              // Location warning + back button. While guiding, Google's turn
              // instructions use the top of the screen, so only the warning shows.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocationRequiredBanner(),
                    if (!guiding)
                      Padding(
                        // The banner already clears the status bar when it's shown
                        padding: EdgeInsets.only(
                          left: 16,
                          top: prov.locationBlocked ? 10 : MediaQuery.of(context).padding.top + 10,
                        ),
                        child: GlassIconButton(
                          icon: Icons.chevron_left_rounded,
                          semanticLabel: 'Back',
                          onTap: _goBack,
                        ),
                      ),
                  ],
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: guiding
                    ? _GuidancePanel(
                        action: _buildStatusAction(context, prov, job),
                        onBack: _goBack,
                      )
                    : _JobSheet(
                        job: job,
                        navAction: leg == null
                            ? null
                            : DriverButton(
                                label: leg == NavLeg.toPickup ? 'Navigate to Pickup' : 'Navigate to Drop-off',
                                isOutlined: true,
                                isLoading: _startingNav,
                                icon: const Icon(Icons.navigation_rounded, size: 18, color: DriverColors.accent),
                                onPressed: () => _startNavigation(job, leg),
                              ),
                        action: _buildStatusAction(context, prov, job),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusAction(BuildContext context, JobProvider prov, JobModel job) {
    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator(color: DriverColors.accent));
    }

    switch (job.status) {
      case JobStatus.confirmed:
        return DriverButton(
          label: 'Confirm Vehicle Pickup',
          backgroundColor: DriverColors.accent,
          foregroundColor: Colors.black,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => PickupConditionForm(job: job),
            );
          },
        );
      case JobStatus.pickedUp:
        return DriverButton(
          label: 'Initiate Route Transit',
          backgroundColor: DriverColors.accent,
          foregroundColor: Colors.black,
          onPressed: () async {
            final ok = await DriverLocationAccess.ensure(
              context,
              reason: 'Your client tracks this delivery using your location. Turn it on to start the trip.',
            );
            if (!ok) return;
            await prov.updateJobStatus(job.id, JobStatus.inTransit);
            // Straight into turn-by-turn to the drop-off
            final updated = prov.activeJob;
            if (updated != null && mounted) await _startNavigation(updated, NavLeg.toDropoff);
          },
        );
      case JobStatus.inTransit:
        return DriverButton(
          label: 'Finalize & Client Handover',
          backgroundColor: DriverColors.accent,
          foregroundColor: Colors.black,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => DeliveryAcknowledgementSheet(
                onConfirm: (signatureBase64) async {
                  await prov.updateJobStatus(
                    job.id,
                    JobStatus.completed,
                    clientSignatureBase64: signatureBase64,
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery Completed Successfully!'),
                        backgroundColor: Color(0xFF161616),
                      ),
                    );
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.dashboard);
                    }
                  }
                },
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Map ───────────────────────────────────────────────────────────────────

/// Full-screen Google map. Before guidance it shows the road route with the
/// pickup and drop-off markers; while guiding it's Google's turn-by-turn view.
///
/// The navigation view needs a navigation session (which needs Google's terms
/// accepted), so until the driver first starts navigating a plain map view
/// shows the overview instead.
class _JobMap extends StatefulWidget {
  final JobModel job;
  final bool guiding;
  const _JobMap({required this.job, required this.guiding});

  @override
  State<_JobMap> createState() => _JobMapState();
}

class _JobMapState extends State<_JobMap> {
  // Roughly the height of the bottom sheet / guidance panel, so fitted routes
  // and the driver's position stay visible above them.
  static const _sheetAllowance = 400.0;
  static const _guidanceAllowance = 200.0;

  GoogleMapViewController? _controller;
  RoadRoute? _route;
  ImageDescriptor? _pickupIcon;
  ImageDescriptor? _dropoffIcon;
  bool _iconsRequested = false;

  LatLng get _pickup => LatLng(latitude: widget.job.pickup.lat, longitude: widget.job.pickup.lng);
  LatLng get _dropoff => LatLng(latitude: widget.job.dropoff.lat, longitude: widget.job.dropoff.lng);

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iconsRequested) {
      _iconsRequested = true;
      _loadIcons();
    }
  }

  @override
  void didUpdateWidget(covariant _JobMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.id != widget.job.id) {
      setState(() => _route = null);
      _loadRoute();
      _decorate();
    } else if (oldWidget.guiding != widget.guiding) {
      _decorate();
    }
  }

  Future<void> _loadIcons() async {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    try {
      final icons = await Future.wait([
        MarkerImages.circle(
          size: 14,
          pixelRatio: pixelRatio,
          color: DriverColors.accent,
          borderColor: Colors.black,
          borderWidth: 2,
          glow: DriverColors.accent.withValues(alpha: 0.7),
          glowBlur: 10,
          halo: DriverColors.accent.withValues(alpha: 0.25),
          haloSize: 30,
        ),
        MarkerImages.circle(
          size: 40,
          pixelRatio: pixelRatio,
          color: const Color(0xFF1A1C1B),
          borderColor: Colors.white.withValues(alpha: 0.35),
          borderWidth: 1.5,
          icon: Icons.flag_rounded,
          iconSize: 20,
          glow: Colors.black.withValues(alpha: 0.5),
          glowBlur: 8,
        ),
      ]);
      if (!mounted) return;
      _pickupIcon = icons[0];
      _dropoffIcon = icons[1];
      _decorate();
    } catch (e) {
      debugPrint('Marker images failed: $e');
    }
  }

  Future<void> _loadRoute() async {
    final jobId = widget.job.id;
    final route = await RouteService.instance.fetch(_pickup, _dropoff);
    if (!mounted || widget.job.id != jobId || route == null) return;
    _route = route;
    _decorate();
  }

  void _onViewCreated(GoogleMapViewController controller) {
    _controller = controller;
    controller.setMyLocationEnabled(true).catchError((Object e) {
      debugPrint('My-location layer unavailable: $e');
    });
    _decorate();
  }

  /// Redraws markers and the route line and sets the camera for the mode.
  Future<void> _decorate() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final guiding = widget.guiding;
    final topInset = MediaQuery.paddingOf(context).top;

    try {
      await controller.clearMarkers();
      await controller.clearPolylines();

      final markers = [
        if (_pickupIcon != null)
          MarkerOptions(
            position: _pickup,
            icon: _pickupIcon!,
            anchor: const MarkerAnchor(u: 0.5, v: 0.5),
          ),
        if (_dropoffIcon != null)
          MarkerOptions(
            position: _dropoff,
            icon: _dropoffIcon!,
            anchor: const MarkerAnchor(u: 0.5, v: 0.5),
          ),
      ];
      if (markers.isNotEmpty) await controller.addMarkers(markers);

      if (controller is GoogleNavigationViewController) {
        // Google's own trip footer would sit under our guidance panel, which
        // shows the same time and distance
        await controller.setNavigationFooterEnabled(!guiding);
        await controller.setSpeedLimitIconEnabled(true);
        await controller.setSpeedometerEnabled(true);
      }

      if (guiding) {
        // Guidance draws its own route and keeps the camera on the car
        await controller.setPadding(const EdgeInsets.only(bottom: _guidanceAllowance));
        if (controller is GoogleNavigationViewController) {
          await controller.followMyLocation(CameraPerspective.tilted);
        }
        return;
      }

      final route = _route;
      await controller.addPolylines(
        route == null
            // No road route yet (or routing unavailable): a straight line
            ? [
                PolylineOptions(
                  points: [_pickup, _dropoff],
                  strokeColor: DriverColors.accent.withValues(alpha: 0.8),
                  strokeWidth: 3,
                ),
              ]
            : [
                PolylineOptions(
                  points: route.points,
                  strokeColor: DriverColors.accent.withValues(alpha: 0.22),
                  strokeWidth: 14,
                ),
                PolylineOptions(
                  points: route.points,
                  strokeColor: DriverColors.accent,
                  strokeWidth: 4,
                  zIndex: 1,
                ),
              ],
      );
      await controller.setPadding(EdgeInsets.only(top: topInset + 60, bottom: _sheetAllowance));
      await _fitRoute();
    } catch (e) {
      // e.g. the view was disposed mid-update when switching map views
      debugPrint('Map update failed: $e');
    }
  }

  Future<void> _fitRoute() async {
    final controller = _controller;
    if (controller == null) return;
    final points = [_pickup, _dropoff, ...?_route?.points];
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    await controller.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(latitude: south, longitude: west),
          northeast: LatLng(latitude: north, longitude: east),
        ),
        padding: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = CameraPosition(target: _pickup, zoom: 11);

    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: NavigationService.instance.sessionReady,
            builder: (context, ready, _) => ready
                ? GoogleMapsNavigationView(
                    key: const ValueKey('navigation-view'),
                    onViewCreated: _onViewCreated,
                    initialCameraPosition: initialCamera,
                    initialMapColorScheme: MapColorScheme.dark,
                    initialForceNightMode: NavigationForceNightMode.auto,
                    initialNavigationUIEnabledPreference: NavigationUIEnabledPreference.automatic,
                  )
                : GoogleMapsMapView(
                    key: const ValueKey('map-view'),
                    onViewCreated: _onViewCreated,
                    initialCameraPosition: initialCamera,
                    initialMapColorScheme: MapColorScheme.dark,
                  ),
          ),
        ),

        // Show the whole route, top right under the status bar
        if (!widget.guiding)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 16,
            child: GlassIconButton(
              icon: Icons.zoom_out_map_rounded,
              semanticLabel: 'Show whole route',
              onTap: _fitRoute,
            ),
          ),
      ],
    );
  }
}

// ── Guidance panel ─────────────────────────────────────────────────────────

/// Compact bottom panel while turn-by-turn guidance runs: time and distance
/// left, the job's next step, and a way to end guidance.
class _GuidancePanel extends StatelessWidget {
  final Widget action;
  final VoidCallback onBack;

  const _GuidancePanel({required this.action, required this.onBack});

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes.clamp(1, 59)} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  String _formatDistance(double meters) =>
      meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';

  @override
  Widget build(BuildContext context) {
    final nav = NavigationService.instance;
    const radius = BorderRadius.vertical(top: Radius.circular(28));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xE60D0E0E),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      semanticLabel: 'Back to dashboard; navigation keeps running',
                      onTap: onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<NavProgress?>(
                        valueListenable: nav.progress,
                        builder: (context, p, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p == null ? 'Navigating…' : _formatDuration(p.remainingS),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              p == null
                                  ? (nav.leg == NavLeg.toPickup ? 'To the pickup point' : 'To the delivery address')
                                  : '${_formatDistance(p.remainingM)} · ${nav.leg == NavLeg.toPickup ? 'to pickup' : 'to delivery'}',
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: nav.stop,
                      style: TextButton.styleFrom(foregroundColor: DriverColors.error),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('End', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (kDebugMode)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      // Testing on emulators/simulators: drive the route with fake GPS
                      onPressed: nav.simulateDrive,
                      child: const Text('Simulate drive (debug)', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                const SizedBox(height: 10),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────

class _JobSheet extends StatelessWidget {
  final JobModel job;
  final Widget action;
  /// "Navigate to …" button for the current leg, when there is one.
  final Widget? navAction;

  const _JobSheet({required this.job, required this.action, this.navAction});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(32));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xE60D0E0E),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Journey progress
                Row(
                  children: [
                    JobStatusChip(job: job),
                    const Spacer(),
                    Text(
                      'Step ${job.status.stage} of ${JobStage.stageCount}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentProgressBar(total: JobStage.stageCount, filled: job.status.stage),
                const SizedBox(height: 20),

                // Customer
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DriverColors.accent.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        job.customerName?.substring(0, 1).toUpperCase() ?? 'C',
                        style: const TextStyle(
                          color: DriverColors.accentLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.customerName ?? 'Client',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.customerPhone ?? 'No phone provided',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    GlassIconButton(
                      icon: Icons.phone_rounded,
                      iconColor: DriverColors.accent,
                      semanticLabel: 'Call client',
                      // Disabled when the booking has no phone number.
                      onTap: (job.customerPhone?.trim().isNotEmpty ?? false)
                          ? () => openLink(
                              context,
                              Uri(
                                scheme: 'tel',
                                path: job.customerPhone!.replaceAll(
                                  RegExp(r'[^\d+]'),
                                  '',
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle + route
                SurfaceCard(
                  radius: 22,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(job.vehicle.icon, color: DriverColors.accentLight, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              job.vehicle.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                            ),
                          ),
                          Text(
                            '#${shortRef(job.id)}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                          ),
                          const SizedBox(width: 8),
                          FlatChip(label: job.serviceLabel),
                        ],
                      ),
                      const SizedBox(height: 14),
                      JobRouteLines(job: job),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (navAction != null) ...[
                  navAction!,
                  const SizedBox(height: 10),
                ],

                // Status action
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
