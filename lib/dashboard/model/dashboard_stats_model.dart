import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalMembers;
  final double totalExpenses;
  final double maintenanceCollected;
  final double maintenancePending;
  final int activeMaintenance;
  final String? updatedAt;

  const DashboardStatsModel({
    required this.totalMembers,
    required this.totalExpenses,
    this.maintenanceCollected = 0.0,
    this.maintenancePending = 0.0,
    this.activeMaintenance = 0,
    this.updatedAt,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final timestamp = json['updated_at'] as Timestamp?;
    return DashboardStatsModel(
      totalMembers: json['total_members'] as int? ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      maintenanceCollected: (json['maintenance_collected'] as num?)?.toDouble() ?? 0.0,
      maintenancePending: (json['maintenance_pending'] as num?)?.toDouble() ?? 0.0,
      activeMaintenance: json['active_maintenance'] as int? ?? 0,
      updatedAt: timestamp?.toDate().toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_members': totalMembers,
        'total_expenses': totalExpenses,
        'maintenance_collected': maintenanceCollected,
        'maintenance_pending': maintenancePending,
        'active_maintenance': activeMaintenance,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props =>
      [totalMembers, totalExpenses, maintenanceCollected, maintenancePending, activeMaintenance, updatedAt];
}
