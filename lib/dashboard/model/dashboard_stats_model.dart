import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalMembers;
  final double totalExpenses;
  final String? updatedAt;

  const DashboardStatsModel({
    required this.totalMembers,
    required this.totalExpenses,
    this.updatedAt,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final timestamp = json['updated_at'] as Timestamp?;
    return DashboardStatsModel(
      totalMembers: json['total_members'] as int? ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      updatedAt: timestamp?.toDate().toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_members': totalMembers,
        'total_expenses': totalExpenses,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [totalMembers, totalExpenses, updatedAt];
}
