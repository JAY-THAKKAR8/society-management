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
    this.checkNumber,
    this.transactionId,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenancePaymentModel.fromJson(Map<String, dynamic> json) {
    // Handle Timestamp conversion safely
    String? convertTimestampToString(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate().toString();
      return null;
    }

    // Safe cast to String
    String? safeString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    try {
      return MaintenancePaymentModel(
        id: safeString(json['id']),
        periodId: safeString(json['period_id']),
        userId: safeString(json['user_id']),
        userName: safeString(json['user_name']),
        userVillaNumber: safeString(json['user_villa_number']),
        userLineNumber: safeString(json['user_line_number']),
        collectedBy: safeString(json['collected_by']),
        collectorName: safeString(json['collector_name']),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
        paymentDate: convertTimestampToString(json['payment_date']),
        paymentMethod: safeString(json['payment_method']),
        status: _statusFromString(safeString(json['status'])),
        notes: safeString(json['notes']),
        receiptNumber: safeString(json['receipt_number']),
        // Handle new fields that might not exist in older records
        checkNumber: safeString(json['check_number']),
        transactionId: safeString(json['transaction_id']),
        createdAt: convertTimestampToString(json['created_at']),
        updatedAt: convertTimestampToString(json['updated_at']),
      );
    } catch (e) {
      // Fallback to a default model if parsing fails
      // Log error but continue with default model
      return const MaintenancePaymentModel(
        status: PaymentStatus.pending,
        amountPaid: 0.0,
      );
    }
  }

  static PaymentStatus _statusFromString(String? status) {
    if (status == null) return PaymentStatus.pending;

    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partially_paid':
        return PaymentStatus.partiallyPaid;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'pending':
        return PaymentStatus.pending;
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
  final String? checkNumber;
  final String? transactionId;
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
    String? checkNumber,
    String? transactionId,
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
      checkNumber: checkNumber ?? this.checkNumber,
      transactionId: transactionId ?? this.transactionId,
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
        'check_number': checkNumber,
        'transaction_id': transactionId,
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
        checkNumber,
        transactionId,
        createdAt,
        updatedAt,
      ];
}
