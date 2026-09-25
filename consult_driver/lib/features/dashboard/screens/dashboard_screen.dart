import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/tap_target.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/widgets/job_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobProv = context.watch<JobProvider>();
    final driver = auth.driver;
    final activeJob = jobProv.activeJob;
    final pendingJob = jobProv.assignedJobs.isNotEmpty ? jobProv.assignedJobs.first : null;

    if (driver == null && auth.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: DriverColors.accent),
        ),
      );
    }

    final assigned = jobProv.assignedJobs.length;
    final inProgress = jobProv.activeJobs.length;
    final completed = jobProv.totalCompleted;
    final total = assigned + inProgress + completed;
    double share(int n) => total == 0 ? 0 : n / total;
    // One source of truth: the toggle, its tap handler and the empty state
    // previously disagreed about the default when the profile hadn't loaded.
    final isOnline = driver?.isOnline ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: _HeroBackdrop()),
          RefreshIndicator(
            color: DriverColors.accent,
            backgroundColor: const Color(0xFF161616),
            onRefresh: () async {
              await jobProv.fetchJobs();
            },
            child: CustomScrollView(
              // Pull-to-refresh must work even when the content is short.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DriverColors.accent.withValues(alpha: 0.12),
                            ),
                            child: Text(
                              driver?.initials ?? 'DR',
                              style: const TextStyle(
                                color: DriverColors.accentLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver?.firstName ?? 'Driver',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 15),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${driver?.rating ?? 5.0}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${driver?.totalJobs ?? 0} trips',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _OnlineToggle(
                            isOnline: isOnline,
                            onTap: () async {
                              final goingOnline = !isOnline;
                              if (goingOnline) {
                                final ok = await DriverLocationAccess.ensure(
                                  context,
                                  reason: 'Clients track their vehicle using your location. Turn it on to go online.',
                                );
                                if (!ok) return;
                              }
                              auth.toggleOnlineStatus();
                            },
                          ),
                        ],
                      ),
                    ),
                  ).motionAware(context).fadeIn().slideY(begin: -0.1, end: 0),
                ),

                // ── Job counts ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.go(AppRoutes.jobBoard),
                      child: BracketedStats(
                        label: 'Active Jobs',
                        value: '${assigned + inProgress}',
                        pills: [
                          StatPillData(
                            icon: Icons.assignment_rounded,
                            value: '$assigned',
                            label: 'Assigned',
                            progress: share(assigned),
                          ),
                          StatPillData(
                            icon: Icons.local_shipping_rounded,
                            value: '$inProgress',
                            label: 'In Progress',
                            progress: share(inProgress),
                          ),
                          StatPillData(
                            icon: Icons.check_circle_rounded,
                            value: '$completed',
                            label: 'Completed',
                            progress: share(completed),
                          ),
                        ],
                      ),
                    ),
                  ).motionAware(context, delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),
                ),

                // ── Current mission / new assignment ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (activeJob != null) ...[
                          _SectionHeader(
                            title: 'Current Mission',
                            actionLabel: 'Open Navigation',
                            onAction: () => context.push(AppRoutes.activeJob),
                          ),
                          const SizedBox(height: 14),
                          _ActiveJobCard(job: activeJob),
                        ] else if (pendingJob != null) ...[
                          const _SectionHeader(title: 'New Assigned Job'),
                          const SizedBox(height: 14),
                          _PendingJobCard(job: pendingJob),
                        ] else
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.jobBoard),
                            // Only claim "online" when the driver actually is.
                            child: isOnline
                                ? const GlassEmptyState(
                                    icon: Icons.local_shipping_outlined,
                                    title: 'Standing By for Dispatch',
                                    subtitle:
                                        'You are online. New delivery assignments will appear here automatically in real time.',
                                  )
                                : const GlassEmptyState(
                                    icon: Icons.power_settings_new_rounded,
                                    title: 'You\'re Offline',
                                    subtitle:
                                        'Go online with the switch above to start receiving delivery assignments.',
                                  ),
                          ).motionAware(context, delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0),
                      ],
                    ),
                  ),
                ),

                // ── Recent deliveries ───────────────────────────────────
                if (jobProv.completedJobs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            title: 'Recent Deliveries',
                            actionLabel: 'See All',
                            onAction: () => context.go(AppRoutes.jobBoard),
                          ),
                          const SizedBox(height: 14),
                          ...jobProv.completedJobs.take(3).map(
                                (j) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CompletedJobRow(job: j),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),

                // Clear the floating nav bar.
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero backdrop: graded car-carrier photo fading into black ─────────────
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.5,
          // Modulate (not multiply) so the green tint only touches the photo's
          // own pixels; multiply also paints transparent areas.
          child: Image.network(
            AppConstants.heroImageUrl,
            fit: BoxFit.cover,
            alignment: const Alignment(0.15, 0),
            color: const Color(0xFF6E9C86),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.5 + 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.25, 0.6, 0.92],
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: height * 0.36,
          left: -80,
          right: -80,
          height: height * 0.45,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  DriverColors.accent.withValues(alpha: 0.14),
                  DriverColors.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Online / offline switch ────────────────────────────────────────────────
