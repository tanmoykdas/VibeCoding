import 'dart:async';

import '../../domain/models/budget_settings.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../models/transaction_model.dart';
import '../../services/local_storage_service.dart';

class LocalTransactionRepository implements TransactionRepository {
  final LocalStorageService _localStorageService;
  final StreamController<List<TransactionModel>> _controller =
      StreamController<List<TransactionModel>>.broadcast();

  int _offset = 0;
  bool _hasMore = true;

  LocalTransactionRepository(this._localStorageService);

  @override
  bool get hasMore => _hasMore;

  @override
  Stream<List<TransactionModel>> watchTransactions({int limit = 20}) async* {
    final transactions = await _localStorageService.loadTransactionsPage(
      limit: limit,
      offset: 0,
    );
    _offset = transactions.length;
    _hasMore = transactions.length == limit;
    yield transactions;
    yield* _controller.stream;
  }

  @override
  Future<List<TransactionModel>> fetchMoreTransactions({int limit = 20}) async {
    if (!_hasMore) return const [];
    final nextPage = await _localStorageService.loadTransactionsPage(
      limit: limit,
      offset: _offset,
    );
    _offset += nextPage.length;
    _hasMore = nextPage.length == limit;
    return nextPage;
  }

  @override
  Future<void> resetPagination() async {
    _offset = 0;
    _hasMore = true;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _localStorageService.addTransaction(transaction);
    await _emitFirstPage();
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _localStorageService.updateTransaction(transaction);
    await _emitFirstPage();
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _localStorageService.deleteTransaction(transactionId);
    await _emitFirstPage();
  }

  @override
  Future<void> clearAllTransactions() async {
    await _localStorageService.clearAll();
    _offset = 0;
    _hasMore = false;
    await _emitFirstPage();
  }

  @override
  Future<void> batchAddTransactions(List<TransactionModel> transactions) async {
    for (final transaction in transactions) {
      await _localStorageService.addTransaction(transaction);
    }
    await _emitFirstPage();
  }

  @override
  Future<BudgetSettings> getBudgetSettings() async {
    return BudgetSettings(
      monthlyLimit: await _localStorageService.loadMonthlyLimit(),
      dailyGoal: await _localStorageService.loadDailyGoal(),
    );
  }

  @override
  Future<void> saveBudgetSettings({
    double? monthlyLimit,
    double? dailyGoal,
  }) async {
    if (monthlyLimit != null) {
      await _localStorageService.saveMonthlyLimit(monthlyLimit);
    }
    if (dailyGoal != null) {
      await _localStorageService.saveDailyGoal(dailyGoal);
    }
  }

  Future<void> _emitFirstPage() async {
    final allTransactions = await _localStorageService.loadTransactions();
    final visibleCount = _offset == 0
        ? (allTransactions.length < 20 ? allTransactions.length : 20)
        : (_offset > allTransactions.length ? allTransactions.length : _offset);
    final firstPage = allTransactions
        .take(visibleCount)
        .toList(growable: false);
    _offset = firstPage.length;
    _hasMore = allTransactions.length > firstPage.length;
    _controller.add(firstPage);
  }

  void dispose() {
    _controller.close();
  }
}
