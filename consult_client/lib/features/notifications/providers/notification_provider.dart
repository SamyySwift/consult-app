import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;

  // Stream controller to broadcast new incoming notifications for in-app alert banners
  final StreamController<NotificationModel> _newNotificationStreamController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get onNewNotification =>
      _newNotificationStreamController.stream;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get transitNotifications =>
      _notifications.where((n) => n.bookingId != null).toList();

  static const String defaultDemoClientId =
      'b0000000-0000-0000-0000-000000000001';

  NotificationProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    final user = _supabase.auth.currentUser;
    final uid = user?.id ?? defaultDemoClientId;
    fetchNotifications(uid);
    subscribeToNotifications(uid);

    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        fetchNotifications(user.id);
        subscribeToNotifications(user.id);
      } else {
        fetchNotifications(defaultDemoClientId);
        subscribeToNotifications(defaultDemoClientId);
      }
    });
  }

  String get _currentUid =>
      _supabase.auth.currentUser?.id ?? defaultDemoClientId;

  /// Fetch notifications from Supabase
  Future<void> fetchNotifications([String? userId]) async {
    final uid = userId ?? _currentUid;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      _notifications = (data as List)
          .map(
            (json) =>
                NotificationModel.fromSupabaseMap(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications from Supabase: $e');
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribe to real-time notification events
  void subscribeToNotifications(String userId) {
    unsubscribeFromNotifications();

    _realtimeChannel = _supabase
        .channel('public:notifications:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRec = payload.newRecord;
            if (payload.eventType == PostgresChangeEvent.insert &&
                newRec.isNotEmpty) {
              final newNotification = NotificationModel.fromSupabaseMap(newRec);

              // Avoid duplicates
              _notifications.removeWhere((n) => n.id == newNotification.id);
              _notifications.insert(0, newNotification);

              // Broadcast for in-app floating banner
              _newNotificationStreamController.add(newNotification);
              notifyListeners();
            } else if (payload.eventType == PostgresChangeEvent.update &&
                newRec.isNotEmpty) {
              final updatedNotification = NotificationModel.fromSupabaseMap(
                newRec,
              );
              final index = _notifications.indexWhere(
                (n) => n.id == updatedNotification.id,
              );
              if (index >= 0) {
                _notifications[index] = updatedNotification;
              } else {
                _notifications.insert(0, updatedNotification);
              }
              notifyListeners();
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final deletedId = payload.oldRecord['id']?.toString();
              if (deletedId != null) {
                _notifications.removeWhere((n) => n.id == deletedId);
                notifyListeners();
              }
            }
          },
        )
        .subscribe();
  }

  void unsubscribeFromNotifications() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      try {
        await _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notificationId);
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _currentUid);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications for user
  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();

    try {
      await _supabase.from('notifications').delete().eq('user_id', _currentUid);
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  @override
  void dispose() {
    unsubscribeFromNotifications();
    _newNotificationStreamController.close();
    super.dispose();
  }
}
