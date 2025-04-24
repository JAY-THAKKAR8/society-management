import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status of a complaint
enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  rejected,
}

/// Represents a complaint submitted by a user
class ComplaintModel extends Equatable {
  const ComplaintModel({
    this.id,
    this.userId,
    this.userName,
    this.userVillaNumber,
    this.userLineNumber,
    this.title,
    this.description,
    this.status = ComplaintStatus.pending,
    this.adminResponse,
    this.createdAt,
    this.updatedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      userVillaNumber: json['user_villa_number'] as String?,
      userLineNumber: json['user_line_number'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: _statusFromString(json['status'] as String?),
      adminResponse: json['admin_response'] as String?,
      createdAt: json['created_at'] != null
          ? (json['created_at'] is Timestamp
              ? (json['created_at'] as Timestamp).toDate().toString()
              : json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is Timestamp
              ? (json['updated_at'] as Timestamp).toDate().toString()
              : json['updated_at'] as String)
          : null,
    );
  }

  final String? id;
  final String? userId;
  final String? userName;
  final String? userVillaNumber;
  final String? userLineNumber;
  final String? title;
  final String? description;
  final ComplaintStatus status;
  final String? adminResponse;
  final String? createdAt;
  final String? updatedAt;

  ComplaintModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userVillaNumber,
    String? userLineNumber,
    String? title,
    String? description,
    ComplaintStatus? status,
    String? adminResponse,
    String? createdAt,
    String? updatedAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userVillaNumber: userVillaNumber ?? this.userVillaNumber,
      userLineNumber: userLineNumber ?? this.userLineNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_villa_number': userVillaNumber,
        'user_line_number': userLineNumber,
        'title': title,
        'description': description,
        'status': _statusToString(status),
        'admin_response': adminResponse,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userVillaNumber,
        userLineNumber,
        title,
        description,
        status,
        adminResponse,
        createdAt,
        updatedAt,
      ];

  static ComplaintStatus _statusFromString(String? status) {
    switch (status) {
      case 'pending':
        return ComplaintStatus.pending;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.pending;
    }
  }

  static String _statusToString(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return 'pending';
      case ComplaintStatus.inProgress:
        return 'in_progress';
      case ComplaintStatus.resolved:
        return 'resolved';
      case ComplaintStatus.rejected:
        return 'rejected';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }
}
