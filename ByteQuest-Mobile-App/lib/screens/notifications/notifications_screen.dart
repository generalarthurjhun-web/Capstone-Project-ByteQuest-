import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/notification_tile.dart';
import '../../services/auth_service.dart';
import '../../core/config/supabase_config.dart';
import '../../services/learner_realtime_coordinator.dart';

/// Notifications screen with filter tabs connecting to live Supabase DB
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with LearnerRealtimeRefreshMixin<NotificationsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Unread
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  Set<LearnerRealtimeDomain> get realtimeDomains => const {
        LearnerRealtimeDomain.notifications,
      };

  @override
  Future<void> refreshFromRealtime() => _fetchNotifications();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) return;

      final response = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) return;

      await SupabaseConfig.client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId);

      await _fetchNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _markAsRead(dynamic id) async {
    try {
      await SupabaseConfig.client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      await _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  String _formatTimeAgo(String? createdAtStr) {
    if (createdAtStr == null) return '';
    try {
      final dt = DateTime.parse(createdAtStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return '';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'reminder':
      case 'mission':
        return Icons.military_tech;
      case 'badge':
        return Icons.emoji_events;
      case 'level':
      case 'progress':
        return Icons.trending_up;
      case 'achievement':
        return Icons.star;
      case 'leaderboard':
        return Icons.group;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(String? type) {
    switch (type) {
      case 'reminder':
      case 'mission':
        return AppTheme.primaryBlue;
      case 'badge':
      case 'achievement':
        return AppTheme.accentOrange;
      case 'level':
      case 'progress':
        return AppTheme.accentGreen;
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _selectedFilter == 0
        ? _notifications
        : _notifications.where((n) {
            final isUnread = !(n['is_read'] as bool? ?? false);
            return isUnread;
          }).toList();

    final unreadCount = _notifications.where((n) {
      final isUnread = !(n['is_read'] as bool? ?? false);
      return isUnread;
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 0, _notifications.length),
                      const SizedBox(width: 12),
                      _buildFilterChip('Unread', 1, unreadCount),
                    ],
                  ),
                ),

                // Notifications List
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 64,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications',
                                style: AppTheme.headlineSmall.copyWith(
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFilter == 1
                                    ? 'All caught up!'
                                    : 'You\'ll see new notifications here',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 8),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            final id = notification['id'];
                            final title = notification['title'] as String? ??
                                'Notification';
                            final message =
                                notification['message'] as String? ??
                                    notification['content'] as String? ??
                                    '';
                            final type = notification['type'] as String? ??
                                notification['category'] as String?;
                            final createdAtStr =
                                notification['created_at'] as String?;
                            final isUnread =
                                !(notification['is_read'] as bool? ?? false);

                            return NotificationTile(
                              icon: _getNotificationIcon(type),
                              iconColor: _getNotificationIconColor(type),
                              title: title,
                              message: message,
                              time: _formatTimeAgo(createdAtStr),
                              isUnread: isUnread,
                              onTap: isUnread ? () => _markAsRead(id) : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilter == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: AppTheme.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
