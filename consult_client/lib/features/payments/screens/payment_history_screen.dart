import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/status_badge.dart';

bool _isPaid(BookingStatusEnum status) =>
    status != BookingStatusEnum.pending &&
    status != BookingStatusEnum.cancelled;

/// Money actually paid: pending and cancelled bookings don't count.
@visibleForTesting
double totalPaid(Iterable<BookingModel> bookings) => bookings
    .where((b) => _isPaid(b.status))
    .fold<double>(0, (sum, b) => sum + b.totalAmount);

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
        final spent = totalPaid(payments);

        final Widget? placeholder;
        if (payments.isEmpty && prov.isLoading) {
          placeholder = const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        } else if (payments.isEmpty && prov.errorMessage != null) {
          placeholder = GlassEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t Load Payments',
            subtitle: 'Check your connection and try again.',
            action: GlassPillButton(
              icon: Icons.refresh_rounded,
              label: 'Try Again',
              onTap: prov.fetchBookings,
            ),
          );
        } else if (payments.isEmpty) {
          placeholder = GlassEmptyState(
            icon: Icons.credit_card_off_rounded,
            title: 'No Payments Yet',
            subtitle: 'Payments for your bookings will appear here.',
            action: GlassPillButton(
              icon: Icons.add_rounded,
              label: 'New Booking',
              onTap: () => context.push(AppConstants.routeBookingNew),
            ),
          );
        } else {
          placeholder = null;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              RefreshIndicator.adaptive(
                onRefresh: prov.fetchBookings,
                child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    ).entrance(
                      context,
                      duration: const Duration(milliseconds: 500),
                    ),
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
                  if (placeholder != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: placeholder,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final booking = payments[i];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: _PaymentCard(booking: booking).entrance(
                            context,
                            delay: Duration(milliseconds: i * 60),
                            duration: const Duration(milliseconds: 300),
                            slide: 0.05,
                          ),
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

    return SurfaceCard(
      radius: 26,
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: Icons.local_shipping_rounded, radius: 15),
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
                        color: Colors.white.withValues(alpha: 0.55),
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

          // Receipt link removed until receipts exist.
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FlatChip(
                  label: booking.serviceName,
                  icon: Icons.local_shipping_rounded,
                ),
                if (booking.hasInsurance)
                  FlatChip(label: 'Insured', icon: Icons.shield_rounded),
                if (booking.transportMode == TransportMode.enclosed)
                  FlatChip(label: 'Enclosed', icon: Icons.garage_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
