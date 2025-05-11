import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for society events
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String location;
  final String category;
  final String creatorId;
  final String creatorName;
  final String? lineNumber;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly, yearly
  final List<String> attendees;
  final String status; // upcoming, ongoing, completed, cancelled
  final String approvalStatus; // pending, approved, rejected
  final String visibility; // society, line, private
  final String? rejectionReason; // Reason for rejection if applicable
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.location,
    required this.category,
    required this.creatorId,
    required this.creatorName,
    this.lineNumber,
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurringPattern,
    List<String>? attendees,
    required this.status,
    this.approvalStatus = 'approved', // Default to approved for backward compatibility
    this.visibility = 'society', // Default to society-wide visibility
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  }) : attendees = attendees ?? [];

  /// Create an EventModel from a JSON map
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDateTime: (json['start_date_time'] as Timestamp).toDate(),
      endDateTime: (json['end_date_time'] as Timestamp).toDate(),
      location: json['location'] as String,
      category: json['category'] as String,
      creatorId: json['creator_id'] as String,
      creatorName: json['creator_name'] as String,
      lineNumber: json['line_number'] as String?,
      isAllDay: json['is_all_day'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringPattern: json['recurring_pattern'] as String?,
      attendees: List<String>.from(json['attendees'] ?? []),
      status: json['status'] as String,
      approvalStatus: json['approval_status'] as String? ?? 'approved', // Default for backward compatibility
      visibility: json['visibility'] as String? ?? 'society', // Default for backward compatibility
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: (json['created_at'] as Timestamp).toDate(),
      updatedAt: (json['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Convert EventModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date_time': Timestamp.fromDate(startDateTime),
      'end_date_time': Timestamp.fromDate(endDateTime),
      'location': location,
      'category': category,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'line_number': lineNumber,
      'is_all_day': isAllDay,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'attendees': attendees,
      'status': status,
      'approval_status': approvalStatus,
      'visibility': visibility,
      'rejection_reason': rejectionReason,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of this EventModel with the given fields replaced with new values
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? location,
    String? category,
    String? creatorId,
    String? creatorName,
    String? lineNumber,
    bool? isAllDay,
    bool? isRecurring,
    String? recurringPattern,
    List<String>? attendees,
    String? status,
    String? approvalStatus,
    String? visibility,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      lineNumber: lineNumber ?? this.lineNumber,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      attendees: attendees ?? this.attendees,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      visibility: visibility ?? this.visibility,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
