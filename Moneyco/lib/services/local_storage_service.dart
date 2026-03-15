import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../core/constants.dart';

class LocalStorageService {
  // Save all transactions
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(
      AppConstants.localTransactionsKey,
      jsonEncode(jsonList),
    );
  }

  // Load all transactions
  Future<List<TransactionModel>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.localTransactionsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TransactionModel>> loadTransactionsPage({
    required int limit,
    int offset = 0,
  }) async {
    final transactions = await loadTransactions();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    if (offset >= transactions.length) return [];

    final end = (offset + limit) > transactions.length
        ? transactions.length
        : offset + limit;
    return transactions.sublist(offset, end);
  }

  // Add a transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    final transactions = await loadTransactions();
    transactions.add(transaction);
    // Sort by date descending
    transactions.sort((a, b) => b.date.compareTo(a.date));
    await saveTransactions(transactions);
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    final transactions = await loadTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      transactions.sort((a, b) => b.date.compareTo(a.date));
      await saveTransactions(transactions);
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    final transactions = await loadTransactions();
    transactions.removeWhere((t) => t.id == transactionId);
    await saveTransactions(transactions);
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.localTransactionsKey);
  }

  // Save theme preference
  Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themeModeKey, isDark);
  }

  // Load theme preference
  Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.themeModeKey) ?? true; // dark by default
  }

  Future<void> saveMonthlyLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.monthlyLimitKey, limit);
  }

  Future<double?> loadMonthlyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppConstants.monthlyLimitKey);
  }

  Future<void> saveDailyGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.dailyGoalKey, goal);
  }

  Future<double?> loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppConstants.dailyGoalKey);
  }
}
