import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double? budgetLimit;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'budget_limit': budgetLimit,
    };
  }

  // Create from database Map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] as int),
      budgetLimit: map['budget_limit'] as double?,
    );
  }
}

// Default categories for the app
class DefaultCategories {
  static final List<Category> all = [
    Category(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: const Color(0xFFFF6B6B),
      budgetLimit: 5000,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: const Color(0xFF4ECDC4),
      budgetLimit: 3000,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: const Color(0xFFFFE66D),
      budgetLimit: 4000,
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt_long,
      color: const Color(0xFF95E1D3),
      budgetLimit: 6000,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: const Color(0xFFF38181),
      budgetLimit: 2000,
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: Icons.local_hospital,
      color: const Color(0xFFAA96DA),
      budgetLimit: 3000,
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: const Color(0xFF6C5CE7),
      budgetLimit: 5000,
    ),
    Category(
      id: 'savings',
      name: 'Savings',
      icon: Icons.savings,
      color: const Color(0xFF00B894),
    ),
    Category(
      id: 'others',
      name: 'Others',
      icon: Icons.more_horiz,
      color: const Color(0xFF636E72),
    ),
  ];

  static Category getById(String id) {
    return all.firstWhere(
      (cat) => cat.id == id,
      orElse: () => all.last, // Return 'Others' as default
    );
  }
}
