import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_item_card.dart';

enum NotificationFilter { all, transit, unread }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<NotificationProvider>(
      builder: (context, notifProv, _) {
        final all = notifProv.notifications;
        final transit = notifProv.transitNotifications;
        final unread = notifProv.unreadNotifications;

        List<NotificationModel> filteredList;
        switch (_selectedFilter) {
          case NotificationFilter.all:
            filteredList = all;
            break;
          case NotificationFilter.transit:
            filteredList = transit;
            break;
          case NotificationFilter.unread:
            filteredList = unread;
            break;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              Column(
                children: [
                  GlassPageHeader(
                    title: 'Notifications',
                    showBack: true,
                    onBack: () => context.pop(),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: 'More',
                        color: const Color(0xF0151515),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        onSelected: (val) {
                          if (val == 'mark_all') {
                            notifProv.markAllAsRead();
                          } else if (val == 'clear_all') {
                            _showClearAllDialog(context, notifProv);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'mark_all',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Mark all as read',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear_all',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_sweep_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Clear all notifications',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: const GlassIconButton(
                          icon: Icons.more_horiz_rounded,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      backgroundColor: colors.surface,
                      color: colors.accent,
                      onRefresh: () => notifProv.fetchNotifications(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                            child: GlassSegmentedControl(
                              labels: [
                                'All (${all.length})',
                                'Transit (${transit.length})',
                                'Unread (${unread.length})',
                              ],
                              selectedIndex: _selectedFilter.index,
                              onChanged: (i) => setState(
                                () => _selectedFilter =
                                    NotificationFilter.values[i],
                              ),
                            ),
                          ),

                          // List or Empty
                          Expanded(
                            child: notifProv.isLoading && all.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : filteredList.isEmpty
                                ? _buildEmptyState()
                                : _buildGroupedNotificationList(filteredList),
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
      },
    );
  }

  Widget _buildGroupedNotificationList(List<NotificationModel> list) {
    // Group items into Today, Yesterday, Earlier
    final now = DateTime.now();
    final todayList = <NotificationModel>[];
    final yesterdayList = <NotificationModel>[];
    final earlierList = <NotificationModel>[];

    for (final item in list) {
      final diffDays = now.difference(item.createdAt).inDays;
      if (diffDays == 0 && item.createdAt.day == now.day) {
        todayList.add(item);
      } else if (diffDays <= 1) {
        yesterdayList.add(item);
      } else {
        earlierList.add(item);
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      children: [
        if (todayList.isNotEmpty) ...[
          _buildSectionHeader('TODAY'),
          ...todayList.asMap().entries.map(
            (entry) => NotificationItemCard(notification: entry.value)
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: entry.key * 40),
                )
                .slideY(begin: 0.08),
          ),
          const SizedBox(height: 12),
        ],
        if (yesterdayList.isNotEmpty) ...[
          _buildSectionHeader('YESTERDAY'),
          ...yesterdayList.asMap().entries.map(
            (entry) => NotificationItemCard(notification: entry.value)
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: entry.key * 40),
                )
                .slideY(begin: 0.08),
          ),
          const SizedBox(height: 12),
        ],
        if (earlierList.isNotEmpty) ...[
          _buildSectionHeader('EARLIER'),
          ...earlierList.asMap().entries.map(
            (entry) => NotificationItemCard(notification: entry.value)
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: entry.key * 40),
                )
                .slideY(begin: 0.08),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.45),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: GlassEmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No Notifications',
          subtitle: _selectedFilter == NotificationFilter.unread
              ? "You're all caught up! There are no unread notifications."
              : 'You will receive real-time updates for every milestone of your vehicle shipment here.',
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationProvider provider,
  ) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xF0151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: const Text(
          'Clear all notifications?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will remove all notification history for your account.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearAll();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
