import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ExpenseCategoryModel extends Equatable {
  const ExpenseCategoryModel({
    this.id,
    this.name,
    this.description,
    this.iconName,
    this.colorHex,
    this.isCommonExpense = true,
    this.isRecurring = false,
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

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseCategoryModel(
        id: json['id'] as String?,
        name: json['name'] as String?,
        description: json['description'] as String?,
        iconName: json['icon_name'] as String?,
        colorHex: json['color_hex'] as String?,
        isCommonExpense: json['is_common_expense'] as bool? ?? true,
        isRecurring: json['is_recurring'] as bool? ?? false,
        createdAt: _parseTimestamp(json['created_at']),
        updatedAt: _parseTimestamp(json['updated_at']),
      );
    } catch (e) {
      // Fallback with safer parsing
      return ExpenseCategoryModel(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        description: json['description']?.toString(),
        iconName: json['icon_name']?.toString(),
        colorHex: json['color_hex']?.toString(),
        isCommonExpense: json['is_common_expense'] == true,
        isRecurring: json['is_recurring'] == true,
        createdAt: _parseTimestamp(json['created_at']),
        updatedAt: _parseTimestamp(json['updated_at']),
      );
    }
  }

  final String? id;
  final String? name;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final bool isCommonExpense;
  final bool isRecurring;
  final String? createdAt;
  final String? updatedAt;

  ExpenseCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    bool? isCommonExpense,
    bool? isRecurring,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExpenseCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isCommonExpense: isCommonExpense ?? this.isCommonExpense,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon_name': iconName,
        'color_hex': colorHex,
        'is_common_expense': isCommonExpense,
        'is_recurring': isRecurring,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconName,
        colorHex,
        isCommonExpense,
        isRecurring,
        createdAt,
        updatedAt,
      ];

  // Helper method to get the actual color
  Color get color {
    if (colorHex == null) return Colors.blue;
    try {
      return Color(int.parse(colorHex!.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  // Helper method to get the icon
  IconData get icon {
    if (iconName == null) return Icons.category;
    switch (iconName) {
      case 'maintenance':
        return Icons.build;
      case 'utilities':
        return Icons.electric_bolt;
      case 'security':
        return Icons.security;
      case 'events':
        return Icons.event;
      case 'emergency':
        return Icons.emergency;
      case 'infrastructure':
        return Icons.apartment;
      case 'administrative':
        return Icons.admin_panel_settings;
      default:
        return Icons.category;
    }
  }
}
