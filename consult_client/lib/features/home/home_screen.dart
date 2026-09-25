import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../booking/providers/booking_provider.dart';
import '../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tap_target.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/links.dart';
import '../../../core/utils/motion.dart';
import '../auth/providers/auth_provider.dart';
import '../notifications/providers/notification_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Active shipments listed on the landing page before "See All".
  static const _maxShipmentsShown = 3;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (context, auth, bookingProv, _) {
        final user = auth.user;
        final active = bookingProv.activeBookings;
        final bookings = bookingProv.bookings;
        int countWhere(bool Function(BookingStatusEnum) test) =>
            bookings.where((b) => test(b.status)).length;

        void track(BookingModel b) =>
            context.go('${AppConstants.routeTrack}?booking=${b.id}');

        // Nothing to show yet: say so, rather than "No Active Shipments".
        final Widget shipmentSlot;
        if (bookings.isEmpty && bookingProv.isLoading) {
          shipmentSlot = const _ShipmentSkeleton();
        } else if (bookings.isEmpty && bookingProv.errorMessage != null) {
          shipmentSlot = GlassEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t Load Bookings',
            subtitle: 'Check your connection and try again.',
            action: GlassPillButton(
              icon: Icons.refresh_rounded,
              label: 'Try Again',
              onTap: bookingProv.fetchBookings,
            ),
          );
        } else if (active.isEmpty) {
          shipmentSlot = _EmptyShipmentCard(
            onBook: () => context.push(AppConstants.routeBookingNew),
          );
        } else {
          shipmentSlot = _FeaturedShipmentCard(
            booking: active.first,
            onTrack: () => track(active.first),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            children: [
              const Positioned.fill(child: _HeroBackdrop()),
              RefreshIndicator.adaptive(
                onRefresh: bookingProv.fetchBookings,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      ).entrance(context, slide: 0),
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
                                  countWhere(
                                    (s) =>
                                        s == BookingStatusEnum.pending ||
                                        s == BookingStatusEnum.confirmed,
                                  ),
                                  bookings.length,
                                ),
                                _statusPill(
                                  Icons.local_shipping_rounded,
                                  'In Transit',
                                  countWhere((s) => s.isTrackable),
                                  bookings.length,
                                ),
                                _statusPill(
                                  Icons.check_circle_rounded,
                                  'Delivered',
                                  countWhere(
                                    (s) => s == BookingStatusEnum.delivered,
                                  ),
                                  bookings.length,
                                ),
                              ],
                            ),
                          ).entrance(
                            context,
                            delay: const Duration(milliseconds: 100),
                            duration: const Duration(milliseconds: 500),
                          ),
                    ),

                    // ── Active shipments ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Active Shipments',
                        padding: EdgeInsets.fromLTRB(24, 40, 24, 14),
                        onSeeAll: active.isEmpty
                            ? null
                            : () => context.go(
                                '${AppConstants.routeBookings}?tab=active',
                              ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child:
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: shipmentSlot,
                          ).entrance(
                            context,
                            delay: const Duration(milliseconds: 200),
                            duration: const Duration(milliseconds: 500),
                          ),
                    ),
                    // The featured card plus up to two rows; See All has the rest.
                    if (active.length > 1)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final booking = active[i + 1];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: _ShipmentRow(
                                  booking: booking,
                                  onTap: () => track(booking),
                                ),
                              ).entrance(
                                context,
                                delay: Duration(milliseconds: 250 + i * 80),
                              );
                            },
                            childCount:
                                math.min(active.length, _maxShipmentsShown) - 1,
                          ),
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
                      child:
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _QuickAction(
                                  icon: Icons.add_circle_rounded,
                                  label: 'New\nBooking',
                                  onTap: () => context.push(
                                    AppConstants.routeBookingNew,
                                  ),
                                ),
                                SizedBox(width: 12),
                                _QuickAction(
                                  icon: Icons.my_location_rounded,
                                  label: 'Track\nVehicle',
                                  onTap: () =>
                                      context.go(AppConstants.routeTrack),
                                ),
                                SizedBox(width: 12),
                                _QuickAction(
                                  icon: Icons.credit_card_rounded,
                                  label: 'Payment\nHistory',
                                  onTap: () =>
                                      context.go(AppConstants.routePayments),
                                ),
                                SizedBox(width: 12),
                                _QuickAction(
                                  icon: Icons.support_agent_rounded,
                                  label: 'Support',
                                  onTap: () => openLink(
                                    context,
                                    Uri(
                                      scheme: 'mailto',
                                      path: AppConstants.supportEmail,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).entrance(
                            context,
                            delay: const Duration(milliseconds: 300),
                            slide: 0,
                          ),
                    ),

                    // ── For you ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'For You',
                        padding: EdgeInsets.fromLTRB(24, 30, 24, 14),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child:
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: _PromoBanner(),
                          ).entrance(
                            context,
                            delay: const Duration(milliseconds: 400),
                            slide: 0,
                          ),
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
    // Neutral glass, matching the bell beside it; green is kept for status.
    return Semantics(
      button: true,
      label: 'Profile',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.go(AppConstants.routeProfile),
        child: GlassContainer(
          width: 46,
          height: 46,
          radius: 23,
          blur: true,
          child: Center(
            child: Text(
              user?.initials ?? 'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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
            TapTarget(
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
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14),
              IconTile(
                icon: Icons.directions_car_rounded,
                size: 72,
                iconSize: 34,
                radius: 20,
                accent: true,
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

/// Placeholder in the shipment slot while bookings load.
class _ShipmentSkeleton extends StatelessWidget {
  const _ShipmentSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Semantics(
      label: 'Loading bookings',
      child: SurfaceCard(
        radius: 30,
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(90, 20),
                  SizedBox(height: 14),
                  bar(180, 20),
                  SizedBox(height: 10),
                  bar(double.infinity, 14),
                  SizedBox(height: 6),
                  bar(120, 14),
                ],
              ),
            ),
            SizedBox(width: 14),
            bar(72, 84),
          ],
        ),
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
              IconTile(
                icon: Icons.local_shipping_outlined,
                size: 56,
                iconSize: 28,
                radius: 18,
                accent: true,
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
    return SurfaceCard(
      onTap: onTap,
      radius: 22,
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(icon: Icons.directions_car_rounded, size: 42),
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
      child: Semantics(
        button: true,
        label: label.replaceAll('\n', ' '),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: SurfaceCard(
                  radius: 24,
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 28,
                    ),
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
      ),
    );
  }
}

// ── Promo: photo card with glass CTA ──────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
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
                    FlatChip(label: 'LIMITED OFFER', accent: true),
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
                    // Clear glass is right here: a control floating on a photo.
                    TapTarget(
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
