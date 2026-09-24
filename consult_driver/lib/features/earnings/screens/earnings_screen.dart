import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/driver_location_access.dart';
import '../../../core/theme/driver_colors.dart';
import '../../jobs/providers/job_provider.dart';
import '../../jobs/models/job_model.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<JobProvider>();
    final activeJob = prov.activeJob;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  Icon(Icons.directions_car_filled_rounded, color: DriverColors.accent, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Vehicle Logistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          if (activeJob != null)
            SliverToBoxAdapter(child: _ActiveVehicleContent(job: activeJob))
          else
            SliverFillRemaining(child: _NoVehicleState()),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Vehicle hero card ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DriverColors.accent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: DriverColors.accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(job.vehicle.icon, color: DriverColors.accent, size: 28),
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
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${job.vehicle.color}  •  Job #${job.id}',
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Status + service type row
                Row(
                  children: [
                    _DarkChip(label: job.statusLabel.toUpperCase(), isAccent: true),
                    const SizedBox(width: 8),
                    _DarkChip(label: job.serviceLabel),
                    const SizedBox(width: 8),
                    _DarkChip(
                      label: job.transportMode == TransportMode.enclosed ? 'Enclosed' : 'Open',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 24),

          // ── Delivery route ──
          const Text(
            'Route Manifest',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, color: DriverColors.accent, size: 10),
                    Container(
                      width: 1.5,
                      height: 36,
                      color: const Color(0xFF2E2E2E),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ORIGIN / PICKUP', style: TextStyle(fontSize: 10, color: Color(0xFF777777), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text(
                        job.pickup.address,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFCCCCCC)),
                      ),
                      const SizedBox(height: 22),
                      const Text('DESTINATION / DROPOFF', style: TextStyle(fontSize: 10, color: Color(0xFF777777), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text(
                        job.dropoff.address,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 24),

          // ── Status timeline ──
          const Text(
            'Mission Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _StatusTimeline(job: job).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── Details grid ──
          const Text(
            'Vehicle & Client Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _DetailCard(label: 'Customer', value: job.customerName ?? '—', icon: Icons.person_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _DetailCard(label: 'Phone', value: job.customerPhone ?? '—', icon: Icons.phone_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _DetailCard(label: 'Transport', value: job.transportModeLabel, icon: Icons.garage_rounded)),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  label: 'Insurance Coverage',
                  value: job.hasInsurance ? 'Active Full Policy' : 'Standard',
                  icon: Icons.shield_rounded,
                  valueColor: job.hasInsurance ? DriverColors.accent : const Color(0xFF888888),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Update status button ──
          Consumer<JobProvider>(
            builder: (context, prov, _) {
              final next = _nextStatus(job.status);
              if (next == null) return const SizedBox.shrink();
              return ElevatedButton.icon(
                onPressed: prov.isLoading
                    ? null
                    : () async {
                        if (next != JobStatus.completed && next != JobStatus.cancelled) {
                          final ok = await DriverLocationAccess.ensure(
                            context,
                            reason: 'Your client tracks this delivery using your location. Turn it on to continue.',
                          );
                          if (!ok) return;
                        }
                        await prov.updateJobStatus(job.id, next);
                      },
                icon: Icon(_nextStatusIcon(next), size: 18),
                label: Text('Mark as ${_nextStatusLabel(next)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  JobStatus? _nextStatus(JobStatus current) {
    switch (current) {
      case JobStatus.confirmed: return JobStatus.pickedUp;
      case JobStatus.pickedUp:  return JobStatus.inTransit;
      case JobStatus.inTransit: return JobStatus.completed;
      default: return null;
    }
  }

  String _nextStatusLabel(JobStatus s) {
    switch (s) {
      case JobStatus.pickedUp:  return 'Picked Up';
      case JobStatus.inTransit: return 'In Transit';
      case JobStatus.completed: return 'Delivered';
      default: return '';
    }
  }

  IconData _nextStatusIcon(JobStatus s) {
    switch (s) {
      case JobStatus.pickedUp:  return Icons.local_shipping_rounded;
      case JobStatus.inTransit: return Icons.moving_rounded;
      case JobStatus.completed: return Icons.task_alt_rounded;
      default: return Icons.arrow_forward_rounded;
    }
  }
}

// ── Dark chip ─────────────────────────────────────────────────────────

class _DarkChip extends StatelessWidget {
  final String label;
  final bool isAccent;
  const _DarkChip({required this.label, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent ? DriverColors.accent.withValues(alpha: 0.15) : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAccent ? DriverColors.accent.withValues(alpha: 0.3) : const Color(0xFF282828),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAccent ? DriverColors.accent : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Status timeline ───────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final JobModel job;
  const _StatusTimeline({required this.job});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(label: 'Assigned', date: job.assignedAt, status: JobStatus.assigned),
      _Step(label: 'Confirmed', date: job.confirmedAt, status: JobStatus.confirmed),
      _Step(label: 'Picked Up', date: job.pickedUpAt, status: JobStatus.pickedUp),
      _Step(label: 'In Transit', date: null, status: JobStatus.inTransit),
      _Step(label: 'Delivered', date: job.completedAt, status: JobStatus.completed),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isDone = _isDone(job.status, step.status);
          final isCurrent = job.status == step.status;
          final isLast = i == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDone || isCurrent
                          ? DriverColors.accent
                          : const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone || isCurrent
                            ? DriverColors.accent
                            : const Color(0xFF333333),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.black, size: 13)
                        : isCurrent
                            ? const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 14)
                            : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 28,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isDone ? DriverColors.accent.withValues(alpha: 0.4) : const Color(0xFF262626),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDone || isCurrent ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                      if (step.date != null)
                        Text(
                          _formatTime(step.date!),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  bool _isDone(JobStatus current, JobStatus step) {
    const order = [
      JobStatus.assigned,
      JobStatus.confirmed,
      JobStatus.pickedUp,
      JobStatus.inTransit,
      JobStatus.completed,
    ];
    final ci = order.indexOf(current);
    final si = order.indexOf(step);
    return ci > si;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}  •  $h:$m $ampm';
  }
}

class _Step {
  final String label;
  final DateTime? date;
  final JobStatus status;
  const _Step({required this.label, required this.date, required this.status});
}

// ── Detail card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _DetailCard({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DriverColors.accent),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? Colors.white),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_outlined, size: 48, color: DriverColors.accent),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Vehicle Manifest Active',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'You have no assigned vehicle logistics underway. Check your Mission Board for incoming dispatches.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
