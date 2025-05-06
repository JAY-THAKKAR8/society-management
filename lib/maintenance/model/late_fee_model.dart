import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a late fee applied to a maintenance payment
class LateFeeModel extends Equatable {
  final String? id;
  final String? paymentId;
  final String? periodId;
  final String? userId;
  final String? userName;
  final double amount;
  final int daysLate;
  final String? appliedDate;
  final bool isPaid;
  final String? paidDate;
  final String? createdAt;
  final String? updatedAt;

  const LateFeeModel({
    this.id,
    this.paymentId,
    this.periodId,
    this.userId,
    this.userName,
    this.amount = 0.0,
    this.daysLate = 0,
    this.appliedDate,
    this.isPaid = false,
    this.paidDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert Firestore timestamp to string
  static String? convertTimestampToString(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    } else if (timestamp is String) {
      return timestamp;
    }
    return null;
  }

  /// Safe string conversion
  static String? safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Create from Firestore document
  factory LateFeeModel.fromJson(Map<String, dynamic> json) {
    try {
      return LateFeeModel(
        id: safeString(json['id']),
        paymentId: safeString(json['payment_id']),
        periodId: safeString(json['period_id']),
        userId: safeString(json['user_id']),
        userName: safeString(json['user_name']),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        daysLate: (json['days_late'] as num?)?.toInt() ?? 0,
        appliedDate: convertTimestampToString(json['applied_date']),
        isPaid: json['is_paid'] as bool? ?? false,
        paidDate: convertTimestampToString(json['paid_date']),
        createdAt: convertTimestampToString(json['created_at']),
        updatedAt: convertTimestampToString(json['updated_at']),
      );
    } catch (e) {
      // Fallback to a default model if parsing fails
      return const LateFeeModel(
        amount: 0.0,
        daysLate: 0,
        isPaid: false,
      );
    }
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_id': paymentId,
        'period_id': periodId,
        'user_id': userId,
        'user_name': userName,
        'amount': amount,
        'days_late': daysLate,
        'applied_date': appliedDate,
        'is_paid': isPaid,
        'paid_date': paidDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Create a copy with updated fields
  LateFeeModel copyWith({
    String? id,
    String? paymentId,
    String? periodId,
    String? userId,
    String? userName,
    double? amount,
    int? daysLate,
    String? appliedDate,
    bool? isPaid,
    String? paidDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return LateFeeModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      periodId: periodId ?? this.periodId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      daysLate: daysLate ?? this.daysLate,
      appliedDate: appliedDate ?? this.appliedDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        paymentId,
        periodId,
        userId,
        userName,
        amount,
        daysLate,
        appliedDate,
        isPaid,
        paidDate,
        createdAt,
        updatedAt,
      ];
}
