import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';

class ExpenseModel extends Equatable {
  const ExpenseModel({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
    this.items = const [],
    this.totalAmount,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      startDate: json['start_date'] != null ? (json['start_date'] as Timestamp).toDate().toString() : null,
      endDate: json['end_date'] != null ? (json['end_date'] as Timestamp).toDate().toString() : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ExpenseItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: json['total_amount'] as double?,
      createdAt: json['created_at'] != null ? (json['created_at'] as Timestamp).toDate().toString() : null,
      updatedAt: json['updated_at'] != null ? (json['updated_at'] as Timestamp).toDate().toString() : null,
    );
  }

  final String? id;
  final String? name;
  final String? startDate;
  final String? endDate;
  final List<ExpenseItemModel> items;
  final double? totalAmount;
  final String? createdAt;
  final String? updatedAt;

  ExpenseModel copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    List<ExpenseItemModel>? items,
    double? totalAmount,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'items': items.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        startDate,
        endDate,
        items,
        totalAmount,
        createdAt,
        updatedAt,
      ];
}
