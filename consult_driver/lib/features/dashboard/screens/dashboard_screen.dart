import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_model.dart';

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          color: DriverColors.accent,
          backgroundColor: const Color(0xFF161616),
          onRefresh: () async {
            await jobProv.fetchJobs();
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Header Bar ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF161616),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF262626)),
                              ),
                              child: Center(
                                child: Text(
                                  driver?.initials ?? 'DR',
                                  style: const TextStyle(
                                    color: DriverColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver?.firstName ?? 'Driver',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
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
                                      style: const TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Online / Status Switch
                        InkWell(
                          onTap: () async {
                            final goingOnline = !(driver?.isOnline ?? false);
                            if (goingOnline) {
                              final ok = await DriverLocationAccess.ensure(
                                context,
                                reason: 'Clients track their vehicle using your location. Turn it on to go online.',
                              );
                              if (!ok) return;
                            }
                            auth.toggleOnlineStatus();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (driver?.isOnline ?? true)
                                  ? DriverColors.accent.withValues(alpha: 0.15)
                                  : const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (driver?.isOnline ?? true)
                                    ? DriverColors.accent.withValues(alpha: 0.5)
                                    : const Color(0xFF333333),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: (driver?.isOnline ?? true)
                                        ? DriverColors.accent
                                        : const Color(0xFF666666),
                                    shape: BoxShape.circle,
                                    boxShadow: (driver?.isOnline ?? true)
                                        ? [
                                            BoxShadow(
                                              color: DriverColors.accent.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (driver?.isOnline ?? true) ? 'ONLINE' : 'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: (driver?.isOnline ?? true)
                                        ? DriverColors.accent
                                        : const Color(0xFF888888),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 24),

                    // ── Stat Cards ──────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _TeslaStatCard(
                            title: 'Active Jobs',
                            value: '${jobProv.assignedJobs.length + jobProv.activeJobs.length}',
                            icon: Icons.local_shipping_outlined,
                            accentColor: DriverColors.accent,
                            onTap: () => context.go(AppRoutes.jobBoard),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TeslaStatCard(
                            title: 'Completed',
                            value: '${jobProv.totalCompleted}',
                            icon: Icons.check_circle_outline_rounded,
                            accentColor: const Color(0xFF2979FF),
                            onTap: () => context.go(AppRoutes.jobBoard),
                          ),
                        ),
                      ],
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 28),

                    // ── Main section (Current Delivery / New Assignment) ────
                    if (activeJob != null) ...[
                      _TeslaSectionHeader(
                        title: 'Current Mission',
                        actionLabel: 'Open Navigation',
                        onAction: () => context.go(AppRoutes.activeJob),
                      ),
                      const SizedBox(height: 12),
                      _TeslaActiveJobCard(job: activeJob),
                    ] else if (pendingJob != null) ...[
                      const _TeslaSectionHeader(title: 'New Assigned Job'),
                      const SizedBox(height: 12),
                      _TeslaPendingJobCard(job: pendingJob),
                    ] else ...[
                      _TeslaAwaitingCard(),
                    ],

                    const SizedBox(height: 28),

                    // ── Recent Deliveries ───────────────────────────────────
                    if (jobProv.completedJobs.isNotEmpty) ...[
                      _TeslaSectionHeader(
                        title: 'Recent Deliveries',
                        actionLabel: 'See All',
                        onAction: () => context.go(AppRoutes.jobBoard),
                      ),
                      const SizedBox(height: 12),
                      ...jobProv.completedJobs.take(3).map(
                        (j) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TeslaCompletedJobRow(job: j),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tesla Stat Card ─────────────────────────────────────────────────────────

class _TeslaStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const _TeslaStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
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

// ── Tesla Section Header ────────────────────────────────────────────────────

class _TeslaSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TeslaSectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: DriverColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Tesla Active Job Card ───────────────────────────────────────────────────

class _TeslaActiveJobCard extends StatelessWidget {
  final JobModel job;
  const _TeslaActiveJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DriverColors.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: DriverColors.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.activeJob),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top vehicle info & status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(job.vehicle.icon, color: DriverColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.vehicle.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${job.id}  •  ${job.vehicle.color}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: DriverColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DriverColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        job.statusLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: Color(0xFF222222), height: 1),
                const SizedBox(height: 18),

                // Pickup & Dropoff
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 10, color: DriverColors.accent),
                        Container(
                          width: 2,
                          height: 26,
                          color: const Color(0xFF262626),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                        ),
                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.white),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.pickup.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            job.dropoff.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: DriverColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Manage Mission',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}

// ── Tesla Pending Job Card ──────────────────────────────────────────────────

class _TeslaPendingJobCard extends StatelessWidget {
  final JobModel job;
  const _TeslaPendingJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.jobBoard),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFFFFB300), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned to You',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Awaiting your confirmation',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF222222), height: 1),
          const SizedBox(height: 16),

          Text(
            job.vehicle.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Route: ${job.pickup.address.split(',').first} → ${job.dropoff.address.split(',').first}',
            style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 13),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
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
                      context.go(AppRoutes.activeJob);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            child: jobProv.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                : const Text('Confirm Assignment'),
          ),
        ],
      ),
    ),
    ),
    ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}

// ── Tesla Awaiting Card ─────────────────────────────────────────────────────

class _TeslaAwaitingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.jobBoard),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(
              children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 36,
              color: DriverColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Standing By for Dispatch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are online. New delivery assignments will appear here automatically in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF888888),
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
    ),
    ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}

// ── Tesla Completed Job Row ─────────────────────────────────────────────────

class _TeslaCompletedJobRow extends StatelessWidget {
  final JobModel job;
  const _TeslaCompletedJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.jobBoard),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DriverColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt_rounded, color: DriverColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.vehicle.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${job.id}  •  ${job.dropoff.address.split(',').first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Delivered',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DriverColors.accent,
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
