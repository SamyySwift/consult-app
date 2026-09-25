import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/surface.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tap_target.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/motion.dart';
import '../../vehicles/models/vehicle_document_model.dart';
import '../../vehicles/widgets/order_request_document_view.dart';

class _WaybillViewerWrapper extends StatelessWidget {
  final BookingModel booking;
  const _WaybillViewerWrapper({required this.booking});

  @override
  Widget build(BuildContext context) {
    return OrderRequestDocumentView(
      document: OrderRequestDocument.fromBooking(booking),
    );
  }
}

class MyBookingsScreen extends StatefulWidget {
  /// Tab to open on: 0 All, 1 Active, 2 Done.
  final int initialTab;

  const MyBookingsScreen({super.key, this.initialTab = 0});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void didUpdateWidget(covariant MyBookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _tabController.animateTo(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        final all = prov.bookings;
        final active = prov.activeBookings;
        final completed = prov.completedBookings;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              Column(
                children: [
                  GlassPageHeader(title: 'My Bookings'),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) => GlassSegmentedControl(
                        labels: [
                          'All (${all.length})',
                          'Active (${active.length})',
                          'Done (${completed.length})',
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
                        for (final list in [all, active, completed])
                          _BookingList(
                            bookings: list,
                            isLoading: prov.isLoading && all.isEmpty,
                            failed: prov.errorMessage != null && all.isEmpty,
                            onRefresh: prov.fetchBookings,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: _NewBookingButton(
            onTap: () => context.push(AppConstants.routeBookingNew),
          ),
        );
      },
    );
  }
}

/// Glowing accent pill floating above the nav bar.
class _NewBookingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewBookingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: context.colors.accentGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: context.colors.accent.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 20, color: Colors.black),
              SizedBox(width: 6),
              Text(
                'New Booking',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool isLoading;
  final bool failed;
  final Future<void> Function() onRefresh;

  const _BookingList({
    required this.bookings,
    required this.isLoading,
    required this.failed,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Leave room for the floating nav and the New Booking button above it.
    final padding = EdgeInsets.fromLTRB(
      24,
      12,
      24,
      MediaQuery.paddingOf(context).bottom + 96,
    );

    // Loading, error and empty states still sit in a scroll view so
    // pull-to-refresh works on them too.
    Widget? placeholder;
    if (isLoading) {
      placeholder = const Center(child: CircularProgressIndicator.adaptive());
    } else if (failed) {
      placeholder = GlassEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t Load Bookings',
        subtitle: 'Check your connection and try again.',
        action: GlassPillButton(
          icon: Icons.refresh_rounded,
          label: 'Try Again',
          onTap: onRefresh,
        ),
      );
    } else if (bookings.isEmpty) {
      placeholder = GlassEmptyState(
        icon: Icons.list_alt_rounded,
        title: 'No Bookings',
        subtitle: 'Bookings you make will appear here.',
        action: GlassPillButton(
          icon: Icons.add_rounded,
          label: 'New Booking',
          onTap: () => context.push(AppConstants.routeBookingNew),
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: placeholder != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding.copyWith(top: 40),
              children: [placeholder],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              itemCount: bookings.length,
              itemBuilder: (context, i) =>
                  _BookingTile(booking: bookings[i], index: i),
            ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  final int index;

  const _BookingTile({required this.booking, required this.index});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final isCancelled = booking.status == BookingStatusEnum.cancelled;

    return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SurfaceCard(
            radius: 26,
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTile(
                      icon: Icons.directions_car_rounded,
                      iconSize: 21,
                      radius: 15,
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
                              fontSize: 16,
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
                    StatusBadge(status: booking.status, compact: true),
                  ],
                ),

                SizedBox(height: 16),

                // Route
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.symmetric(horizontal: 3.5),
                      decoration: BoxDecoration(
                        color: context.colors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        booking.pickup.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 14,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        booking.dropoff.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18),

                // Journey progress
                Row(
                  children: [
                    Text(
                      'Journey',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${booking.status.stage} of ${BookingStatusStage.stageCount}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    Spacer(),
                    FlatChip(label: booking.serviceName),
                  ],
                ),
                SizedBox(height: 10),
                SegmentProgressBar(
                  total: BookingStatusStage.stageCount,
                  filled: booking.status.stage,
                  color: isCancelled ? context.colors.error : null,
                ),

                SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatNaira(booking.totalAmount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TapTarget(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _WaybillViewerWrapper(booking: booking),
                          ),
                        );
                      },
                      child: GlassPill(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Waybill',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (booking.status.isTrackable) ...[
                      SizedBox(width: 8),
                      TapTarget(
                        onTap: () => context.go(
                          '${AppConstants.routeTrack}?booking=${booking.id}',
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: context.colors.accentGradient,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.accent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                size: 14,
                                color: Colors.black,
                              ),
                              SizedBox(width: 5),
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
                  ],
                ),
              ],
            ),
          ),
        )
        .entrance(
          context,
          delay: Duration(milliseconds: index * 50),
          duration: const Duration(milliseconds: 300),
          slide: 0.04,
        );
  }
}
