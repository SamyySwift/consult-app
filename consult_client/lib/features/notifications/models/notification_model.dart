import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? bookingId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'transit_update',
    this.bookingId,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? bookingId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromSupabaseMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Transit Notification',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'transit_update',
      bookingId: map['booking_id']?.toString(),
      isRead: map['is_read'] == true,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'booking_id': bookingId,
      'is_read': isRead,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  /// Friendly human-readable relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '${hrs}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(createdAt);
    }
  }

  /// Status badge color based on title or type content
  Color get accentColor {
    final t = title.toLowerCase();
    if (t.contains('in transit') || t.contains('out for delivery')) {
      return const Color(0xFFF59E0B); // Amber / Orange
    } else if (t.contains('delivered') || t.contains('confirmed')) {
      return const Color(0xFF10B981); // Emerald Green
    } else if (t.contains('driver assigned') || t.contains('assigned')) {
      return const Color(0xFF3B82F6); // Electric Blue
    } else if (t.contains('picked up')) {
      return const Color(0xFF8B5CF6); // Purple / Indigo
    } else if (t.contains('cancelled')) {
      return const Color(0xFFEF4444); // Red
    }
    return const Color(0xFFE50914); // Brand Red / Default Accent
  }

  /// Icon representing this transit phase
  IconData get iconData {
    final t = title.toLowerCase();
    if (t.contains('in transit')) {
      return Icons.local_shipping_rounded;
    } else if (t.contains('out for delivery')) {
      return Icons.near_me_rounded;
    } else if (t.contains('delivered')) {
      return Icons.check_circle_rounded;
    } else if (t.contains('confirmed')) {
      return Icons.verified_rounded;
    } else if (t.contains('driver assigned') || t.contains('assigned')) {
      return Icons.person_pin_rounded;
    } else if (t.contains('picked up')) {
      return Icons.fact_check_rounded;
    } else if (t.contains('cancelled')) {
      return Icons.cancel_outlined;
    } else if (t.contains('placed') || t.contains('received')) {
      return Icons.inventory_2_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  /// Clean status tag name
  String get statusTag {
    final t = title.toLowerCase();
    if (t.contains('in transit')) return 'IN TRANSIT';
    if (t.contains('out for delivery')) return 'ARRIVING';
    if (t.contains('delivered')) return 'DELIVERED';
    if (t.contains('picked up')) return 'PICKED UP';
    if (t.contains('driver assigned')) return 'ASSIGNED';
    if (t.contains('confirmed')) return 'CONFIRMED';
    if (t.contains('placed') || t.contains('received')) return 'PLACED';
    if (t.contains('cancelled')) return 'CANCELLED';
    return 'UPDATE';
  }
}
