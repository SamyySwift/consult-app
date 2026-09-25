import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/driver_colors.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/widgets/job_ui.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/driver_button.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JobProvider>();
    final activeJob = prov.activeJob;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          RefreshIndicator.adaptive(
            color: DriverColors.accent,
            onRefresh: prov.fetchJobs,
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: GlassPageHeader(title: 'Vehicle Logistics'),
              ),
              if (activeJob != null)
                SliverToBoxAdapter(child: _ActiveVehicleContent(job: activeJob))
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoVehicleState(),
                ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

// ── Active vehicle content ────────────────────────────────────────────────────

class _ActiveVehicleContent extends StatelessWidget {
  final JobModel job;
  const _ActiveVehicleContent({required this.job});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Leaves room for the floating nav bar at the bottom.
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Vehicle hero card ──
          SurfaceCard(
            radius: 30,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTile(
                      icon: job.vehicle.icon,
                      size: 58,
                      iconSize: 28,
                      radius: 20,
                      tint: DriverColors.accent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.vehicle.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${job.vehicle.color}  •  Job #${shortRef(job.id)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    JobStatusChip(job: job),
                    _Chip(label: job.serviceLabel),
                    _Chip(
                      label: job.transportMode == TransportMode.enclosed
                          ? 'Enclosed'
                          : 'Open',
                    ),
                  ],
                ),
              ],
            ),
          ).motionAware(context).fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 28),

          // ── Delivery route ──
          const _SectionTitle('Route Manifest'),
          SurfaceCard(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: DriverColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DriverColors.accent.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 46,
                      color: Colors.white.withValues(alpha: 0.12),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RouteLabel('ORIGIN / PICKUP'),
                      const SizedBox(height: 3),
                      Text(
                        job.pickup.address,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _RouteLabel('DESTINATION / DROPOFF'),
                      const SizedBox(height: 3),
                      Text(
                        job.dropoff.address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).motionAware(context, delay: 60.ms).fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 28),

          // ── Status timeline ──
          const _SectionTitle('Mission Progress'),
          _StatusTimeline(job: job).motionAware(context, delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          // ── Details grid ──
          const _SectionTitle('Vehicle & Client Details'),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  label: 'Customer',
                  value: job.customerName ?? '—',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  label: 'Phone',
                  value: job.customerPhone ?? '—',
                  icon: Icons.phone_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  label: 'Transport',
                  value: job.transportModeLabel,
                  icon: Icons.garage_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  label: 'Insurance Coverage',
                  value: job.hasInsurance ? 'Active Full Policy' : 'Standard',
                  icon: Icons.shield_rounded,
                  valueColor: job.hasInsurance
                      ? DriverColors.accent
                      : const Color(0xFF888888),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Next step ──
          // Status changes happen on the mission screen, which runs the
          // pickup inspection and the client's handover signature. Marking
          // them from here skipped both.
          if (_nextStepLabel(job.status) case final label?)
            DriverButton(
              label: label,
              icon: const Icon(
                Icons.navigation_rounded,
                size: 18,
                color: Colors.white,
              ),
              onPressed: () => context.push(AppRoutes.activeJob),
            ),
        ],
      ),
    );
  }

  String? _nextStepLabel(JobStatus current) => switch (current) {
    JobStatus.confirmed => 'Continue to Pickup Inspection',
    JobStatus.pickedUp => 'Continue to Start Transit',
    JobStatus.inTransit => 'Continue to Client Handover',
    _ => null,
  };
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RouteLabel extends StatelessWidget {
  final String text;
  const _RouteLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.55),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) => FlatChip(label: label);
}

// ── Status timeline ───────────────────────────────────────────────────────────

class _Step {
  final JobStatus status;
  final IconData icon;
  final String label;
  final String description;
  final DateTime? date;
  const _Step(this.status, this.icon, this.label, this.description, this.date);
}