class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTap;

  const _OnlineToggle({required this.isOnline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isOnline,
      // The pill is ~32pt tall; the hit region is padded out to 44pt.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: TapTarget.minSize,
            minHeight: TapTarget.minSize,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: GlassPill(
          blur: true,
          glow: isOnline,
          tint: isOnline ? DriverColors.accent : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? DriverColors.accent : const Color(0xFF777777),
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [BoxShadow(color: DriverColors.accent.withValues(alpha: 0.7), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isOnline ? DriverColors.accentLight : Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null)
          TapTarget(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: DriverColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Current mission: luminous glass card ──────────────────────────────────
class _ActiveJobCard extends StatelessWidget {
  final JobModel job;
  const _ActiveJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.activeJob),
      child: GlassContainer(
        radius: 30,
        blur: true,
        glow: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  icon: job.vehicle.icon,
                  size: 50,
                  iconSize: 24,
                  radius: 17,
                  tint: DriverColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.vehicle.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${shortRef(job.id)}  •  ${job.vehicle.color}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                JobStatusChip(job: job),
              ],
            ),
            const SizedBox(height: 18),
            JobRouteLines(job: job),
            const SizedBox(height: 20),
            GlassPillButton(
              icon: Icons.navigation_rounded,
              label: 'Manage Mission',
              onTap: () => context.push(AppRoutes.activeJob),
            ),
          ],
        ),
      ),
    ).motionAware(context, delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}

// ── New assignment awaiting confirmation ──────────────────────────────────
class _PendingJobCard extends StatelessWidget {
  final JobModel job;
  const _PendingJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();

    return GestureDetector(
      onTap: () => context.go(AppRoutes.jobBoard),
      child: GlassContainer(
        radius: 30,
        blur: true,
        glow: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconTile(
                  icon: Icons.assignment_rounded,
                  size: 50,
                  iconSize: 22,
                  radius: 17,
                  tint: DriverColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned to You',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                      Text(
                        'Awaiting your confirmation',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              job.vehicle.displayName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            JobRouteLines(job: job),
            const SizedBox(height: 22),
            DriverButton(
              label: 'Confirm Assignment',
              isLoading: jobProv.isLoading,
              onPressed: jobProv.isLoading
                  ? null
                  : () async {
                      final ok = await DriverLocationAccess.ensure(
                        context,
                        reason: 'Your client tracks this delivery using your location. Turn it on to accept the job.',
                      );
                      if (!ok || !context.mounted) return;
                      await jobProv.confirmJob(job.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job confirmed! Proceed to pickup.'),
                            backgroundColor: Color(0xFF161616),
                          ),
                        );
                        context.push(AppRoutes.activeJob);
                      }
                    },
            ),
          ],
        ),
      ),
    ).motionAware(context, delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}

// ── Recent delivery row ───────────────────────────────────────────────────
class _CompletedJobRow extends StatelessWidget {
  final JobModel job;
  const _CompletedJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.go(AppRoutes.jobBoard),
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
          children: [
            const IconTile(
              icon: Icons.task_alt_rounded,
              size: 42,
              iconSize: 19,
              tint: DriverColors.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.vehicle.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${shortRef(job.id)}  •  ${job.dropoff.address.split(',').first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Delivered',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DriverColors.accent),
            ),
          ],
        ),
    );
  }
}
