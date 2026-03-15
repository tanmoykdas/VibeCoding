import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryDark = Color(0xFF158F3F);
  static const Color primaryLight = Color(0xFF4ECB77);
  static const Color income = Color(0xFF1DB954);
  static const Color expense = Color(0xFFE53935);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF252525);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
}

class AppStrings {
  static const String appName = 'Moneyco';
  static const String tagline = 'Your money, your way';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueAsGuest = 'Continue as Guest';
  static const String signOut = 'Sign Out';
  static const String addTransaction = 'Add Transaction';
  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String totalBalance = 'Total Balance';
  static const String totalIncome = 'Total Income';
  static const String totalExpense = 'Total Expense';
  static const String noTransactions = 'No transactions yet';
  static const String noTransactionsSubtitle = 'Tap + to add your first transaction';
  static const String guestMode = 'Guest Mode';
  static const String loginToSync = 'Login to sync your data across devices';
}

class AppConstants {
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Gift',
    'Investment',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Education',
    'Other',
  ];

  static const String localTransactionsKey = 'local_transactions';
  static const String themeModeKey = 'theme_mode';
  static const String monthlyLimitKey = 'monthly_limit';
  static const String dailyGoalKey = 'daily_goal';
}

class CategoryIcons {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.work_rounded;
      case 'freelance':
        return Icons.laptop_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.local_hospital_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'education':
        return Icons.school_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return const Color(0xFF1DB954);
      case 'freelance':
        return const Color(0xFF2196F3);
      case 'business':
        return const Color(0xFF9C27B0);
      case 'gift':
        return const Color(0xFFE91E63);
      case 'investment':
        return const Color(0xFF00BCD4);
      case 'food':
        return const Color(0xFFFF5722);
      case 'transport':
        return const Color(0xFF607D8B);
      case 'shopping':
        return const Color(0xFFFF9800);
      case 'bills':
        return const Color(0xFFF44336);
      case 'health':
        return const Color(0xFF4CAF50);
      case 'entertainment':
        return const Color(0xFF673AB7);
      case 'education':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
