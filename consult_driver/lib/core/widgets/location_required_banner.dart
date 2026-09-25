import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/jobs/providers/job_provider.dart';
import '../services/driver_location_access.dart';
import '../theme/driver_colors.dart';
import 'glass.dart';

/// Shown while the driver has a job but isn't sharing location, since the
/// client can't track the delivery until it's back on.
class LocationRequiredBanner extends StatelessWidget {
  const LocationRequiredBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JobProvider>();
    if (!prov.locationBlocked) return const SizedBox.shrink();

    return ColoredBox(
      color: DriverColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: GlassContainer(
            radius: 22,
            tint: DriverColors.error,
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DriverColors.error.withValues(alpha: 0.18),
                  ),
                  child: const Icon(Icons.location_off_rounded, color: DriverColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location is off',
                        style: TextStyle(color: DriverColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        "Your client can't track this delivery until you turn it on.",
                        style: TextStyle(color: DriverColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final ok = await DriverLocationAccess.ensure(
                      context,
                      reason: 'Your client tracks this delivery using your location.',
                    );
                    if (ok) await prov.recheckLocation();
                  },
                  child: const Text(
                    'Turn on',
                    style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
