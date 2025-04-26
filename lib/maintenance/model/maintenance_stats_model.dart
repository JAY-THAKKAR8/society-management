/// Model class for user maintenance statistics
class UserStatsModel {
  final String userId;
  final String userName;
  final String? villaNumber;
  final String lineNumber;
  double totalAmount;
  double totalPaid;
  final List<PendingPeriodModel> pendingPeriods;

  UserStatsModel({
    required this.userId,
    required this.userName,
    required this.villaNumber,
    required this.lineNumber,
    required this.totalAmount,
    required this.totalPaid,
    required this.pendingPeriods,
  });
}

/// Model class for pending maintenance period
class PendingPeriodModel {
  final String periodId;
  final String periodName;
  final double amount;
  final double amountPaid;
  final DateTime? dueDate;

  PendingPeriodModel({
    required this.periodId,
    required this.periodName,
    required this.amount,
    required this.amountPaid,
    required this.dueDate,
  });
}

/// Model class for line statistics
class LineStatsModel {
  double totalAmount;
  double collectedAmount;
  double pendingAmount;
  int memberCount;
  int paidCount;
  int pendingCount;

  LineStatsModel({
    required this.totalAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.memberCount,
    required this.paidCount,
    required this.pendingCount,
  });
}
