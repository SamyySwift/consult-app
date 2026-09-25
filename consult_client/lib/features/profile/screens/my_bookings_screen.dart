import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
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
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                        _BookingList(bookings: all),
                        _BookingList(bookings: active),
                        _BookingList(bookings: completed),
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
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 80),
          child: GlassEmptyState(
            icon: Icons.list_alt_rounded,
            title: 'No Bookings',
            subtitle: 'Your bookings will appear here',
          ),
        ),
      );
    }

    // Leave room for the floating nav and the New Booking button above it.
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.paddingOf(context).bottom + 96,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, i) => _BookingTile(booking: bookings[i], index: i),
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
          child: GlassContainer(
            radius: 26,
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassContainer(
                      width: 44,
                      height: 44,
                      radius: 15,
                      tint: context.colors.accent,
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: context.colors.accentLight,
                        size: 21,
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
                              color: Colors.white.withValues(alpha: 0.45),
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
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    Spacer(),
                    GlassPill(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        booking.serviceName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                    GestureDetector(
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
                    if (booking.status == BookingStatusEnum.inTransit) ...[
                      SizedBox(width: 8),
                      GestureDetector(
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
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04);
  }
}
