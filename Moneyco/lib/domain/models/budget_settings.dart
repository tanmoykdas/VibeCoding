class BudgetSettings {
  final double? monthlyLimit;
  final double? dailyGoal;

  const BudgetSettings({this.monthlyLimit, this.dailyGoal});

  static const empty = BudgetSettings();
}
