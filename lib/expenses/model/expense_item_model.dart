import 'package:equatable/equatable.dart';

class ExpenseItemModel extends Equatable {
  const ExpenseItemModel({
    this.id,
    this.name,
    this.price,
  });

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

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseItemModel(
        id: json['id'] as String?,
        name: json['name'] as String?,
        price: json['price'] is int ? (json['price'] as int).toDouble() : json['price'] as double?,
      );
    } catch (e) {
      // Fallback with safer parsing
      return ExpenseItemModel(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        price: _parseAmount(json['price']),
      );
    }
  }

  final String? id;
  final String? name;
  final double? price;

  ExpenseItemModel copyWith({
    String? id,
    String? name,
    double? price,
  }) {
    return ExpenseItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        price,
      ];
}
