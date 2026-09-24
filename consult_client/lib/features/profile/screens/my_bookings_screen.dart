
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../booking/providers/booking_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/status_badge.dart';
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

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
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
          backgroundColor: context.colors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: context.colors.background,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 24, bottom: 60),
                  title: Text(
                    'My Bookings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.3),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(48),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: context.colors.textLight,
                      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      tabs: [
                        Tab(text: 'All (${all.length})', height: 36),
                        Tab(text: 'Active (${active.length})', height: 36),
                        Tab(text: 'Done (${completed.length})', height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _BookingList(bookings: all),
                _BookingList(bookings: active),
                _BookingList(bookings: completed),
              ],
            ),
          ),
          floatingActionButton: GestureDetector(
            onTap: () => context.push(AppConstants.routeBookingNew),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: context.colors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: Colors.black),
                  SizedBox(width: 6),
                  Text('New Booking', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black, fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      },
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_outlined, size: 56, color: context.colors.textLight),
            SizedBox(height: 16),
            Text('No Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
            SizedBox(height: 6),
            Text('Your bookings will appear here', style: TextStyle(color: context.colors.textLight)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 80),
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
    final amtFmt = booking.totalAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{3})(?=\d)'),
      (m) => '${m[1]},',
    );

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_car_rounded, color: context.colors.accent, size: 20),
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
              StatusBadge(status: booking.status),
            ],
          ),

          SizedBox(height: 12),

          // Route dots
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.pickup.address,
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: context.colors.textLight, size: 12),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.dropoff.address,
                  style: TextStyle(fontSize: 12, color: context.colors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),
          Container(height: 1, color: context.colors.divider),
          SizedBox(height: 10),

          Row(
            children: [
              Text(
                '₦$amtFmt',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.serviceName,
                  style: TextStyle(fontSize: 11, color: context.colors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => _WaybillViewerWrapper(booking: booking)
                    )
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: EdgeInsets.only(right: booking.status == BookingStatusEnum.inTransit ? 8 : 0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: context.colors.surfaceVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 14, color: context.colors.textPrimary),
                      SizedBox(width: 4),
                      Text('Waybill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                    ],
                  ),
                ),
              ),
              if (booking.status == BookingStatusEnum.inTransit)
                GestureDetector(
                  onTap: () => context.go('${AppConstants.routeTrack}?booking=${booking.id}'),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location_rounded, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.04);
  }
}
