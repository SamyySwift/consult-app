import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/glass.dart';
import '../notifications/providers/notification_provider.dart';
import '../notifications/widgets/in_app_notification_banner.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

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

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      // Tabs scroll under the floating glass nav; each adds bottom padding
      // from MediaQuery so its last item clears it.
      extendBody: true,
      body: shell,
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: shell.currentIndex,
        // Re-tapping the current tab returns it to its root.
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

/// Floating frosted-glass pill nav with a capsule that slides to the
/// selected tab.
class _GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _GlassNavBar({required this.selectedIndex, required this.onSelect});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.list_alt_outlined, Icons.list_alt_rounded, 'Bookings'),
    _NavItem(Icons.my_location_outlined, Icons.my_location_rounded, 'Track'),
    _NavItem(Icons.credit_card_outlined, Icons.credit_card_rounded, 'Payments'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: GlassContainer(
          radius: 36,
          blur: true,
          tint: Colors.white,
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _items.length;
              return SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: reduceMotion(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * selectedIndex,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          SizedBox(
                            width: itemWidth,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelect(i),
                              child: Semantics(
                                button: true,
                                selected: i == selectedIndex,
                                label: _items[i].label,
                                excludeSemantics: true,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      i == selectedIndex
                                          ? _items[i].selectedIcon
                                          : _items[i].icon,
                                      size: 22,
                                      color: i == selectedIndex
                                          ? colors.accent
                                          : Colors.white.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _items[i].label,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: i == selectedIndex
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
