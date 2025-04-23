import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Payment status enum
enum PaymentStatus {
  pending,
  paid,
  partiallyPaid,
  overdue,
}

/// Represents a maintenance payment by a user
class MaintenancePaymentModel extends Equatable {
  const MaintenancePaymentModel({
    this.id,
    this.periodId,
    this.userId,
    this.userName,
    this.userVillaNumber,
    this.userLineNumber,
    this.collectedBy,
    this.collectorName,
    this.amount,
    this.amountPaid = 0.0,
    this.paymentDate,
    this.paymentMethod,
    this.status = PaymentStatus.pending,
    this.notes,
    this.receiptNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenancePaymentModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePaymentModel(
      id: json['id'] as String?,
      periodId: json['period_id'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      userVillaNumber: json['user_villa_number'] as String?,
      userLineNumber: json['user_line_number'] as String?,
      collectedBy: json['collected_by'] as String?,
      collectorName: json['collector_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] != null 
          ? (json['payment_date'] as Timestamp).toDate().toString() 
          : null,
      paymentMethod: json['payment_method'] as String?,
      status: _statusFromString(json['status'] as String?),
      notes: json['notes'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      createdAt: json['created_at'] != null 
          ? (json['created_at'] as Timestamp).toDate().toString() 
          : null,
      updatedAt: json['updated_at'] != null 
          ? (json['updated_at'] as Timestamp).toDate().toString() 
          : null,
    );
  }

  static PaymentStatus _statusFromString(String? status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partially_paid':
        return PaymentStatus.partiallyPaid;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  static String _statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.partiallyPaid:
        return 'partially_paid';
      case PaymentStatus.overdue:
        return 'overdue';
      case PaymentStatus.pending:
      default:
        return 'pending';
    }
  }

  final String? id;
  final String? periodId;
  final String? userId;
  final String? userName;
  final String? userVillaNumber;
  final String? userLineNumber;
  final String? collectedBy;
  final String? collectorName;
  final double? amount;
  final double amountPaid;
  final String? paymentDate;
  final String? paymentMethod;
  final PaymentStatus status;
  final String? notes;
  final String? receiptNumber;
  final String? createdAt;
  final String? updatedAt;

  MaintenancePaymentModel copyWith({
    String? id,
    String? periodId,
    String? userId,
    String? userName,
    String? userVillaNumber,
    String? userLineNumber,
    String? collectedBy,
    String? collectorName,
    double? amount,
    double? amountPaid,
    String? paymentDate,
    String? paymentMethod,
    PaymentStatus? status,
    String? notes,
    String? receiptNumber,
    String? createdAt,
    String? updatedAt,
  }) {
    return MaintenancePaymentModel(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userVillaNumber: userVillaNumber ?? this.userVillaNumber,
      userLineNumber: userLineNumber ?? this.userLineNumber,
      collectedBy: collectedBy ?? this.collectedBy,
      collectorName: collectorName ?? this.collectorName,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'period_id': periodId,
        'user_id': userId,
        'user_name': userName,
        'user_villa_number': userVillaNumber,
        'user_line_number': userLineNumber,
        'collected_by': collectedBy,
        'collector_name': collectorName,
        'amount': amount,
        'amount_paid': amountPaid,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
        'status': _statusToString(status),
        'notes': notes,
        'receipt_number': receiptNumber,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        periodId,
        userId,
        userName,
        userVillaNumber,
        userLineNumber,
        collectedBy,
        collectorName,
        amount,
        amountPaid,
        paymentDate,
        paymentMethod,
        status,
        notes,
        receiptNumber,
        createdAt,
        updatedAt,
      ];
}
