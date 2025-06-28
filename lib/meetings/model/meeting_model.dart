import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetingType { general, emergency, financial, maintenance, committee, social }

enum AgendaStatus { pending, inProgress, completed }

enum AttendanceStatus { present, absent, notMarked }

class MeetingModel {
  final String? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final MeetingType type;
  final String? targetLine; // null means all lines
  final String createdBy;
  final String creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AgendaItem> agenda;
  final List<AttendanceRecord> attendance;

  MeetingModel({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    this.targetLine,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.agenda = const [],
    this.attendance = const [],
  });

  bool get isPast => DateTime.now().isAfter(dateTime);
  bool get isUpcoming => DateTime.now().isBefore(dateTime);

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: (json['dateTime'] as Timestamp).toDate(),
      type: MeetingType.values.firstWhere(
        (e) => e.toString() == 'MeetingType.${json['type']}',
        orElse: () => MeetingType.general,
      ),
      targetLine: json['targetLine'],
      createdBy: json['createdBy'] ?? '',
      creatorName: json['creatorName'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      agenda: (json['agenda'] as List<dynamic>?)?.map((item) => AgendaItem.fromJson(item)).toList() ?? [],
      attendance: (json['attendance'] as List<dynamic>?)?.map((item) => AttendanceRecord.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'type': type.toString().split('.').last,
      'targetLine': targetLine,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'agenda': agenda.map((item) => item.toJson()).toList(),
      'attendance': attendance.map((item) => item.toJson()).toList(),
    };
  }

  MeetingModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    MeetingType? type,
    String? targetLine,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AgendaItem>? agenda,
    List<AttendanceRecord>? attendance,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      targetLine: targetLine ?? this.targetLine,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      agenda: agenda ?? this.agenda,
      attendance: attendance ?? this.attendance,
    );
  }
}

class AgendaItem {
  final String id;
  final String title;
  final String description;
  final AgendaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgendaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: AgendaStatus.values.firstWhere(
        (e) => e.toString() == 'AgendaStatus.${json['status']}',
        orElse: () => AgendaStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AgendaItem copyWith({
    String? id,
    String? title,
    String? description,
    AgendaStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AttendanceRecord {
  final String userId;
  final String userName;
  final String userRole;
  final String? userLine;
  final String? userVilla;
  final AttendanceStatus status;
  final DateTime? markedAt;
  final String? markedBy;

  AttendanceRecord({
    required this.userId,
    required this.userName,
    required this.userRole,
    this.userLine,
    this.userVilla,
    required this.status,
    this.markedAt,
    this.markedBy,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userRole: json['userRole'] ?? '',
      userLine: json['userLine'],
      userVilla: json['userVilla'],
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${json['status']}',
        orElse: () => AttendanceStatus.notMarked,
      ),
      markedAt: json['markedAt'] != null ? (json['markedAt'] as Timestamp).toDate() : null,
      markedBy: json['markedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userLine': userLine,
      'userVilla': userVilla,
      'status': status.toString().split('.').last,
      'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : null,
      'markedBy': markedBy,
    };
  }

  AttendanceRecord copyWith({
    String? userId,
    String? userName,
    String? userRole,
    String? userLine,
    String? userVilla,
    AttendanceStatus? status,
    DateTime? markedAt,
    String? markedBy,
  }) {
    return AttendanceRecord(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      userLine: userLine ?? this.userLine,
      userVilla: userVilla ?? this.userVilla,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
      markedBy: markedBy ?? this.markedBy,
    );
  }
}
