import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:society_management/broadcasting/model/broadcast_model.dart';
import 'package:society_management/broadcasting/repository/i_broadcast_repository.dart';
import 'package:society_management/notifications/service/notification_service.dart';

/// Service for handling broadcast operations and notifications
@LazySingleton()
class BroadcastService {
  final IBroadcastRepository _broadcastRepository;

  BroadcastService(this._broadcastRepository);

  /// Send broadcast and trigger notifications
  Future<void> sendBroadcastWithNotifications({
    required String broadcastId,
  }) async {
    try {
      log('Sending broadcast with notifications: $broadcastId');

      // Get broadcast details
      final broadcastResult = await _broadcastRepository.getBroadcastById(
        broadcastId: broadcastId,
      );

      final broadcast = broadcastResult.fold(
        (failure) {
          log('Failed to get broadcast: ${failure.message}');
          throw Exception(failure.message);
        },
        (broadcast) => broadcast,
      );

      // Update broadcast status to sent
      await _broadcastRepository.sendBroadcast(broadcastId: broadcastId);

      // Send appropriate notification based on broadcast type
      await _sendNotificationForBroadcast(broadcast);

      log('Broadcast sent successfully with notifications: $broadcastId');
    } catch (e) {
      log('Error sending broadcast with notifications: $e');
      rethrow;
    }
  }

  /// Send notification based on broadcast type
  Future<void> _sendNotificationForBroadcast(BroadcastModel broadcast) async {
    try {
      final title = '${broadcast.type.emoji} ${broadcast.title}';
      final body = broadcast.message;

      switch (broadcast.type) {
        case BroadcastType.emergency:
          await NotificationService.sendEmergencyNotification(
            title: broadcast.title,
            message: broadcast.message,
            sentBy: broadcast.creatorName,
          );
          break;

        case BroadcastType.announcement:
          await NotificationService.sendAnnouncementNotification(
            title: title,
            message: body,
            sentBy: broadcast.creatorName,
            target: broadcast.target,
            targetLineNumber: broadcast.targetLineNumber,
          );
          break;

        case BroadcastType.maintenance:
          await NotificationService.sendMaintenanceAnnouncementNotification(
            title: title,
            message: body,
            sentBy: broadcast.creatorName,
          );
          break;

        case BroadcastType.event:
          await NotificationService.sendEventAnnouncementNotification(
            title: title,
            message: body,
            sentBy: broadcast.creatorName,
            target: broadcast.target,
            targetLineNumber: broadcast.targetLineNumber,
          );
          break;

        case BroadcastType.reminder:
          await NotificationService.sendReminderNotification(
            title: title,
            message: body,
            sentBy: broadcast.creatorName,
          );
          break;

        case BroadcastType.notice:
        case BroadcastType.celebration:
        case BroadcastType.warning:
          await NotificationService.sendGeneralNotification(
            title: title,
            message: body,
            sentBy: broadcast.creatorName,
            type: broadcast.type.name,
            priority: broadcast.priority.name,
            target: broadcast.target,
            targetLineNumber: broadcast.targetLineNumber,
          );
          break;
      }

      log('Notification sent for broadcast type: ${broadcast.type}');
    } catch (e) {
      log('Error sending notification for broadcast: $e');
      // Don't rethrow - broadcast should still be marked as sent even if notification fails
    }
  }

  /// Schedule broadcast for later sending
  Future<void> scheduleBroadcast({
    required String broadcastId,
    required DateTime scheduledAt,
  }) async {
    try {
      await _broadcastRepository.scheduleBroadcast(
        broadcastId: broadcastId,
        scheduledAt: scheduledAt,
      );

      log('Broadcast scheduled successfully: $broadcastId for $scheduledAt');
    } catch (e) {
      log('Error scheduling broadcast: $e');
      rethrow;
    }
  }

  /// Process scheduled broadcasts (to be called by a background service)
  Future<void> processScheduledBroadcasts() async {
    try {
      log('Processing scheduled broadcasts...');

      // Get scheduled broadcasts that are due
      final broadcastsResult = await _broadcastRepository.getBroadcasts(
        status: BroadcastStatus.scheduled,
        toDate: DateTime.now(),
      );

      final broadcasts = broadcastsResult.fold(
        (failure) {
          log('Failed to get scheduled broadcasts: ${failure.message}');
          return <BroadcastModel>[];
        },
        (broadcasts) => broadcasts,
      );

      for (final broadcast in broadcasts) {
        if (broadcast.scheduledAt != null && broadcast.scheduledAt!.isBefore(DateTime.now())) {
          try {
            await sendBroadcastWithNotifications(broadcastId: broadcast.id!);
            log('Processed scheduled broadcast: ${broadcast.id}');
          } catch (e) {
            log('Error processing scheduled broadcast ${broadcast.id}: $e');
          }
        }
      }

      log('Finished processing scheduled broadcasts');
    } catch (e) {
      log('Error processing scheduled broadcasts: $e');
    }
  }

