import 'package:equatable/equatable.dart';

class ExpenseItemModel extends Equatable {
  const ExpenseItemModel({
    this.id,
    this.name,
    this.price,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      price: json['price'] as double?,
    );
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
