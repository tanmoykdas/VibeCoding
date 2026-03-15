class TransactionAnalytics {
  final double totalIncome;
  final double totalExpense;
  final double currentMonthExpense;
  final double todayExpense;
  final Map<String, double> expensesByCategory;
  final Map<String, Map<String, double>> monthlyData;

  const TransactionAnalytics({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentMonthExpense,
    required this.todayExpense,
    required this.expensesByCategory,
    required this.monthlyData,
  });

  static const empty = TransactionAnalytics(
    totalIncome: 0,
    totalExpense: 0,
    currentMonthExpense: 0,
    todayExpense: 0,
    expensesByCategory: {},
    monthlyData: {},
  );

  factory TransactionAnalytics.fromMap(Map<String, dynamic> map) {
    return TransactionAnalytics(
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0,
      currentMonthExpense:
          (map['currentMonthExpense'] as num?)?.toDouble() ?? 0,
      todayExpense: (map['todayExpense'] as num?)?.toDouble() ?? 0,
      expensesByCategory:
          (map['expensesByCategory'] as Map<dynamic, dynamic>? ?? const {}).map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
      monthlyData: (map['monthlyData'] as Map<dynamic, dynamic>? ?? const {})
          .map(
            (key, value) => MapEntry(
              key.toString(),
              (value as Map<dynamic, dynamic>).map(
                (innerKey, innerValue) => MapEntry(
                  innerKey.toString(),
                  (innerValue as num).toDouble(),
                ),
              ),
            ),
          ),
    );
  }
}
