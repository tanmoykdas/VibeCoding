import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/input_sanitizer.dart';
import '../data/repositories/firestore_transaction_repository.dart';
import '../data/repositories/local_transaction_repository.dart';
import '../domain/models/transaction_analytics.dart';
import '../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class TransactionProvider extends ChangeNotifier {
  static const int _pageSize = 20;

  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;
  final NotificationService _notificationService;
  final AuthProvider _authProvider;
  final _uuid = const Uuid();

  late final LocalTransactionRepository _localRepository;

  TransactionRepository? _activeRepository;
  StreamSubscription<List<TransactionModel>>? _transactionsSub;

  List<TransactionModel> _transactions = [];
  TransactionAnalytics _analytics = TransactionAnalytics.empty;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  double? _monthlyLimit;
  double? _dailyGoal;
  int _analyticsVersion = 0;
  String _activeAuthScope = 'guest';

  TransactionProvider(
    this._firestoreService,
    this._localStorageService,
    this._notificationService,
    this._authProvider,
  ) {
    _localRepository = LocalTransactionRepository(_localStorageService);
    _init();
  }

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<TransactionModel> get sortedTransactions =>
      List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  double? get monthlyLimit => _monthlyLimit;
  double? get dailyGoal => _dailyGoal;
  double get totalIncome => _analytics.totalIncome;
  double get totalExpense => _analytics.totalExpense;
  double get totalBalance => totalIncome - totalExpense;
  double get currentMonthExpense => _analytics.currentMonthExpense;
  double get todayExpense => _analytics.todayExpense;
  Map<String, double> get expensesByCategory => _analytics.expensesByCategory;
  Map<String, Map<String, double>> get monthlyData => _analytics.monthlyData;

  TransactionRepository _resolveRepository() {
    if (_authProvider.isLoggedIn && _authProvider.userId != null) {
      return FirestoreTransactionRepository(
        _firestoreService,
        uid: _authProvider.userId!,
      );
    }
    return _localRepository;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _init() async {
    _activeAuthScope = _currentAuthScope;
    _activeRepository = _resolveRepository();
    await _activeRepository!.resetPagination();
    _hasMore = true;
    _monthlyLimit = 0;
    _dailyGoal = 0;
    await _loadBudgetSettings();
    await _subscribeToTransactions();
  }

  String get _currentAuthScope {
    final userId = _authProvider.userId;
    if (!_authProvider.isLoggedIn || userId == null || userId.isEmpty) {
      return 'guest';
    }
    return 'user:$userId';
  }

  Future<void> syncAuthState() async {
    final nextScope = _currentAuthScope;
    if (nextScope == _activeAuthScope) {
      return;
    }
    await reload();
  }

  Future<void> _loadBudgetSettings() async {
    try {
      final settings = await _activeRepository!.getBudgetSettings();
      _monthlyLimit = settings.monthlyLimit ?? 0;
      _dailyGoal = settings.dailyGoal ?? 0;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _subscribeToTransactions() async {
    _setLoading(true);
    try {
      await _transactionsSub?.cancel();
      _transactionsSub = _activeRepository!
          .watchTransactions(limit: _pageSize)
          .listen(
            (latestTransactions) {
              unawaited(_handleRealtimeUpdate(latestTransactions));
            },
            onError: (Object error) {
              _setError(error.toString());
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> _handleRealtimeUpdate(
    List<TransactionModel> latestTransactions,
  ) async {
    final latestIds = latestTransactions.map((tx) => tx.id).toSet();
    final retainedOlder = _transactions
        .where((tx) => !latestIds.contains(tx.id))
        .toList(growable: false);

    await _replaceTransactions([...latestTransactions, ...retainedOlder]);
    _hasMore = _activeRepository?.hasMore ?? false;
    _isLoading = false;
    notifyListeners();
    unawaited(_runBudgetChecks());
  }

  Future<void> _replaceTransactions(List<TransactionModel> updated) async {
    final sorted = List<TransactionModel>.from(updated)
      ..sort((a, b) => b.date.compareTo(a.date));

    _transactions = sorted;
    final version = ++_analyticsVersion;
    final payload = await compute(
      _buildAnalyticsPayload,
      sorted.map((item) => item.toJson()).toList(growable: false),
    );

    if (version != _analyticsVersion) return;
    _analytics = TransactionAnalytics.fromMap(payload);
  }

  Future<void> loadMoreTransactions() async {
    if (_isLoading ||
        _isFetchingMore ||
        !_hasMore ||
        _activeRepository == null) {
      return;
    }

    _isFetchingMore = true;
    notifyListeners();

    try {
      final nextPage = await _activeRepository!.fetchMoreTransactions(
        limit: _pageSize,
      );

      if (nextPage.isNotEmpty) {
        final map = <String, TransactionModel>{
          for (final tx in _transactions) tx.id: tx,
          for (final tx in nextPage) tx.id: tx,
        };
        await _replaceTransactions(map.values.toList(growable: false));
      }

      _hasMore = _activeRepository!.hasMore;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _transactions = [];
    _analytics = TransactionAnalytics.empty;
    _monthlyLimit = 0;
    _dailyGoal = 0;
    notifyListeners();
    await _init();
  }

  Future<void> setMonthlyLimit(double value) async {
    _monthlyLimit = value;
    notifyListeners();

    try {
      await _activeRepository?.saveBudgetSettings(monthlyLimit: value);
      await _runBudgetChecks();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> setDailyGoal(double value) async {
    _dailyGoal = value;
    notifyListeners();

    try {
      await _activeRepository?.saveBudgetSettings(dailyGoal: value);
      await _runBudgetChecks();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> addTransaction({
    required double amount,
    required String type,
    required String category,
    String? note,
    required DateTime date,
  }) async {
    final transaction = TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      category: InputSanitizer.sanitizeText(category, maxLength: 40),
      note: note == null || note.trim().isEmpty
          ? null
          : InputSanitizer.sanitizeText(note, maxLength: 160),
      date: date,
    );

    final optimistic = <String, TransactionModel>{
      transaction.id: transaction,
      for (final tx in _transactions) tx.id: tx,
    };

    try {
      await _replaceTransactions(optimistic.values.toList(growable: false));
      notifyListeners();
      await _activeRepository!.addTransaction(transaction);
      await _runBudgetChecks();
    } catch (e) {
      _transactions.removeWhere((tx) => tx.id == transaction.id);
      await _replaceTransactions(_transactions);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    final previous = List<TransactionModel>.from(_transactions);

    try {
      _transactions.removeWhere((tx) => tx.id == id);
      await _replaceTransactions(_transactions);
      notifyListeners();
      await _activeRepository!.deleteTransaction(id);
      await _runBudgetChecks();
    } catch (e) {
      await _replaceTransactions(previous);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> migrateLocalToFirestore() async {
    if (!_authProvider.isLoggedIn || _authProvider.userId == null) return;

    final localTransactions = await _localStorageService.loadTransactions();
    if (localTransactions.isEmpty) return;

    try {
      final remoteRepository = FirestoreTransactionRepository(
        _firestoreService,
        uid: _authProvider.userId!,
      );
      await remoteRepository.batchAddTransactions(localTransactions);
      await _localStorageService.clearAll();
      await _localRepository.resetPagination();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> clearAllLocalData() async {
    try {
      await _localRepository.clearAllTransactions();
      await _localRepository.saveBudgetSettings(monthlyLimit: 0, dailyGoal: 0);
      await _replaceTransactions(const []);
      _monthlyLimit = 0;
      _dailyGoal = 0;
      notifyListeners();
      await _runBudgetChecks();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> clearAllFirestoreData() async {
    if (!_authProvider.isLoggedIn || _authProvider.userId == null) return;

    try {
      final remoteRepository = FirestoreTransactionRepository(
        _firestoreService,
        uid: _authProvider.userId!,
      );
      await remoteRepository.clearAllTransactions();
      await _firestoreService.clearBudgetSettings(_authProvider.userId!);
      await _replaceTransactions(const []);
      _monthlyLimit = 0;
      _dailyGoal = 0;
      notifyListeners();
      await _runBudgetChecks();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _runBudgetChecks() async {
    await _notificationService.checkMonthlyLimit(
      transactions: _transactions,
      monthlyLimit: _monthlyLimit,
    );
    await _notificationService.checkDailyGoal(
      transactions: _transactions,
      dailyGoal: _dailyGoal,
    );
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    _localRepository.dispose();
    super.dispose();
  }
}

Map<String, dynamic> _buildAnalyticsPayload(
  List<Map<String, dynamic>> rawItems,
) {
  double totalIncome = 0;
  double totalExpense = 0;
  double currentMonthExpense = 0;
  double todayExpense = 0;
  final expensesByCategory = <String, double>{};
  final monthlyData = <String, Map<String, double>>{};
  final now = DateTime.now();

  for (final item in rawItems) {
    final amount = (item['amount'] as num).toDouble();
    final type = item['type'] as String;
    final category = item['category'] as String;
    final date = DateTime.parse(item['date'] as String);
    final isIncome = type == 'income';
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

    monthlyData[monthKey] ??= {'income': 0, 'expense': 0};
    if (isIncome) {
      totalIncome += amount;
      monthlyData[monthKey]!['income'] =
          (monthlyData[monthKey]!['income'] ?? 0) + amount;
    } else {
      totalExpense += amount;
      monthlyData[monthKey]!['expense'] =
          (monthlyData[monthKey]!['expense'] ?? 0) + amount;
      expensesByCategory[category] =
          (expensesByCategory[category] ?? 0) + amount;

      if (date.year == now.year && date.month == now.month) {
        currentMonthExpense += amount;
      }
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        todayExpense += amount;
      }
    }
  }

  return {
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'currentMonthExpense': currentMonthExpense,
    'todayExpense': todayExpense,
    'expensesByCategory': expensesByCategory,
    'monthlyData': monthlyData,
  };
}
