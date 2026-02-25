import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryInfo {
  final String key;
  final String label;
  final String emoji;
  final Color color;

  const CategoryInfo({
    required this.key,
    required this.label,
    required this.emoji,
    required this.color,
  });

  static const Map<String, CategoryInfo> _categories = {
    'food': CategoryInfo(key: 'food', label: 'Food & Dining', emoji: '🍔', color: Color(0xFFF97316)),
    'transport': CategoryInfo(key: 'transport', label: 'Transport', emoji: '🚗', color: Color(0xFF3B82F6)),
    'shopping': CategoryInfo(key: 'shopping', label: 'Shopping', emoji: '🛍️', color: Color(0xFFEC4899)),
    'bills': CategoryInfo(key: 'bills', label: 'Bills & Subscriptions', emoji: '📱', color: Color(0xFF8B5CF6)),
    'entertainment': CategoryInfo(key: 'entertainment', label: 'Entertainment', emoji: '🎬', color: Color(0xFFEF4444)),
    'health': CategoryInfo(key: 'health', label: 'Health & Fitness', emoji: '💊', color: Color(0xFF10B981)),
    'education': CategoryInfo(key: 'education', label: 'Education', emoji: '📚', color: Color(0xFF06B6D4)),
    'savings': CategoryInfo(key: 'savings', label: 'Savings', emoji: '💰', color: Color(0xFF22C55E)),
    'other': CategoryInfo(key: 'other', label: 'Other', emoji: '📦', color: Color(0xFF94A3B8)),
  };

  static CategoryInfo getCategory(String key) {
    return _categories[key.toLowerCase()] ??
        CategoryInfo(key: key, label: _capitalize(key), emoji: '📦', color: AppColors.textMuted);
  }

  static List<CategoryInfo> get allCategories => _categories.values.toList();

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
