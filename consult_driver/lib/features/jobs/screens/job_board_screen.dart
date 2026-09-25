import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/theme/driver_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../widgets/job_ui.dart';

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
    String withCount(String label, int n) => n > 0 ? '$label ($n)' : label;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          Column(
            children: [
              const GlassPageHeader(title: 'Mission Board'),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) => GlassSegmentedControl(
                    labels: [
                      withCount('Assigned', jobProv.assignedJobs.length),
                      withCount('Active', jobProv.activeJobs.length),
                      'Completed',
                    ],
                    selectedIndex: _tabController.index,
                    onChanged: _tabController.animateTo,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AssignedJobsList(),
                    _ActiveJobsList(),
                    _CompletedJobsList(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Leaves room for the floating nav bar under the last card.
EdgeInsets _listPadding(BuildContext context) =>
    EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.paddingOf(context).bottom + 24);

/// One tab of the board: pull to refresh, a spinner on first load, and an
/// empty state that still scrolls so pull-to-refresh works on it.
class _JobList extends StatelessWidget {
  final List<JobModel> Function(JobProvider) select;
  final _JobCardVariant variant;
  final _EmptyState empty;

  const _JobList({
    required this.select,
    required this.variant,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JobProvider>();
    final jobs = select(prov);
    final nothingLoaded = prov.assignedJobs.isEmpty &&
        prov.activeJobs.isEmpty &&
        prov.completedJobs.isEmpty;

    final Widget list;
    if (jobs.isEmpty) {
      list = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listPadding(context).copyWith(top: 40),
        children: [
          prov.isLoading && nothingLoaded
              ? const Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(DriverColors.accent),
                  ),
                )
              : empty,
        ],
      );
    } else {
      list = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listPadding(context),
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _JobCard(job: jobs[i], variant: variant)
            .entrance(
              context,
              delay: Duration(milliseconds: i * 60),
              slide: 0.05,
            ),
      );
    }

    return RefreshIndicator.adaptive(
      color: DriverColors.accent,
      onRefresh: prov.fetchJobs,
      child: list,
    );
  }
}

class _AssignedJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _JobList(
    select: (p) => p.assignedJobs,
    variant: _JobCardVariant.assigned,
    empty: const _EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Pending Assignments',
      subtitle: 'New vehicle transport jobs dispatched to you will show here.',
    ),
  );
}

class _ActiveJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _JobList(
    select: (p) => p.activeJobs,
    variant: _JobCardVariant.active,
    empty: const _EmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'No Active Missions',
      subtitle: 'Confirm an assigned job to begin transport route.',
    ),
  );
}

class _CompletedJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _JobList(
    select: (p) => p.completedJobs,
    variant: _JobCardVariant.completed,
    empty: const _EmptyState(
      icon: Icons.task_alt_outlined,
      title: 'No Completed Jobs',
      subtitle: 'Your successfully delivered jobs will appear here.',
    ),
  );
}

// ── Job card ──────────────────────────────────────────────────────────────────

enum _JobCardVariant { assigned, active, completed }

class _JobCard extends StatelessWidget {
  final JobModel job;
  final _JobCardVariant variant;

  const _JobCard({required this.job, required this.variant});

  @override
  Widget build(BuildContext context) {
    final isActive = variant == _JobCardVariant.active;
    final accent = job.status.color;

    // Active missions get a green hairline instead of a glow.
    return SurfaceCard(
      radius: 26,
      borderColor: isActive
          ? DriverColors.accent.withValues(alpha: 0.45)
          : null,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              IconTile(
                icon: job.vehicle.icon,
                size: 46,
                iconSize: 21,
                radius: 16,
                tint: accent,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${shortRef(job.id)}  •  ${job.vehicle.color}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
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
          const SizedBox(height: 16),

          // ── Service tags ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: job.serviceLabel, icon: Icons.speed_rounded),
              _Tag(label: job.transportModeLabel, icon: Icons.garage_rounded),
              if (job.hasInsurance)
                const _Tag(
                  label: 'Insured',
                  icon: Icons.shield_rounded,
                  color: DriverColors.accent,
                ),
            ],
          ),

          // ── Journey progress ──
          if (isActive) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Journey',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${job.status.stage} of ${JobStage.stageCount}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentProgressBar(
              total: JobStage.stageCount,
              filled: job.status.stage,
            ),
          ],

          const SizedBox(height: 18),
          _CardAction(job: job, variant: variant),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _Tag({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) =>
      FlatChip(label: label, icon: icon, color: color);
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
          builder: (context, prov, _) => DriverButton(
            label: 'Confirm Mission',
            isLoading: prov.isLoading,
            onPressed: prov.isLoading
                ? null
                : () async {
                    final hasLocation = await DriverLocationAccess.ensure(
                      context,
                      reason:
                          'Your client tracks this delivery using your location. Turn it on to accept the job.',
                    );
                    if (!hasLocation || !context.mounted) return;
                    final ok = await prov.confirmJob(job.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mission confirmed! Proceeding to active.',
                          ),
                          backgroundColor: Color(0xFF161616),
                        ),
                      );
                      context.push(AppRoutes.activeJob);
                    }
                  },
          ),
        );

      case _JobCardVariant.active:
        return GlassPillButton(
          icon: Icons.navigation_rounded,
          label: 'Mission Progress',
          onTap: () => context.push(AppRoutes.activeJob),
        );

      case _JobCardVariant.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: DriverColors.accent,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Delivered',
                  style: TextStyle(
                    color: DriverColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (job.completedAt != null)
              Text(
                _formatDate(job.completedAt!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
          ],
        );
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
    ).entrance(context, slide: 0);
  }
}
