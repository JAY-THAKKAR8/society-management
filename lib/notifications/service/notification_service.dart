import 'package:society_management/utility/firebase_messaging_service.dart';

/// Service to handle different types of notifications in the society management app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Send notification when a new meeting is created
  static Future<void> sendMeetingCreatedNotification({
    required String meetingTitle,
    required String meetingDate,
    required String creatorName,
    String? targetLine,
  }) async {
    final title = 'New Meeting: $meetingTitle';
    final body = 'Meeting scheduled for $meetingDate by $creatorName';

    final data = {
      'type': 'meeting_created',
      'meeting_title': meetingTitle,
      'meeting_date': meetingDate,
      'creator_name': creatorName,
      'target_line': targetLine ?? 'all',
    };

    // For now, show local notification for immediate feedback
    // In production, this would send to server/FCM
    await FirebaseMessagingService.showLocalNotification(
      title: title,
      body: body,
      data: data,
    );

    if (targetLine != null) {
      await FirebaseMessagingService.sendNotificationToLine(
        lineNumber: targetLine,
        title: title,
        body: body,
        data: data,
      );
    } else {
      await FirebaseMessagingService.sendNotificationToAll(
        title: title,
        body: body,
        data: data,
      );
    }
  }

  /// Send notification when a meeting is updated
  static Future<void> sendMeetingUpdatedNotification({
    required String meetingTitle,
    required String updateDetails,
    String? targetLine,
  }) async {
    final title = 'Meeting Updated: $meetingTitle';
    final body = updateDetails;

    final data = {
      'type': 'meeting_updated',
      'meeting_title': meetingTitle,
      'update_details': updateDetails,
      'target_line': targetLine ?? 'all',
    };

    // Show local notification for immediate feedback
    await FirebaseMessagingService.showLocalNotification(
      title: title,
      body: body,
      data: data,
    );

    if (targetLine != null) {
      await FirebaseMessagingService.sendNotificationToLine(
        lineNumber: targetLine,
        title: title,
        body: body,
        data: data,
      );
    } else {
      await FirebaseMessagingService.sendNotificationToAll(
        title: title,
        body: body,
        data: data,
      );
    }
  }

  /// Send notification for maintenance payment reminders
  static Future<void> sendMaintenanceReminderNotification({
    required String userId,
    required String userName,
    required double pendingAmount,
    required String dueDate,
    required String periodName,
  }) async {
    const title = 'Maintenance Payment Reminder';
    final body = 'Hi $userName, ₹${pendingAmount.toStringAsFixed(0)} pending for $periodName. Due: $dueDate';

    final data = {
      'type': 'maintenance_reminder',
      'user_name': userName,
      'pending_amount': pendingAmount.toString(),
      'due_date': dueDate,
      'period_name': periodName,
    };

    // Show local notification immediately
    await FirebaseMessagingService.showLocalNotification(
      title: title,
      body: body,
      data: data,
    );

    // Also send to server (for future server-side notifications)
    await FirebaseMessagingService.sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send notification when maintenance payment is received
  static Future<void> sendPaymentConfirmationNotification({
    required String userId,
    required String userName,
    required double amountPaid,
    required String periodName,
    required String receiptNumber,
  }) async {
    const title = 'Payment Confirmed';
    final body = 'Payment of ₹${amountPaid.toStringAsFixed(0)} received for $periodName. Receipt: $receiptNumber';

    final data = {
      'type': 'payment_confirmation',
      'user_name': userName,
      'amount_paid': amountPaid.toString(),
      'period_name': periodName,
      'receipt_number': receiptNumber,
    };

    await FirebaseMessagingService.sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send notification to line head about pending collections
  static Future<void> sendLineHeadCollectionAlert({
    required String lineHeadUserId,
    required String lineNumber,
    required int pendingCount,
    required double pendingAmount,
    required String periodName,
  }) async {
    final title = 'Collection Alert - $lineNumber';
    final body = '$pendingCount members pending, ₹${pendingAmount.toStringAsFixed(0)} total for $periodName';

    final data = {
      'type': 'collection_alert',
      'line_number': lineNumber,
      'pending_count': pendingCount.toString(),
      'pending_amount': pendingAmount.toString(),
      'period_name': periodName,
    };

    // Show local notification immediately
    await FirebaseMessagingService.showLocalNotification(
      title: title,
      body: body,
      data: data,
    );

    // Also send to server (for future server-side notifications)
    await FirebaseMessagingService.sendNotificationToUser(
      userId: lineHeadUserId,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send notification when a new maintenance period is created
  static Future<void> sendNewMaintenancePeriodNotification({
    required String periodName,
    required double amount,
    required String dueDate,
    required String createdBy,
  }) async {
    final title = 'New Maintenance Period: $periodName';
    final body = 'Amount: ₹${amount.toStringAsFixed(0)}, Due: $dueDate. Created by $createdBy';

    final data = {
      'type': 'new_maintenance_period',
      'period_name': periodName,
      'amount': amount.toString(),
      'due_date': dueDate,
      'created_by': createdBy,
    };

    await FirebaseMessagingService.sendNotificationToAll(
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send notification when a complaint is submitted
  static Future<void> sendComplaintSubmittedNotification({
    required String complaintTitle,
    required String submittedBy,
    required String lineNumber,
  }) async {
    const title = 'New Complaint Submitted';
    final body = '$complaintTitle submitted by $submittedBy from $lineNumber';

    final data = {
      'type': 'complaint_submitted',
      'complaint_title': complaintTitle,
      'submitted_by': submittedBy,
      'line_number': lineNumber,
    };

    // Show local notification immediately
    await FirebaseMessagingService.showLocalNotification(
      title: title,
      body: body,
      data: data,
    );

    // Send to admins (you might want to implement admin user filtering)
    await FirebaseMessagingService.sendNotificationToAll(
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send notification when complaint status is updated
  static Future<void> sendComplaintStatusUpdateNotification({
    required String userId,
    required String complaintTitle,
    required String newStatus,
    required String updatedBy,
  }) async {
    const title = 'Complaint Status Updated';
    final body = 'Your complaint "$complaintTitle" is now $newStatus by $updatedBy';

    final data = {
      'type': 'complaint_status_update',
      'complaint_title': complaintTitle,
      'new_status': newStatus,
      'updated_by': updatedBy,
    };

    await FirebaseMessagingService.sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send emergency notification to all users
  static Future<void> sendEmergencyNotification({
    required String title,
    required String message,
    required String sentBy,
  }) async {
    final notificationTitle = '🚨 EMERGENCY: $title';
    final body = '$message - Sent by $sentBy';

    final data = {
      'type': 'emergency',
      'emergency_title': title,
      'message': message,
      'sent_by': sentBy,
    };

    // Show local notification immediately
    await FirebaseMessagingService.showLocalNotification(
      title: notificationTitle,
      body: body,
      data: data,
    );

    await FirebaseMessagingService.sendNotificationToAll(
      title: notificationTitle,
      body: body,
      data: data,
    );
  }

  /// Send notification for upcoming meeting reminders
  static Future<void> sendMeetingReminderNotification({
    required String meetingTitle,
    required String meetingTime,
    required String location,
    String? targetLine,
  }) async {
    final title = 'Meeting Reminder: $meetingTitle';
    final body = 'Meeting starts at $meetingTime. Location: $location';

    final data = {
      'type': 'meeting_reminder',
      'meeting_title': meetingTitle,
      'meeting_time': meetingTime,
      'location': location,
      'target_line': targetLine ?? 'all',
    };

    if (targetLine != null) {
      await FirebaseMessagingService.sendNotificationToLine(
        lineNumber: targetLine,
        title: title,
        body: body,
        data: data,
      );
    } else {
      await FirebaseMessagingService.sendNotificationToAll(
        title: title,
        body: body,
        data: data,
      );
    }
  }
}