  /// Get broadcast analytics
  Future<Map<String, dynamic>> getBroadcastAnalytics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final broadcastsResult = await _broadcastRepository.getBroadcasts(
        fromDate: fromDate,
        toDate: toDate,
      );

      final broadcasts = broadcastsResult.fold(
        (failure) => <BroadcastModel>[],
        (broadcasts) => broadcasts,
      );

      final analytics = {
        'total_broadcasts': broadcasts.length,
        'by_type': <String, int>{},
        'by_priority': <String, int>{},
        'by_status': <String, int>{},
        'total_recipients': 0,
        'total_delivered': 0,
        'total_read': 0,
      };

      for (final broadcast in broadcasts) {
        // Count by type
        final typeName = broadcast.type.displayName;
        final byType = analytics['by_type'] as Map<String, int>;
        byType[typeName] = (byType[typeName] ?? 0) + 1;

        // Count by priority
        final priorityName = broadcast.priority.displayName;
        final byPriority = analytics['by_priority'] as Map<String, int>;
        byPriority[priorityName] = (byPriority[priorityName] ?? 0) + 1;

        // Count by status
        final statusName = broadcast.status.name;
        final byStatus = analytics['by_status'] as Map<String, int>;
        byStatus[statusName] = (byStatus[statusName] ?? 0) + 1;

        // Sum totals
        analytics['total_recipients'] = (analytics['total_recipients'] as int) + broadcast.totalRecipients;
        analytics['total_delivered'] = (analytics['total_delivered'] as int) + broadcast.deliveredCount;
        analytics['total_read'] = (analytics['total_read'] as int) + broadcast.readCount;
      }

      // Calculate rates
      final totalRecipients = analytics['total_recipients'] as int;
      final totalDelivered = analytics['total_delivered'] as int;
      final totalRead = analytics['total_read'] as int;

      if (totalRecipients > 0) {
        analytics['delivery_rate'] = (totalDelivered / totalRecipients * 100).toStringAsFixed(1);
        analytics['read_rate'] = (totalRead / totalRecipients * 100).toStringAsFixed(1);
      } else {
        analytics['delivery_rate'] = '0.0';
        analytics['read_rate'] = '0.0';
      }

      return analytics;
    } catch (e) {
      log('Error getting broadcast analytics: $e');
      return {};
    }
  }

  /// Create and send immediate broadcast
  Future<String?> createAndSendBroadcast({
    required String title,
    required String message,
    required BroadcastType type,
    required BroadcastPriority priority,
    required BroadcastTarget target,
    String? targetLineNumber,
    required String createdBy,
    required String creatorName,
    List<String> attachmentUrls = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Create broadcast
      final createResult = await _broadcastRepository.createBroadcast(
        title: title,
        message: message,
        type: type,
        priority: priority,
        target: target,
        targetLineNumber: targetLineNumber,
        createdBy: createdBy,
        creatorName: creatorName,
        attachmentUrls: attachmentUrls,
        metadata: metadata,
      );

      final broadcast = createResult.fold(
        (failure) {
          log('Failed to create broadcast: ${failure.message}');
          throw Exception(failure.message);
        },
        (broadcast) => broadcast,
      );

      // Send immediately
      await sendBroadcastWithNotifications(broadcastId: broadcast.id!);

      log('Broadcast created and sent successfully: ${broadcast.id}');
      return broadcast.id;
    } catch (e) {
      log('Error creating and sending broadcast: $e');
      rethrow;
    }
  }

  /// Get broadcast statistics for dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final thisWeek = today.subtract(const Duration(days: 7));
      final thisMonth = DateTime(today.year, today.month, 1);

      final weeklyAnalytics = await getBroadcastAnalytics(fromDate: thisWeek);
      final monthlyAnalytics = await getBroadcastAnalytics(fromDate: thisMonth);

      return {
        'weekly': weeklyAnalytics,
        'monthly': monthlyAnalytics,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('Error getting dashboard stats: $e');
      return {};
    }
  }
}
