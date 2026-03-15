import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class PaginatedTransactionsResult {
  final List<TransactionModel> transactions;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PaginatedTransactionsResult({
    required this.transactions,
    required this.lastDocument,
    required this.hasMore,
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _transactionsRef(String uid) {
    return _db.collection('users').doc(uid).collection('transactions');
  }

  DocumentReference<Map<String, dynamic>> _monthlyLimitRef(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('monthlyLimit');
  }

  DocumentReference<Map<String, dynamic>> _dailyGoalRef(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('dailyGoal');
  }

  Query<Map<String, dynamic>> _transactionsQuery(String uid) {
    return _transactionsRef(uid).orderBy('date', descending: true);
  }

  Future<void> addTransaction(String uid, TransactionModel transaction) async {
    try {
      await _transactionsRef(
        uid,
      ).doc(transaction.id).set(transaction.toFirestore());
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to add transaction.');
    }
  }

  Future<void> updateTransaction(
    String uid,
    TransactionModel transaction,
  ) async {
    try {
      await _transactionsRef(
        uid,
      ).doc(transaction.id).update(transaction.toFirestore());
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to update transaction.');
    }
  }

  Future<void> deleteTransaction(String uid, String transactionId) async {
    try {
      await _transactionsRef(uid).doc(transactionId).delete();
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to delete transaction.');
    }
  }

  Stream<PaginatedTransactionsResult> watchTransactions(
    String uid, {
    int limit = 20,
  }) {
    return _transactionsQuery(uid).limit(limit).snapshots().map((snapshot) {
      final transactions = snapshot.docs
          .map(TransactionModel.fromFirestore)
          .toList();
      return PaginatedTransactionsResult(
        transactions: transactions,
        lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
        hasMore: snapshot.docs.length == limit,
      );
    });
  }

  Future<PaginatedTransactionsResult> fetchMoreTransactions(
    String uid, {
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _transactionsQuery(uid).limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return PaginatedTransactionsResult(
        transactions: snapshot.docs
            .map(TransactionModel.fromFirestore)
            .toList(),
        lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
        hasMore: snapshot.docs.length == limit,
      );
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to fetch more transactions.');
    }
  }

  Future<void> deleteAllTransactions(String uid) async {
    try {
      final snapshot = await _transactionsRef(uid).get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to clear transactions.');
    }
  }

  Future<void> batchAddTransactions(
    String uid,
    List<TransactionModel> transactions,
  ) async {
    try {
      final batch = _db.batch();
      for (final transaction in transactions) {
        final ref = _transactionsRef(uid).doc(transaction.id);
        batch.set(ref, transaction.toFirestore());
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to migrate transactions.');
    }
  }

  Future<void> saveBudgetSettings(
    String uid, {
    double? monthlyLimit,
    double? dailyGoal,
  }) async {
    try {
      if (monthlyLimit != null) {
        await _monthlyLimitRef(
          uid,
        ).set({'value': monthlyLimit}, SetOptions(merge: true));
      }
      if (dailyGoal != null) {
        await _dailyGoalRef(
          uid,
        ).set({'value': dailyGoal}, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to save budget settings.');
    }
  }

  Future<Map<String, dynamic>?> getBudgetSettings(String uid) async {
    try {
      final monthlyDoc = await _monthlyLimitRef(uid).get();
      final dailyDoc = await _dailyGoalRef(uid).get();

      return {
        if (monthlyDoc.data()?['value'] != null)
          'monthlyLimit': monthlyDoc.data()?['value'],
        if (dailyDoc.data()?['value'] != null)
          'dailyGoal': dailyDoc.data()?['value'],
      };
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to load budget settings.');
    }
  }

  Future<void> clearBudgetSettings(String uid) async {
    try {
      final batch = _db.batch();
      batch.delete(_monthlyLimitRef(uid));
      batch.delete(_dailyGoalRef(uid));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw StateError(e.message ?? 'Failed to clear budget settings.');
    }
  }
}
