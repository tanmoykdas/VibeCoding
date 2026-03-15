import '../../models/transaction_model.dart';
import '../models/budget_settings.dart';

abstract class TransactionRepository {
  bool get hasMore;

  Stream<List<TransactionModel>> watchTransactions({int limit = 20});

  Future<List<TransactionModel>> fetchMoreTransactions({int limit = 20});

  Future<void> resetPagination();

  Future<void> addTransaction(TransactionModel transaction);

  Future<void> updateTransaction(TransactionModel transaction);

  Future<void> deleteTransaction(String transactionId);

  Future<void> clearAllTransactions();

  Future<void> batchAddTransactions(List<TransactionModel> transactions);

  Future<void> saveBudgetSettings({double? monthlyLimit, double? dailyGoal});

  Future<BudgetSettings> getBudgetSettings();
}
