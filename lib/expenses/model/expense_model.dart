import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:society_management/expenses/model/expense_item_model.dart';

enum ExpensePriority { low, medium, high, critical }

class ExpenseModel extends Equatable {
  const ExpenseModel({
    this.id,
    this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.items = const [],
    this.totalAmount,
    this.categoryId,
    this.categoryName,
    this.lineNumber,
    this.lineName,
    this.vendorName,
    this.receiptUrl,
    this.priority = ExpensePriority.medium,
    this.addedBy,
    this.addedByName,
    this.createdAt,
    this.updatedAt,
  });

  // Helper method to safely parse Timestamp or String to String
  static String? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) {
        return value.toDate().toString();
      } else if (value is String) {
        return value;
      } else {
        return value.toString();
      }
    } catch (e) {
      // Use toString as fallback
      return value.toString();
    }
  }

  // Helper method to safely parse amount values
  static double? _parseAmount(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value);
      } else {
        return null;
      }
    } catch (e) {
      // Return null on parsing error
      return null;
    }
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseModel(
        id: json['id'] as String?,
        name: json['name'] as String?,
        description: json['description'] as String?,
        startDate: _parseTimestamp(json['start_date']),
        endDate: _parseTimestamp(json['end_date']),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ExpenseItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalAmount: _parseAmount(json['total_amount']),
        categoryId: json['category_id'] as String?,
        categoryName: json['category_name'] as String?,
        lineNumber: json['line_number'] as String?,
        lineName: json['line_name'] as String?,
        vendorName: json['vendor_name'] as String?,
        receiptUrl: json['receipt_url'] as String?,
        priority: _priorityFromString(json['priority'] as String?),
        addedBy: json['added_by'] as String?,
        addedByName: json['added_by_name'] as String?,
        createdAt: _parseTimestamp(json['created_at']),
        updatedAt: _parseTimestamp(json['updated_at']),
      );
    } catch (e) {
      // Fallback with safer parsing
      return ExpenseModel(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        description: json['description']?.toString(),
        startDate: _parseTimestamp(json['start_date']),
        endDate: _parseTimestamp(json['end_date']),
        items: const [],
        totalAmount: _parseAmount(json['total_amount']),
        categoryId: json['category_id']?.toString(),
        categoryName: json['category_name']?.toString(),
        lineNumber: json['line_number']?.toString(),
        lineName: json['line_name']?.toString(),
        vendorName: json['vendor_name']?.toString(),
        receiptUrl: json['receipt_url']?.toString(),
        priority: _priorityFromString(json['priority']?.toString()),
        addedBy: json['added_by']?.toString(),
        addedByName: json['added_by_name']?.toString(),
        createdAt: _parseTimestamp(json['created_at']),
        updatedAt: _parseTimestamp(json['updated_at']),
      );
    }
  }

  // Helper methods for priority conversion
  static ExpensePriority _priorityFromString(String? value) {
    switch (value) {
      case 'low':
        return ExpensePriority.low;
      case 'high':
        return ExpensePriority.high;
      case 'critical':
        return ExpensePriority.critical;
      default:
        return ExpensePriority.medium;
    }
  }

  static String _priorityToString(ExpensePriority priority) {
    switch (priority) {
      case ExpensePriority.low:
        return 'low';
      case ExpensePriority.medium:
        return 'medium';
      case ExpensePriority.high:
        return 'high';
      case ExpensePriority.critical:
        return 'critical';
    }
  }

  final String? id;
  final String? name;
  final String? description;
  final String? startDate;
  final String? endDate;
  final List<ExpenseItemModel> items;
  final double? totalAmount;
  final String? categoryId;
  final String? categoryName;
  final String? lineNumber;
  final String? lineName;
  final String? vendorName;
  final String? receiptUrl;
  final ExpensePriority priority;
  final String? addedBy;
  final String? addedByName;
  final String? createdAt;
  final String? updatedAt;

  ExpenseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? startDate,
    String? endDate,
    List<ExpenseItemModel>? items,
    double? totalAmount,
    String? categoryId,
    String? categoryName,
    String? lineNumber,
    String? lineName,
    String? vendorName,
    String? receiptUrl,
    ExpensePriority? priority,
    String? addedBy,
    String? addedByName,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      lineNumber: lineNumber ?? this.lineNumber,
      lineName: lineName ?? this.lineName,
      vendorName: vendorName ?? this.vendorName,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      priority: priority ?? this.priority,
      addedBy: addedBy ?? this.addedBy,
      addedByName: addedByName ?? this.addedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
        'items': items.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'category_id': categoryId,
        'category_name': categoryName,
        'line_number': lineNumber,
        'line_name': lineName,
        'vendor_name': vendorName,
        'receipt_url': receiptUrl,
        'priority': _priorityToString(priority),
        'added_by': addedBy,
        'added_by_name': addedByName,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        startDate,
        endDate,
        items,
        totalAmount,
        categoryId,
        categoryName,
        lineNumber,
        lineName,
        vendorName,
        receiptUrl,
        priority,
        addedBy,
        addedByName,
        createdAt,
        updatedAt,
      ];

  // Helper method to check if this is a common expense
  bool get isCommonExpense => lineNumber == null || lineNumber!.isEmpty;
}
