import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../booking/providers/booking_provider.dart';
import '../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
import '../auth/providers/auth_provider.dart';
import '../notifications/providers/notification_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _pendingStatuses = {
    BookingStatusEnum.pending,
    BookingStatusEnum.confirmed,
  };
  static const _inTransitStatuses = {
    BookingStatusEnum.pickedUp,
    BookingStatusEnum.inTransit,
    BookingStatusEnum.outForDelivery,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, auth, bookingProv, _) {
        final user = auth.user;
        final active = bookingProv.activeBookings;
        final bookings = bookingProv.bookings;
        int countOf(Set<BookingStatusEnum> statuses) =>
            bookings.where((b) => statuses.contains(b.status)).length;

        void track(BookingModel b) =>
            context.go('${AppConstants.routeTrack}?booking=${b.id}');

        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            children: [
              const Positioned.fill(child: _HeroBackdrop()),
              CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()} 👋',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user?.firstName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const _NotificationButton(),
                            SizedBox(width: 10),
                            _Avatar(user: user),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  // ── Hero metric ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child:
                        Padding(
                              padding: EdgeInsets.fromLTRB(24, 56, 24, 0),
                              child: BracketedStats(
                                label: 'Active Shipments',
                                value: '${active.length}',
                                pills: [
                                  _statusPill(
                                    Icons.hourglass_bottom_rounded,
                                    'Pending',
                                    countOf(_pendingStatuses),
                                    bookings.length,
                                  ),
                                  _statusPill(
                                    Icons.local_shipping_rounded,
                                    'In Transit',
                                    countOf(_inTransitStatuses),
                                    bookings.length,
                                  ),
                                  _statusPill(
                                    Icons.check_circle_rounded,
                                    'Delivered',
                                    countOf({BookingStatusEnum.delivered}),
                                    bookings.length,
                                  ),
                                ],
                              ),
                            )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.08),
                  ),

                  // ── Active shipments ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Active Shipments',
                      padding: EdgeInsets.fromLTRB(24, 40, 24, 14),
                      onSeeAll: active.isEmpty
                          ? null
                          : () => context.go(AppConstants.routeBookings),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child:
                        Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: active.isEmpty
                                  ? _EmptyShipmentCard(
                                      onBook: () => context.push(
                                        AppConstants.routeBookingNew,
                                      ),
                                    )
                                  : _FeaturedShipmentCard(
                                      booking: active.first,
                                      onTrack: () => track(active.first),
                                    ),
                            )
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.08),
                  ),
                  if (active.length > 1)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final booking = active[i + 1];
                          return Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: _ShipmentRow(
                                  booking: booking,
                                  onTap: () => track(booking),
                                ),
                              )
                              .animate(
                                delay: Duration(milliseconds: 250 + i * 80),
                              )
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.08);
                        }, childCount: active.length - 1),
                      ),
                    ),

                  // ── Quick actions ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Quick Actions',
                      padding: EdgeInsets.fromLTRB(24, 30, 24, 14),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle_rounded,
                            label: 'New\nBooking',
                            onTap: () =>
                                context.push(AppConstants.routeBookingNew),
                          ),
                          SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.my_location_rounded,
                            label: 'Track\nVehicle',
                            onTap: () => context.go(AppConstants.routeTrack),
                          ),
                          SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.credit_card_rounded,
                            label: 'Payment\nHistory',
                            onTap: () => context.go(AppConstants.routePayments),
                          ),
                          SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.support_agent_rounded,
                            label: 'Support',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  ),

                  // ── For you ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'For You',
                      padding: EdgeInsets.fromLTRB(24, 30, 24, 14),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _PromoBanner(),
                    ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
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

  /// Pill whose rim shows this status's share of all bookings.
  static StatPillData _statusPill(
    IconData icon,
    String label,
    int count,
    int total,
  ) => StatPillData(
    icon: icon,
    value: '$count',
    label: label,
    progress: total == 0 ? 0 : count / total,
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Hero backdrop: graded car-carrier photo fading into black ─────────────
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final accent = context.colors.accent;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.55,
          // Modulate (not multiply) so the green tint only touches the photo's
          // own pixels; multiply also paints transparent areas.
          child: Image.network(
            AppConstants.heroImageUrl,
            fit: BoxFit.cover,
            alignment: Alignment(0.15, 0),
            color: Color(0xFF6E9C86),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.55 + 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.25, 0.6, 0.92],
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        // Soft accent light behind the featured card.
        Positioned(
          top: height * 0.38,
          left: -80,
          right: -80,
          height: height * 0.45,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.16),
                  accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header buttons ────────────────────────────────────────────────────────
class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProv, _) {
        return GlassIconButton(
          icon: Icons.notifications_outlined,
          semanticLabel: 'Notifications',
          badgeCount: notifProv.unreadCount,
          onTap: () => context.push(AppConstants.routeNotifications),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final dynamic user;
  const _Avatar({this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppConstants.routeProfile),
      child: GlassContainer(
        width: 46,
        height: 46,
        radius: 23,
        blur: true,
        glow: true,
        tint: context.colors.accent,
        child: Center(
          child: Text(
            user?.initials ?? 'U',
            style: TextStyle(
              color: context.colors.accentLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.padding,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Featured shipment: luminous glass card ────────────────────────────────
class _FeaturedShipmentCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTrack;

  const _FeaturedShipmentCard({required this.booking, required this.onTrack});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');
    final pickupAt = booking.pickup.scheduledDateTime;

    return GlassContainer(
      radius: 30,
      blur: true,
      glow: true,
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(status: booking.status, compact: true),
              Spacer(),
              if (pickupAt != null)
                Text(
                  'Pickup ${fmt.format(pickupAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.vehicle.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${booking.pickup.address}  →  ${booking.dropoff.address}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Booking #${shortRef(booking.id)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14),
              GlassContainer(
                width: 72,
                height: 84,
                radius: 20,
                tint: context.colors.accent,
                child: Icon(
                  Icons.directions_car_rounded,
                  size: 34,
                  color: context.colors.accentLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          GlassPillButton(
            icon: Icons.my_location_rounded,
            label: 'Track live',
            onTap: onTrack,
          ),
        ],
      ),
    );
  }
}

class _EmptyShipmentCard extends StatelessWidget {
  final VoidCallback onBook;
  const _EmptyShipmentCard({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 30,
      blur: true,
      glow: true,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GlassContainer(
                width: 56,
                height: 56,
                radius: 18,
                tint: context.colors.accent,
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 28,
                  color: context.colors.accentLight,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Shipments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Book your first vehicle transport today',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          GlassPillButton(
            icon: Icons.add_rounded,
            label: 'New Booking',
            onTap: onBook,
          ),
        ],
      ),
    );
  }
}

// ── Compact row for the remaining active shipments ────────────────────────
class _ShipmentRow extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _ShipmentRow({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 22,
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            GlassContainer(
              width: 42,
              height: 42,
              radius: 14,
              tint: context.colors.accent,
              child: Icon(
                Icons.directions_car_rounded,
                size: 20,
                color: context.colors.accentLight,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${booking.pickup.address} → ${booking.dropoff.address}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            StatusBadge(status: booking.status, compact: true),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action: glass squircle with label underneath ────────────────────
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
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: GlassContainer(
                radius: 24,
                child: Center(
                  child: Icon(icon, color: context.colors.accent, size: 28),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Promo: photo card with glass CTA ──────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                AppConstants.heroImageUrl,
                fit: BoxFit.cover,
                alignment: Alignment(0.4, 0),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassPill(
                      tint: context.colors.accent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        'LIMITED OFFER',
                        style: TextStyle(
                          color: context.colors.accentLight,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => context.push(AppConstants.routeBookingNew),
                      child: GlassPill(
                        blur: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Book Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.colors.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
