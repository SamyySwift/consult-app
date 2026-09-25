import 'package:flutter/material.dart';
import '../../../core/theme/driver_colors.dart';
import '../models/job_model.dart';

extension JobStage on JobStatus {
  /// Steps in a job's journey (Confirmed → Delivered).
  static const int stageCount = 4;

  /// How many journey steps are done: 0 while only assigned or cancelled,
  /// 4 once delivered.
  int get stage => switch (this) {
        JobStatus.assigned || JobStatus.cancelled => 0,
        JobStatus.confirmed => 1,
        JobStatus.pickedUp => 2,
        JobStatus.inTransit => 3,
        JobStatus.completed => 4,
      };

  /// Accent for chips and highlights: amber while awaiting confirmation,
  /// red when cancelled, green otherwise.
  Color get color => switch (this) {
        JobStatus.assigned => DriverColors.warning,
        JobStatus.cancelled => DriverColors.error,
        _ => DriverColors.accent,
      };
}

/// Flat chip showing a job's status in its accent colour.
class JobStatusChip extends StatelessWidget {
  final JobModel job;
  const JobStatusChip({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final color = job.status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            job.statusLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Pickup → drop-off addresses joined by a dot-to-pin rail.
class JobRouteLines extends StatelessWidget {
  final JobModel job;
  const JobRouteLines({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: DriverColors.accent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: DriverColors.accent.withValues(alpha: 0.6), blurRadius: 6)],
              ),
            ),
            Container(
              width: 2,
              height: 24,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
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
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              Text(
                job.dropoff.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
