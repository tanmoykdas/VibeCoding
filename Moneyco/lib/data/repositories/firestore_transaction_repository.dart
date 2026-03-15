import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/budget_settings.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final FirestoreService _firestoreService;
  final String uid;

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;

  FirestoreTransactionRepository(this._firestoreService, {required this.uid});

  @override
  bool get hasMore => _hasMore;

  @override
  Stream<List<TransactionModel>> watchTransactions({int limit = 20}) {
    return _firestoreService.watchTransactions(uid, limit: limit).map((data) {
      _lastDocument = data.lastDocument;
      _hasMore = data.hasMore;
      return data.transactions;
    });
  }

  @override
  Future<List<TransactionModel>> fetchMoreTransactions({int limit = 20}) async {
    if (!_hasMore) return const [];

    final data = await _firestoreService.fetchMoreTransactions(
      uid,
      limit: limit,
      startAfter: _lastDocument,
    );
    _lastDocument = data.lastDocument;
    _hasMore = data.hasMore;
    return data.transactions;
  }

  @override
  Future<void> resetPagination() async {
    _lastDocument = null;
    _hasMore = true;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) {
    return _firestoreService.addTransaction(uid, transaction);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) {
    return _firestoreService.updateTransaction(uid, transaction);
  }

  @override
  Future<void> deleteTransaction(String transactionId) {
    return _firestoreService.deleteTransaction(uid, transactionId);
  }

  @override
  Future<void> clearAllTransactions() {
    return _firestoreService.deleteAllTransactions(uid);
  }

  @override
  Future<void> batchAddTransactions(List<TransactionModel> transactions) {
    return _firestoreService.batchAddTransactions(uid, transactions);
  }

  @override
  Future<BudgetSettings> getBudgetSettings() async {
    final settings = await _firestoreService.getBudgetSettings(uid);
    return BudgetSettings(
      monthlyLimit: (settings?['monthlyLimit'] as num?)?.toDouble(),
      dailyGoal: (settings?['dailyGoal'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> saveBudgetSettings({double? monthlyLimit, double? dailyGoal}) {
    return _firestoreService.saveBudgetSettings(
      uid,
      monthlyLimit: monthlyLimit,
      dailyGoal: dailyGoal,
    );
  }
}
