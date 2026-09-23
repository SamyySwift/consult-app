
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final payments = prov.bookings;

        return Scaffold(
          backgroundColor: context.colors.background,
          body: CustomScrollView(
            slivers: [
              // ── Flat header ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                backgroundColor: context.colors.background,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'Payments',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.3),
                  ),
                ),
              ),

              // ── Summary cards — flat, no border ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      _SummaryTile(
                        label: 'Total Spent',
                        value: '₦${_totalSpent(prov.bookings)}',
                        icon: Icons.payments_rounded,
                      ),
                      SizedBox(width: 10),
                      _SummaryTile(
                        label: 'Transactions',
                        value: '${prov.bookings.length}',
                        icon: Icons.receipt_long_rounded,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),

              // ── List ────────────────────────────────────────────────
              if (payments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card_off_rounded, size: 56, color: context.colors.textLight),
                        SizedBox(height: 16),
                        Text('No Payments Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                        SizedBox(height: 6),
                        Text('Your payment history will appear here', style: TextStyle(color: context.colors.textLight)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final booking = payments[i];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _PaymentCard(booking: booking)
                            .animate(delay: Duration(milliseconds: i * 60))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05),
                      );
                    },
                    childCount: payments.length,
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  String _totalSpent(List<BookingModel> bookings) {
    final total = bookings.fold<double>(0, (sum, b) => sum + b.totalAmount);
    return total.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{3})(?=\d)'),
      (m) => '${m[1]},',
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.accent, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(label, style: TextStyle(fontSize: 11, color: context.colors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final BookingModel booking;

  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final amtFmt = booking.totalAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{3})(?=\d)'),
      (m) => '${m[1]},',
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_shipping_rounded, color: context.colors.accent, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.vehicle.displayName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                    ),
                    Text(
                      '#${booking.id} • ${fmt.format(booking.createdAt)}',
                      style: TextStyle(fontSize: 12, color: context.colors.textLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦$amtFmt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  _PaymentStatusBadge(booking.status),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),
          Container(height: 1, color: context.colors.divider),
          SizedBox(height: 12),

          Row(
            children: [
              _ReceiptTag(label: booking.serviceName, icon: Icons.local_shipping_rounded),
              SizedBox(width: 8),
              if (booking.hasInsurance) _ReceiptTag(label: 'Insured', icon: Icons.shield_rounded),
              if (booking.transportMode == TransportMode.enclosed)
                _ReceiptTag(label: 'Enclosed', icon: Icons.garage_rounded),
              Spacer(),
              GestureDetector(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 14, color: context.colors.accent),
                    SizedBox(width: 4),
                    Text(
                      'Receipt',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.accent),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.textLight),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.colors.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final BookingStatusEnum status;
  const _PaymentStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final isPaid = status != BookingStatusEnum.pending && status != BookingStatusEnum.cancelled;
    return Container(
      margin: EdgeInsets.only(top: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? context.colors.accent.withValues(alpha: 0.12) : context.colors.warningLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPaid ? context.colors.accent : context.colors.warning,
        ),
      ),
    );
  }
}
