import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/status_badge.dart';

bool _isPaid(BookingStatusEnum status) =>
    status != BookingStatusEnum.pending &&
    status != BookingStatusEnum.cancelled;

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final payments = prov.bookings;
        final total = payments.length;
        final paid = payments.where((b) => _isPaid(b.status)).length;
        final pending = payments
            .where((b) => b.status == BookingStatusEnum.pending)
            .length;
        final spent = payments.fold<double>(0, (sum, b) => sum + b.totalAmount);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: GlassPageHeader(title: 'Payments')),

                  // ── Total spent ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 36, 24, 0),
                      child: BracketedStats(
                        label: 'Total Spent',
                        value: formatNaira(spent),
                        pills: [
                          StatPillData(
                            icon: Icons.receipt_long_rounded,
                            value: '$total',
                            label: 'Transactions',
                            progress: total == 0 ? 0 : 1,
                          ),
                          StatPillData(
                            icon: Icons.check_circle_rounded,
                            value: '$paid',
                            label: 'Paid',
                            progress: total == 0 ? 0 : paid / total,
                          ),
                          StatPillData(
                            icon: Icons.hourglass_bottom_rounded,
                            value: '$pending',
                            label: 'Pending',
                            progress: total == 0 ? 0 : pending / total,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 40, 24, 14),
                      child: Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // ── List ────────────────────────────────────────────────
                  if (payments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: GlassEmptyState(
                          icon: Icons.credit_card_off_rounded,
                          title: 'No Payments Yet',
                          subtitle: 'Your payment history will appear here',
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final booking = payments[i];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: _PaymentCard(booking: booking)
                              .animate(delay: Duration(milliseconds: i * 60))
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.05),
                        );
                      }, childCount: payments.length),
                    ),

                  // Clear the floating nav bar.
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final BookingModel booking;

  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final isPaid = _isPaid(booking.status);

    return GlassContainer(
      radius: 26,
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              GlassContainer(
                width: 44,
                height: 44,
                radius: 15,
                tint: context.colors.accent,
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: context.colors.accentLight,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.vehicle.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '#${shortRef(booking.id)} · ${fmt.format(booking.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatNaira(booking.totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPaid
                          ? context.colors.accent
                          : context.colors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReceiptTag(
                      label: booking.serviceName,
                      icon: Icons.local_shipping_rounded,
                    ),
                    if (booking.hasInsurance)
                      _ReceiptTag(label: 'Insured', icon: Icons.shield_rounded),
                    if (booking.transportMode == TransportMode.enclosed)
                      _ReceiptTag(
                        label: 'Enclosed',
                        icon: Icons.garage_rounded,
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: context.colors.accent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Receipt',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.accent,
                      ),
                    ),
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

class _ReceiptTag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ReceiptTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
