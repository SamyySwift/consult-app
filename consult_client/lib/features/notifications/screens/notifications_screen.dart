import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            actions: [
              if (unread.isNotEmpty)
                TextButton(
                  onPressed: () => notifProv.markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.white70, size: 22),
                color: colors.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
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
                        Icon(Icons.done_all_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Mark all as read',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded,
                            size: 18, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Clear all notifications',
                            style:
                                TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            backgroundColor: colors.surface,
            color: colors.accent,
            onRefresh: () => notifProv.fetchNotifications(),
            child: Column(
              children: [
                // Filter Tabs Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${all.length})',
                        isSelected: _selectedFilter == NotificationFilter.all,
                        onTap: () => setState(
                            () => _selectedFilter = NotificationFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Transit (${transit.length})',
                        isSelected:
                            _selectedFilter == NotificationFilter.transit,
                        onTap: () => setState(
                            () => _selectedFilter = NotificationFilter.transit),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Unread (${unread.length})',
                        isSelected:
                            _selectedFilter == NotificationFilter.unread,
                        onTap: () => setState(
                            () => _selectedFilter = NotificationFilter.unread),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFF222733)),

                // List or Empty
                Expanded(
                  child: notifProv.isLoading && all.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : filteredList.isEmpty
                          ? _buildEmptyState(colors)
                          : _buildGroupedNotificationList(filteredList),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.accent : colors.textSecondary,
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (todayList.isNotEmpty) ...[
          _buildSectionHeader('TODAY'),
          ...todayList.asMap().entries.map((entry) => NotificationItemCard(
                notification: entry.value,
              )
                  .animate()
                  .fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: entry.key * 40),
                  )
                  .slideY(begin: 0.08)),
          const SizedBox(height: 12),
        ],
        if (yesterdayList.isNotEmpty) ...[
          _buildSectionHeader('YESTERDAY'),
          ...yesterdayList.asMap().entries.map((entry) => NotificationItemCard(
                notification: entry.value,
              )
                  .animate()
                  .fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: entry.key * 40),
                  )
                  .slideY(begin: 0.08)),
          const SizedBox(height: 12),
        ],
        if (earlierList.isNotEmpty) ...[
          _buildSectionHeader('EARLIER'),
          ...earlierList.asMap().entries.map((entry) => NotificationItemCard(
                notification: entry.value,
              )
                  .animate()
                  .fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: entry.key * 40),
                  )
                  .slideY(begin: 0.08)),
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
          color: context.colors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == NotificationFilter.unread
                  ? "You're all caught up! There are no unread notifications."
                  : 'You will receive real-time updates for every milestone of your vehicle shipment here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  void _showClearAllDialog(
      BuildContext context, NotificationProvider provider) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        title: const Text(
          'Clear all notifications?',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
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
