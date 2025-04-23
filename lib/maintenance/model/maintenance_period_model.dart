import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a maintenance collection period
class MaintenancePeriodModel extends Equatable {
  const MaintenancePeriodModel({
    this.id,
    this.name,
    this.description,
    this.amount,
    this.startDate,
    this.endDate,
    this.dueDate,
    this.isActive = true,
    this.totalCollected = 0.0,
    this.totalPending = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenancePeriodModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePeriodModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null 
          ? (json['start_date'] as Timestamp).toDate().toString() 
          : null,
      endDate: json['end_date'] != null 
          ? (json['end_date'] as Timestamp).toDate().toString() 
          : null,
      dueDate: json['due_date'] != null 
          ? (json['due_date'] as Timestamp).toDate().toString() 
          : null,
      isActive: json['is_active'] as bool? ?? true,
      totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0.0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? (json['created_at'] as Timestamp).toDate().toString() 
          : null,
      updatedAt: json['updated_at'] != null 
          ? (json['updated_at'] as Timestamp).toDate().toString() 
          : null,
    );
  }

  final String? id;
  final String? name;
  final String? description;
  final double? amount;
  final String? startDate;
  final String? endDate;
  final String? dueDate;
  final bool isActive;
  final double totalCollected;
  final double totalPending;
  final String? createdAt;
  final String? updatedAt;

  MaintenancePeriodModel copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    String? startDate,
    String? endDate,
    String? dueDate,
    bool? isActive,
    double? totalCollected,
    double? totalPending,
    String? createdAt,
    String? updatedAt,
  }) {
    return MaintenancePeriodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dueDate: dueDate ?? this.dueDate,
      isActive: isActive ?? this.isActive,
      totalCollected: totalCollected ?? this.totalCollected,
      totalPending: totalPending ?? this.totalPending,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'amount': amount,
        'start_date': startDate,
        'end_date': endDate,
        'due_date': dueDate,
        'is_active': isActive,
        'total_collected': totalCollected,
        'total_pending': totalPending,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        amount,
        startDate,
        endDate,
        dueDate,
        isActive,
        totalCollected,
        totalPending,
        createdAt,
        updatedAt,
      ];
}