/// Journey steps as large icon capsules: done steps are tinted and joined by
/// a dashed line, the current step is a tall glowing pill, upcoming are dim.
class _StatusTimeline extends StatelessWidget {
  final JobModel job;
  const _StatusTimeline({required this.job});

  static const _order = [
    JobStatus.assigned,
    JobStatus.confirmed,
    JobStatus.pickedUp,
    JobStatus.inTransit,
    JobStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(
        JobStatus.assigned,
        Icons.assignment_rounded,
        'Assigned',
        'Dispatched to you',
        job.assignedAt,
      ),
      _Step(
        JobStatus.confirmed,
        Icons.event_available_rounded,
        'Confirmed',
        'You accepted the mission',
        job.confirmedAt,
      ),
      _Step(
        JobStatus.pickedUp,
        Icons.key_rounded,
        'Picked Up',
        'Vehicle collected from the client',
        job.pickedUpAt,
      ),
      const _Step(
        JobStatus.inTransit,
        Icons.local_shipping_rounded,
        'In Transit',
        'On the road to drop-off',
        null,
      ),
      _Step(
        JobStatus.completed,
        Icons.verified_rounded,
        'Delivered',
        'Handed over to the recipient',
        job.completedAt,
      ),
    ];
    final current = _order.indexOf(job.status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            state: i < current
                ? _StepState.done
                : i == current
                ? _StepState.current
                : _StepState.upcoming,
            connector: i == steps.length - 1
                ? null
                : (i + 1 <= current ? _Connector.dashed : _Connector.solid),
            caption: steps[i].date != null
                ? _formatTime(steps[i].date!)
                : steps[i].description,
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
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
    return '${months[dt.month - 1]} ${dt.day}  •  $h:$m $ampm';
  }
}

enum _StepState { done, current, upcoming }

enum _Connector { dashed, solid }

class _TimelineRow extends StatelessWidget {
  static const _railWidth = 56.0;

  final _Step step;
  final _StepState state;
  final _Connector? connector;
  final String caption;

  const _TimelineRow({
    required this.step,
    required this.state,
    required this.connector,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _StepState.current;
    final isDone = state == _StepState.done;

    final capsule = Container(
      width: _railWidth,
      height: isCurrent ? 86 : _railWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_railWidth / 2),
        gradient: isCurrent ? DriverColors.accentGradient : null,
        color: isCurrent
            ? null
            : isDone
            ? DriverColors.accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05),
        border: isCurrent
            ? null
            : Border.all(
                color: isDone
                    ? DriverColors.accent.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.10),
              ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: DriverColors.accent.withValues(alpha: 0.45),
                  blurRadius: 22,
                ),
              ]
            : null,
      ),
      child: Icon(
        step.icon,
        size: 24,
        color: isCurrent
            ? Colors.black
            : isDone
            ? DriverColors.accentLight
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
                    child: CustomPaint(
                      painter: _RailPainter(
                        dashed: connector == _Connector.dashed,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isCurrent ? 16 : 7, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrent ? 'Happening now' : caption,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? DriverColors.accent
                          : Colors.white.withValues(alpha: isDone ? 0.5 : 0.3),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white.withValues(
                        alpha: state == _StepState.upcoming ? 0.45 : 1,
                      ),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.description,
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

class _RailPainter extends CustomPainter {
  final bool dashed;
  _RailPainter({required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = dashed
          ? DriverColors.accent.withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.12)
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
        Offset(x, (y + dash).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) => old.dashed != dashed;
}

// ── Detail card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _DetailCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, size: 36, iconSize: 18, radius: 12),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── No vehicle empty state ────────────────────────────────────────────────────

class _NoVehicleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: const GlassEmptyState(
          icon: Icons.directions_car_outlined,
          title: 'No Vehicle Manifest Active',
          subtitle:
              'You have no assigned vehicle logistics underway. Check your Mission Board for incoming dispatches.',
        ),
      ),
    ).motionAware(context).fadeIn();
  }
}
