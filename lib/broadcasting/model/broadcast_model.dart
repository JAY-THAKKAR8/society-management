import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for broadcast messages in the society management app
class BroadcastModel {
  final String? id;
  final String title;
  final String message;
  final BroadcastType type;
  final BroadcastPriority priority;
  final BroadcastTarget target;
  final String? targetLineNumber;
  final String createdBy;
  final String creatorName;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final BroadcastStatus status;
  final List<String> attachmentUrls;
  final Map<String, dynamic> metadata;
  final int totalRecipients;
  final int deliveredCount;
  final int readCount;

  const BroadcastModel({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.target,
    this.targetLineNumber,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    this.scheduledAt,
    required this.status,
    this.attachmentUrls = const [],
    this.metadata = const {},
    this.totalRecipients = 0,
    this.deliveredCount = 0,
    this.readCount = 0,
  });

  factory BroadcastModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BroadcastModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: BroadcastType.values.firstWhere(
        (e) => e.toString() == 'BroadcastType.${data['type']}',
        orElse: () => BroadcastType.announcement,
      ),
      priority: BroadcastPriority.values.firstWhere(
        (e) => e.toString() == 'BroadcastPriority.${data['priority']}',
        orElse: () => BroadcastPriority.normal,
      ),
      target: BroadcastTarget.values.firstWhere(
        (e) => e.toString() == 'BroadcastTarget.${data['target']}',
        orElse: () => BroadcastTarget.all,
      ),
      targetLineNumber: data['target_line_number'],
      createdBy: data['created_by'] ?? '',
      creatorName: data['creator_name'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (data['scheduled_at'] as Timestamp?)?.toDate(),
      status: BroadcastStatus.values.firstWhere(
        (e) => e.toString() == 'BroadcastStatus.${data['status']}',
        orElse: () => BroadcastStatus.draft,
      ),
      attachmentUrls: List<String>.from(data['attachment_urls'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      totalRecipients: data['total_recipients'] ?? 0,
      deliveredCount: data['delivered_count'] ?? 0,
      readCount: data['read_count'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'target': target.name,
      'target_line_number': targetLineNumber,
      'created_by': createdBy,
      'creator_name': creatorName,
      'created_at': Timestamp.fromDate(createdAt),
      'scheduled_at': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'status': status.name,
      'attachment_urls': attachmentUrls,
      'metadata': metadata,
      'total_recipients': totalRecipients,
      'delivered_count': deliveredCount,
      'read_count': readCount,
    };
  }

  BroadcastModel copyWith({
    String? id,
    String? title,
    String? message,
    BroadcastType? type,
    BroadcastPriority? priority,
    BroadcastTarget? target,
    String? targetLineNumber,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? scheduledAt,
    BroadcastStatus? status,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
    int? totalRecipients,
    int? deliveredCount,
    int? readCount,
  }) {
    return BroadcastModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      target: target ?? this.target,
      targetLineNumber: targetLineNumber ?? this.targetLineNumber,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      metadata: metadata ?? this.metadata,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      readCount: readCount ?? this.readCount,
    );
  }
}

/// Types of broadcast messages
enum BroadcastType {
  announcement,
  emergency,
  maintenance,
  event,
  reminder,
  notice,
  celebration,
  warning,
}

/// Priority levels for broadcasts
enum BroadcastPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

/// Target audience for broadcasts
enum BroadcastTarget {
  all,
  line,
  admins,
  lineHeads,
  members,
}

/// Status of broadcast messages
enum BroadcastStatus {
  draft,
  scheduled,
  sent,
  delivered,
  failed,
  cancelled,
}

/// Extensions for better display
extension BroadcastTypeExtension on BroadcastType {
  String get displayName {
    switch (this) {
      case BroadcastType.announcement:
        return 'Announcement';
      case BroadcastType.emergency:
        return 'Emergency';
      case BroadcastType.maintenance:
        return 'Maintenance';
      case BroadcastType.event:
        return 'Event';
      case BroadcastType.reminder:
        return 'Reminder';
      case BroadcastType.notice:
        return 'Notice';
      case BroadcastType.celebration:
        return 'Celebration';
      case BroadcastType.warning:
        return 'Warning';
    }
  }

  String get emoji {
    switch (this) {
      case BroadcastType.announcement:
        return '📢';
      case BroadcastType.emergency:
        return '🚨';
      case BroadcastType.maintenance:
        return '🔧';
      case BroadcastType.event:
        return '🎉';
      case BroadcastType.reminder:
        return '⏰';
      case BroadcastType.notice:
        return '📋';
      case BroadcastType.celebration:
        return '🎊';
      case BroadcastType.warning:
        return '⚠️';
    }
  }
}

extension BroadcastPriorityExtension on BroadcastPriority {
  String get displayName {
    switch (this) {
      case BroadcastPriority.low:
        return 'Low';
      case BroadcastPriority.normal:
        return 'Normal';
      case BroadcastPriority.high:
        return 'High';
      case BroadcastPriority.urgent:
        return 'Urgent';
      case BroadcastPriority.critical:
        return 'Critical';
    }
  }
}

extension BroadcastTargetExtension on BroadcastTarget {
  String get displayName {
    switch (this) {
      case BroadcastTarget.all:
        return 'All Users';
      case BroadcastTarget.line:
        return 'Specific Line';
      case BroadcastTarget.admins:
        return 'Admins Only';
      case BroadcastTarget.lineHeads:
        return 'Line Heads';
      case BroadcastTarget.members:
        return 'Members Only';
    }
  }
}
