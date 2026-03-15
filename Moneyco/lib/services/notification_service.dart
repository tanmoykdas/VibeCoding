import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';

class NotificationService {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  NotificationService(this._scaffoldMessengerKey);

  Future<void> _show({
    required String title,
    required String body,
  }) async {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> checkMonthlyLimit({
    required List<TransactionModel> transactions,
    required double? monthlyLimit,
  }) async {
    if (monthlyLimit == null || monthlyLimit <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final lastMonth = prefs.getString('budget_month_key');
    if (lastMonth != monthKey) {
      await prefs.setString('budget_month_key', monthKey);
      await prefs.setBool('notified_90', false);
      await prefs.setBool('notified_100', false);
    }

    final monthExpense = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    final notified90 = prefs.getBool('notified_90') ?? false;
    final notified100 = prefs.getBool('notified_100') ?? false;

    if (monthExpense >= monthlyLimit && !notified100) {
      await _show(
        title: 'Monthly Limit Exceeded!',
        body: 'You have gone over your budget for this month.',
      );
      await prefs.setBool('notified_100', true);
      await prefs.setBool('notified_90', true);
      return;
    }

    if (monthExpense >= monthlyLimit * 0.9 && !notified90) {
      await _show(
        title: 'Spending Alert',
        body: 'You have used 90% of your monthly budget. Spend carefully!',
      );
      await prefs.setBool('notified_90', true);
    }
  }

  Future<void> checkDailyGoal({
    required List<TransactionModel> transactions,
    required double? dailyGoal,
  }) async {
    if (dailyGoal == null || dailyGoal <= 0) return;

    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final flagKey = 'daily_goal_notified_$todayKey';

    final prefs = await SharedPreferences.getInstance();
    final alreadyNotified = prefs.getBool(flagKey) ?? false;

    final todayExpense = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (todayExpense > dailyGoal && !alreadyNotified) {
      await _show(
        title: 'Daily Goal Exceeded',
        body:
            'You have exceeded your daily spending goal of ${dailyGoal.toStringAsFixed(0)} taka today.',
      );
      await prefs.setBool(flagKey, true);
    }
  }
}
