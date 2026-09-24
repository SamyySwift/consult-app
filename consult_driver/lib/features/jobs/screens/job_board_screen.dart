import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_model.dart';

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});

  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mission Board',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: DriverColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: const Color(0xFF888888),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Assigned'),
                      if (jobProv.assignedJobs.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        _TabBadge(count: jobProv.assignedJobs.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Active'),
                      if (jobProv.activeJobs.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        _TabBadge(count: jobProv.activeJobs.length, isDark: true),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssignedJobsList(),
          _ActiveJobsList(),
          _CompletedJobsList(),
        ],
      ),
    );
  }
}

// ── Tab badge ─────────────────────────────────────────────────────────────────

class _TabBadge extends StatelessWidget {
  final int count;
  final bool isDark;
  const _TabBadge({required this.count, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isDark ? DriverColors.accent : Colors.white,
        ),
      ),
    );
  }
}

// ── Assigned jobs list ────────────────────────────────────────────────────────

class _AssignedJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().assignedJobs;

    if (jobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No Pending Assignments',
        subtitle: 'New vehicle transport jobs dispatched to you will show here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) =>
          _JobCard(job: jobs[i], variant: _JobCardVariant.assigned)
              .animate(delay: (i * 60).ms)
              .fadeIn()
              .slideY(begin: 0.05),
    );
  }
}

// ── Active jobs list ──────────────────────────────────────────────────────────

class _ActiveJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().activeJobs;

    if (jobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No Active Missions',
        subtitle: 'Confirm an assigned job to begin transport route.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) =>
          _JobCard(job: jobs[i], variant: _JobCardVariant.active)
              .animate(delay: (i * 60).ms)
              .fadeIn()
              .slideY(begin: 0.05),
    );
  }
}

// ── Completed jobs list ───────────────────────────────────────────────────────

class _CompletedJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>().completedJobs;

    if (jobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.task_alt_outlined,
        title: 'No Completed Jobs',
        subtitle: 'Your successfully delivered jobs will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) =>
          _JobCard(job: jobs[i], variant: _JobCardVariant.completed)
              .animate(delay: (i * 60).ms)
              .fadeIn()
              .slideY(begin: 0.05),
    );
  }
}

// ── Job card ──────────────────────────────────────────────────────────────────

enum _JobCardVariant { assigned, active, completed }

class _JobCard extends StatelessWidget {
  final JobModel job;
  final _JobCardVariant variant;

  const _JobCard({required this.job, required this.variant});

  @override
  Widget build(BuildContext context) {
    final isAssigned = variant == _JobCardVariant.assigned;
    final isActive = variant == _JobCardVariant.active;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? DriverColors.accent.withValues(alpha: 0.4)
              : isAssigned
                  ? const Color(0xFFFFB300).withValues(alpha: 0.3)
                  : const Color(0xFF222222),
          width: isActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // ── Card header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    job.vehicle.icon,
                    color: isActive ? DriverColors.accent : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.vehicle.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${job.id}  •  ${job.vehicle.color}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAssigned
                        ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                        : DriverColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAssigned ? const Color(0xFFFFB300) : DriverColors.accent,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF1E1E1E)),

          // ── Route ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 9, color: DriverColors.accent),
                    Container(
                      width: 1.5,
                      height: 20,
                      color: const Color(0xFF262626),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                    const Icon(Icons.location_on_rounded, size: 11, color: Colors.white),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.pickup.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        job.dropoff.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Service tags ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                _Tag(label: job.serviceLabel, icon: Icons.speed_rounded),
                const SizedBox(width: 8),
                _Tag(label: job.transportModeLabel, icon: Icons.garage_rounded),
                if (job.hasInsurance) ...[
                  const SizedBox(width: 8),
                  const _Tag(
                    label: 'Insured',
                    icon: Icons.shield_rounded,
                    color: DriverColors.accent,
                  ),
                ],
              ],
            ),
          ),

          // ── Action footer ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: _CardAction(job: job, variant: variant),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Tag({
    required this.label,
    required this.icon,
    this.color = const Color(0xFF888888),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final JobModel job;
  final _JobCardVariant variant;
  const _CardAction({required this.job, required this.variant});

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case _JobCardVariant.assigned:
        return Consumer<JobProvider>(
          builder: (context, prov, _) => Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: prov.isLoading
                      ? null
                      : () async {
                          final hasLocation = await DriverLocationAccess.ensure(
                            context,
                            reason: 'Your client tracks this delivery using your location. Turn it on to accept the job.',
                          );
                          if (!hasLocation || !context.mounted) return;
                          final ok = await prov.confirmJob(job.id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mission confirmed! Proceeding to active.'),
                                backgroundColor: Color(0xFF161616),
                              ),
                            );
                            context.go(AppRoutes.activeJob);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverColors.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  child: prov.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Confirm Mission'),
                ),
              ),
            ],
          ),
        );

      case _JobCardVariant.active:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.activeJob),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                child: const Text('Mission Progress'),
              ),
            ),
          ],
        );

      case _JobCardVariant.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: DriverColors.accent, size: 16),
                SizedBox(width: 6),
                Text(
                  'Delivered',
                  style: TextStyle(color: DriverColors.accent, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            if (job.completedAt != null)
              Text(
                _formatDate(job.completedAt!),
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
          ],
        );
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: DriverColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF888888), height: 1.4, fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
