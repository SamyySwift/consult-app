import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/network/route_service.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/location_required_banner.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/surface.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';
import '../widgets/job_ui.dart';
import 'delivery_acknowledgement_sheet.dart';
import 'pickup_condition_form.dart';

class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dashboard);
    }
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
                  onBack: () => _goBack(context),
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _JobMap(job: job)),

          // Location warning + back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocationRequiredBanner(),
                Padding(
                  // The banner already clears the status bar when it's shown
                  padding: EdgeInsets.only(
                    left: 16,
                    top: prov.locationBlocked ? 10 : MediaQuery.of(context).padding.top + 10,
                  ),
                  child: GlassIconButton(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Back',
                    onTap: () => _goBack(context),
                  ),
                ),
              ],
            ),
          ),

          // Job status sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _JobSheet(
              job: job,
              action: _buildStatusAction(context, prov, job),
            ),
          ),
        ],
      ),
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
            if (ok) await prov.updateJobStatus(job.id, JobStatus.inTransit);
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

/// Full-screen map with the road route, pickup and drop-off markers, and the
/// driver's own live position.
class _JobMap extends StatefulWidget {
  final JobModel job;
  const _JobMap({required this.job});

  @override
  State<_JobMap> createState() => _JobMapState();
}

class _JobMapState extends State<_JobMap> {
  // Roughly the height of the bottom sheet, so fitted routes stay visible.
  static const _sheetAllowance = 400.0;

  final MapController _mapController = MapController();
  bool _mapReady = false;
  RoadRoute? _route;

  LatLng get _pickup => LatLng(widget.job.pickup.lat, widget.job.pickup.lng);
  LatLng get _dropoff => LatLng(widget.job.dropoff.lat, widget.job.dropoff.lng);

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant _JobMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job.id != widget.job.id) {
      setState(() => _route = null);
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    final jobId = widget.job.id;
    final route = await RouteService.instance.fetch(_pickup, _dropoff);
    if (!mounted || widget.job.id != jobId || route == null) return;
    setState(() => _route = route);
    _fitRoute();
  }

  void _fitRoute() {
    if (!_mapReady) return;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [_pickup, _dropoff, ...?_route?.points],
        padding: EdgeInsets.fromLTRB(40, MediaQuery.paddingOf(context).top + 90, 40, _sheetAllowance),
        maxZoom: 15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMapbox = AppConstants.mapboxToken != null;
    final driverPosition = context.read<JobProvider>().driverPosition;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(
                coordinates: [_pickup, _dropoff],
                padding: EdgeInsets.fromLTRB(40, 120, 40, _sheetAllowance),
                maxZoom: 15,
              ),
              backgroundColor: const Color(0xFF0E0F0F),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _mapReady = true;
                if (_route != null) _fitRoute();
              },
            ),
            children: [
              _tileLayer(),
              PolylineLayer(polylines: _polylines()),
              MarkerLayer(markers: _endpointMarkers()),
              ValueListenableBuilder<Position?>(
                valueListenable: driverPosition,
                builder: (context, position, _) => MarkerLayer(
                  markers: [
                    if (position != null)
                      Marker(
                        point: LatLng(position.latitude, position.longitude),
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: DriverColors.accentGradient,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: [
                              BoxShadow(color: DriverColors.accent.withValues(alpha: 0.6), blurRadius: 18),
                            ],
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Colors.black, size: 22),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Show the whole route + map credit, top right under the status bar.
        Positioned(
          top: MediaQuery.paddingOf(context).top + 10,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassIconButton(
                icon: Icons.zoom_out_map_rounded,
                semanticLabel: 'Show whole route',
                onTap: _fitRoute,
              ),
              const SizedBox(height: 8),
              Text(
                hasMapbox ? '© Mapbox © OpenStreetMap' : '© OpenStreetMap',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                  shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tileLayer() {
    final token = AppConstants.mapboxToken;
    if (token == null) {
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.carpitalconsult.driver',
      );
    }
    return TileLayer(
      urlTemplate:
          'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/512/{z}/{x}/{y}@2x?access_token={accessToken}',
      additionalOptions: {'accessToken': token},
      tileSize: 512,
      zoomOffset: -1,
      userAgentPackageName: 'com.carpitalconsult.driver',
    );
  }

  List<Polyline> _polylines() {
    final route = _route;
    if (route == null) {
      // No road route yet (or routing unavailable): a straight dashed line.
      return [
        Polyline(
          points: [_pickup, _dropoff],
          color: DriverColors.accent.withValues(alpha: 0.8),
          strokeWidth: 3,
          pattern: StrokePattern.dashed(segments: const [10, 8]),
        ),
      ];
    }
    return [
      Polyline(points: route.points, color: DriverColors.accent.withValues(alpha: 0.22), strokeWidth: 14),
      Polyline(points: route.points, color: DriverColors.accent, strokeWidth: 4),
    ];
  }

  List<Marker> _endpointMarkers() {
    return [
      Marker(
        point: _pickup,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DriverColors.accent.withValues(alpha: 0.25),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DriverColors.accent,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [BoxShadow(color: DriverColors.accent.withValues(alpha: 0.7), blurRadius: 10)],
            ),
          ),
        ),
      ),
      Marker(
        point: _dropoff,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1C1B),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8)],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
        ),
      ),
    ];
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────

class _JobSheet extends StatelessWidget {
  final JobModel job;
  final Widget action;

  const _JobSheet({required this.job, required this.action});

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
