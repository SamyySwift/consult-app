import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../booking/providers/booking_provider.dart';
import '../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/status_badge.dart';
import '../auth/providers/auth_provider.dart';
import '../notifications/providers/notification_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, auth, bookingProv, _) {
        final user = auth.user;
        final active = bookingProv.activeBookings;

        return Scaffold(
          backgroundColor: context.colors.background,
          body: CustomScrollView(
            slivers: [
              // ── Tesla-style header: flat black, clean text, no gradient ───
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()} 👋',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.textLight,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    user?.firstName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification with live unread badge
                            Consumer<NotificationProvider>(
                              builder: (context, notifProv, _) {
                                final unread = notifProv.unreadCount;
                                return Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: context.colors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: unread > 0
                                          ? context.colors.accent.withValues(alpha: 0.35)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () => context.push(AppConstants.routeNotifications),
                                    icon: Badge(
                                      isLabelVisible: unread > 0,
                                      label: Text(
                                        unread > 99 ? '99+' : unread.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: context.colors.accent,
                                      child: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 10),
                            _Avatar(user: user),
                          ],
                        ).animate().fadeIn(duration: 400.ms),

                        SizedBox(height: 28),

                        // Stats row — Tesla-style flat cards
                        Row(
                          children: [
                            _StatCard(
                              label: 'Active',
                              value: active.length.toString(),
                              icon: Icons.local_shipping_rounded,
                              color: context.colors.accent,
                            ),
                            SizedBox(width: 10),
                            _StatCard(
                              label: 'Completed',
                              value: bookingProv.completedBookings.length.toString(),
                              icon: Icons.check_circle_rounded,
                              color: context.colors.accent,
                            ),
                            SizedBox(width: 10),
                            _StatCard(
                              label: 'Total',
                              value: bookingProv.bookings.length.toString(),
                              icon: Icons.receipt_long_rounded,
                              color: context.colors.textLight,
                            ),
                          ],
                        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Quick actions — clean flat grid ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                      ),
                      SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _QuickAction(
                              icon: Icons.add_circle_rounded,
                              label: 'New\nBooking',
                              onTap: () => context.push(AppConstants.routeBookingNew),
                            ),
                            SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.my_location_rounded,
                              label: 'Track\nVehicle',
                              onTap: () => context.go(AppConstants.routeTrack),
                            ),
                            SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.credit_card_rounded,
                              label: 'Payment\nHistory',
                              onTap: () => context.go(AppConstants.routePayments),
                            ),
                            SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.support_agent_rounded,
                              label: 'Support',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                ),
              ),

              // ── Active bookings ─────────────────────────────────────────
              if (active.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Active Shipments',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppConstants.routeBookings),
                          child: Text(
                            'See All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: _ActiveBookingCard(
                        booking: active[i],
                        onTrack: () => context.go('${AppConstants.routeTrack}?booking=${active[i].id}'),
                      ),
                    ).animate(delay: Duration(milliseconds: 300 + i * 100)).fadeIn(duration: 400.ms).slideY(begin: 0.08),
                    childCount: active.length,
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: _EmptyActiveCard(
                      onBook: () => context.push(AppConstants.routeBookingNew),
                    ),
                  ),
                ),

              // ── Promo banner ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: _PromoBanner(),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              ),
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final dynamic user;
  const _Avatar({this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppConstants.routeProfile),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: Text(
            user?.initials ?? 'U',
            style: TextStyle(
              color: context.colors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat card — Tesla flat style ──────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: context.colors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action — Tesla minimal icon tile ─────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.colors.accent, size: 24),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active booking card — Tesla flat, no shadow ────────────────────────────
class _ActiveBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTrack;

  const _ActiveBookingCard({required this.booking, required this.onTrack});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_car_rounded, color: context.colors.accent, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.vehicle.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Booking #${booking.id}',
                      style: TextStyle(fontSize: 12, color: context.colors.textLight),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),

          SizedBox(height: 14),
          Container(height: 1, color: context.colors.divider),
          SizedBox(height: 14),

          // Route
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                    width: 1,
                    height: 20,
                    color: context.colors.divider,
                  ),
                  SizedBox(height: 2),
                  Icon(Icons.location_on, color: context.colors.textLight, size: 14),
                ],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.pickup.address,
                      style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),
                    Text(
                      booking.dropoff.address,
                      style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Text(
                  booking.pickup.scheduledDateTime != null
                      ? 'Pickup: ${fmt.format(booking.pickup.scheduledDateTime!)}'
                      : '',
                  style: TextStyle(fontSize: 12, color: context.colors.textLight),
                ),
              ),
              GestureDetector(
                onTap: onTrack,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded, size: 14, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        'Track',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty active card ─────────────────────────────────────────────────────
class _EmptyActiveCard extends StatelessWidget {
  final VoidCallback onBook;
  const _EmptyActiveCard({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_outlined, size: 32, color: context.colors.textLight),
          ),
          SizedBox(height: 16),
          Text(
            'No Active Shipments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
          ),
          SizedBox(height: 6),
          Text(
            'Book your first vehicle transport today',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.colors.textLight),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: onBook,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: Colors.black),
                  SizedBox(width: 6),
                  Text(
                    'New Booking',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promo banner — Tesla-green accent ─────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIMITED OFFER',
                    style: TextStyle(
                      color: context.colors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Get 15% off\nyour first booking!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push(AppConstants.routeBookingNew),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: context.colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.local_offer_rounded, size: 28, color: context.colors.accent),
          ),
        ],
      ),
    );
  }
}
