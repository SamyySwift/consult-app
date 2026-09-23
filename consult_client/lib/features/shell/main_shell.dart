import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../notifications/providers/notification_provider.dart';
import '../notifications/widgets/in_app_notification_banner.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription? _notifSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifProv = context.read<NotificationProvider>();
      _notifSubscription = notifProv.onNewNotification.listen((notification) {
        if (mounted) {
          InAppNotificationBanner.show(context, notification);
        }
      });
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/bookings')) return 1;
    if (location.startsWith('/track')) return 2;
    if (location.startsWith('/payments')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _selectedIndex(location);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colors.background,
        ),
        child: NavigationBar(
          selectedIndex: idx,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go(AppConstants.routeHome);
              case 1:
                context.go(AppConstants.routeBookings);
              case 2:
                context.go(AppConstants.routeTrack);
              case 3:
                context.go(AppConstants.routePayments);
              case 4:
                context.go(AppConstants.routeProfile);
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: colors.textLight),
              selectedIcon: Icon(Icons.home_rounded, color: colors.accent),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined, color: colors.textLight),
              selectedIcon: Icon(Icons.list_alt_rounded, color: colors.accent),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.my_location_outlined, color: colors.textLight),
              selectedIcon: Icon(Icons.my_location_rounded, color: colors.accent),
              label: 'Track',
            ),
            NavigationDestination(
              icon: Icon(Icons.credit_card_outlined, color: colors.textLight),
              selectedIcon: Icon(Icons.credit_card_rounded, color: colors.accent),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: colors.textLight),
              selectedIcon: Icon(Icons.person_rounded, color: colors.accent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
