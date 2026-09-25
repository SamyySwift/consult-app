import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationItemCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationItemCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = notification.accentColor;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(
          notification.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification removed'),
            backgroundColor: colors.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            context.read<NotificationProvider>().markAsRead(notification.id);
          }
          if (onTap != null) {
            onTap!();
          } else if (notification.bookingId != null) {
            // Find booking in provider if active and navigate to track
            context.go(AppConstants.routeTrack);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            radius: 24,
            glow: !notification.isRead,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Badge
                GlassContainer(
                  width: 44,
                  height: 44,
                  radius: 22,
                  tint: accentColor,
                  child: Icon(
                    notification.iconData,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top tag & timestamp row
                      Row(
                        children: [
                          GlassPill(
                            tint: accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            child: Text(
                              notification.statusTag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.accent.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Body
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(
                            alpha: notification.isRead ? 0.55 : 0.8,
                          ),
                          height: 1.35,
                        ),
                      ),

                      // Booking Link Button
                      if (notification.bookingId != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            if (!notification.isRead) {
                              context.read<NotificationProvider>().markAsRead(
                                notification.id,
                              );
                            }
                            context.go(AppConstants.routeTrack);
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: GlassPill(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_searching_rounded,
                                  size: 14,
                                  color: colors.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Track Order #${shortRef(notification.bookingId!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: colors.accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
