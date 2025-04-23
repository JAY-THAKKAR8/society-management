import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ActivityModel extends Equatable {
  final String id;
  final String message;
  final String type; // 'user', 'expense', 'payment', 'notice', etc.
  final DateTime timestamp;

  const ActivityModel({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'] as Timestamp;
    return ActivityModel(
      id: json['id'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      timestamp: timestamp.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'type': type,
    'timestamp': timestamp,
  };

  @override
  List<Object?> get props => [id, message, type, timestamp];
}
