import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RecurringExpenseType {
  security,
  electricity,
  water,
  garden,
  cleaning,
  maintenance,
  salary,
  other,
}

enum RecurringFrequency {
  monthly,
  quarterly,
  yearly,
}

class RecurringExpenseModel extends Equatable {
  const RecurringExpenseModel({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.frequency,
    this.description,
    this.vendorName,
    this.contactNumber,
    this.dueDate,
    this.isActive = true,
    this.isPaid = false,
    this.dueMonth,
    this.dueYear,
    this.lastPaidDate,
    this.nextDueDate,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.lineNumber,
  });

  final String? id;
  final String name;
  final double amount;
  final RecurringExpenseType type;
  final RecurringFrequency frequency;
  final String? description;
  final String? vendorName;
  final String? contactNumber;
  final int? dueDate; // Day of month (1-31)
  final bool isActive;
  final bool isPaid; // New field to track if current month is paid
  final int? dueMonth; // Month for which this expense is due
  final int? dueYear; // Year for which this expense is due
  final DateTime? lastPaidDate;
  final DateTime? nextDueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? lineNumber;

  factory RecurringExpenseModel.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: _parseType(json['type'] as String?),
      frequency: _parseFrequency(json['frequency'] as String?),
      description: json['description'] as String?,
      vendorName: json['vendor_name'] as String?,
      contactNumber: json['contact_number'] as String?,
      dueDate: json['due_date'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      isPaid: json['is_paid'] as bool? ?? false,
      dueMonth: json['due_month'] as int?,
      dueYear: json['due_year'] as int?,
      lastPaidDate: _parseDateTime(json['last_paid_date']),
      nextDueDate: _parseDateTime(json['next_due_date']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      createdBy: json['created_by'] as String?,
      lineNumber: json['line_number'] as String?,
    );
  }

  static RecurringExpenseType _parseType(String? type) {
    switch (type) {
      case 'security':
        return RecurringExpenseType.security;
      case 'electricity':
        return RecurringExpenseType.electricity;
      case 'water':
        return RecurringExpenseType.water;
      case 'garden':
        return RecurringExpenseType.garden;
      case 'cleaning':
        return RecurringExpenseType.cleaning;
      case 'maintenance':
        return RecurringExpenseType.maintenance;
      case 'salary':
        return RecurringExpenseType.salary;
      default:
        return RecurringExpenseType.other;
    }
  }

  static RecurringFrequency _parseFrequency(String? frequency) {
    switch (frequency) {
      case 'quarterly':
        return RecurringFrequency.quarterly;
      case 'yearly':
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.monthly;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type.name,
      'frequency': frequency.name,
      'description': description,
      'vendor_name': vendorName,
      'contact_number': contactNumber,
      'due_date': dueDate,
      'is_active': isActive,
      'is_paid': isPaid,
      'due_month': dueMonth,
      'due_year': dueYear,
      'last_paid_date': lastPaidDate != null ? Timestamp.fromDate(lastPaidDate!) : null,
      'next_due_date': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'created_by': createdBy,
      'line_number': lineNumber,
    };
  }

  RecurringExpenseModel copyWith({
    String? id,
    String? name,
    double? amount,
    RecurringExpenseType? type,
    RecurringFrequency? frequency,
    String? description,
    String? vendorName,
    String? contactNumber,
    int? dueDate,
    bool? isActive,
    bool? isPaid,
    int? dueMonth,
    int? dueYear,
    DateTime? lastPaidDate,
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lineNumber,
  }) {
    return RecurringExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      description: description ?? this.description,
      vendorName: vendorName ?? this.vendorName,
      contactNumber: contactNumber ?? this.contactNumber,
      dueDate: dueDate ?? this.dueDate,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
      dueMonth: dueMonth ?? this.dueMonth,
      dueYear: dueYear ?? this.dueYear,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lineNumber: lineNumber ?? this.lineNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amount,
        type,
        frequency,
        description,
        vendorName,
        contactNumber,
        dueDate,
        isActive,
        isPaid,
        dueMonth,
        dueYear,
        lastPaidDate,
        nextDueDate,
        createdAt,
        updatedAt,
        createdBy,
        lineNumber,
      ];
}

// Extension for UI helpers
extension RecurringExpenseTypeExtension on RecurringExpenseType {
  String get displayName {
    switch (this) {
      case RecurringExpenseType.security:
        return 'Security Guard';
      case RecurringExpenseType.electricity:
        return 'Electricity Bill';
      case RecurringExpenseType.water:
        return 'Water Bill';
      case RecurringExpenseType.garden:
        return 'Garden Maintenance';
      case RecurringExpenseType.cleaning:
        return 'Cleaning Service';
      case RecurringExpenseType.maintenance:
        return 'Maintenance Work';
      case RecurringExpenseType.salary:
        return 'Staff Salary';
      case RecurringExpenseType.other:
        return 'Other Expense';
    }
  }

  String get emoji {
    switch (this) {
      case RecurringExpenseType.security:
        return '🛡️';
      case RecurringExpenseType.electricity:
        return '💡';
      case RecurringExpenseType.water:
        return '💧';
      case RecurringExpenseType.garden:
        return '🌱';
      case RecurringExpenseType.cleaning:
        return '🧹';
      case RecurringExpenseType.maintenance:
        return '🔧';
      case RecurringExpenseType.salary:
        return '💰';
      case RecurringExpenseType.other:
        return '📋';
    }
  }
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String get displayName {
    switch (this) {
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}
