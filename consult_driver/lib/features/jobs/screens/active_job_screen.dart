import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/location_required_banner.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';
import 'delivery_acknowledgement_sheet.dart';
import 'pickup_condition_form.dart';

class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JobProvider>();
    final job = prov.activeJob;

    if (job == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Active Mission',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(
          child: Text(
            'No active mission selected.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final pickup = LatLng(job.pickup.lat, job.pickup.lng);
    final dropoff = LatLng(job.dropoff.lat, job.dropoff.lng);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map Background with dark tone overlay
          FlutterMap(
            options: MapOptions(
              initialCenter: pickup,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carpitalconsult.driver',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickup, dropoff],
                    color: DriverColors.accent,
                    strokeWidth: 4,
                    pattern: StrokePattern.dashed(segments: const [10, 10]),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickup,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: DriverColors.accent, size: 40),
                  ),
                  Marker(
                    point: dropoff,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ],
          ),

          // Location warning + back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Consumer<JobProvider>(
              builder: (context, prov, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocationRequiredBanner(),
                  Padding(
                    // The banner already clears the status bar when it's shown
                    padding: EdgeInsets.only(
                      left: 16,
                      top: prov.locationBlocked ? 10 : MediaQuery.of(context).padding.top + 10,
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF141414),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.dashboard);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Job Status Sheet (Tesla Carbon UI)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: const Color(0xFF222222)),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, -10)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Customer info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF202020),
                          radius: 24,
                          child: Text(
                            job.customerName?.substring(0, 1).toUpperCase() ?? 'C',
                            style: const TextStyle(
                              color: DriverColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.customerName ?? 'Client',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job.customerPhone ?? 'No phone provided',
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.phone_rounded, color: Colors.black, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: DriverColors.accent,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFF1E1E1E), height: 1),
                    const SizedBox(height: 18),

                    // Vehicle details
                    Row(
                      children: [
                        Icon(job.vehicle.icon, color: DriverColors.accent, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          job.vehicle.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            job.serviceLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Status Actions
                    _buildStatusAction(context, prov, job),
                  ],
                ),
              ),
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
