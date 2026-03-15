import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/transaction_provider.dart';
import '../widgets/chart_widget.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _selectedChart = 0; // 0: Bar, 1: Pie, 2: Line

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: txProvider.transactions.isEmpty
          ? _EmptyAnalytics()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stats
                  _SummaryRow(
                    totalIncome: txProvider.totalIncome,
                    totalExpense: txProvider.totalExpense,
                    totalBalance: txProvider.totalBalance,
                  ),
                  const SizedBox(height: 24),

                  // Chart type toggle
                  Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.cardDark
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _ChartTab(
                          label: 'Monthly',
                          icon: Icons.bar_chart_rounded,
                          isSelected: _selectedChart == 0,
                          onTap: () => setState(() => _selectedChart = 0),
                        ),
                        _ChartTab(
                          label: 'Categories',
                          icon: Icons.pie_chart_rounded,
                          isSelected: _selectedChart == 1,
                          onTap: () => setState(() => _selectedChart = 1),
                        ),
                        _ChartTab(
                          label: 'Trend',
                          icon: Icons.show_chart_rounded,
                          isSelected: _selectedChart == 2,
                          onTap: () => setState(() => _selectedChart = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chart title
                  Text(
                    _getChartTitle(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getChartSubtitle(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart
                  RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              theme.brightness == Brightness.dark ? 40 : 10,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          key: ValueKey(_selectedChart),
                          height: _selectedChart == 1 ? 320 : 240,
                          child: _buildChart(txProvider),
                        ),
                      ),
                    ),
                  ),

                  // Legend for bar chart
                  if (_selectedChart == 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: AppColors.income, label: 'Income'),
                        const SizedBox(width: 24),
                        _LegendItem(color: AppColors.expense, label: 'Expense'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Top expenses list
                  if (_selectedChart == 1 &&
                      txProvider.expensesByCategory.isNotEmpty) ...[
                    Text(
                      'Expense Breakdown',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildCategoryList(txProvider),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildChart(TransactionProvider txProvider) {
    switch (_selectedChart) {
      case 0:
        return MonthlyBarChart(monthlyData: txProvider.monthlyData);
      case 1:
        return ExpensePieChart(
          expensesByCategory: txProvider.expensesByCategory,
        );
      case 2:
        return BalanceTrendChart(monthlyData: txProvider.monthlyData);
      default:
        return const SizedBox();
    }
  }

  String _getChartTitle() {
    switch (_selectedChart) {
      case 0:
        return 'Monthly Overview';
      case 1:
        return 'Expense Distribution';
      case 2:
        return 'Balance Trend';
      default:
        return '';
    }
  }

  String _getChartSubtitle() {
    switch (_selectedChart) {
      case 0:
        return 'Income vs Expense by month (last 6 months)';
      case 1:
        return 'How your expenses are distributed';
      case 2:
        return 'Your balance over time';
      default:
        return '';
    }
  }

  List<Widget> _buildCategoryList(TransactionProvider txProvider) {
    final expenses = txProvider.expensesByCategory.entries.toList();
    expenses.sort((a, b) => b.value.compareTo(a.value));
    final total = txProvider.totalExpense;

    return expenses.map((entry) {
      final percentage = total > 0 ? entry.value / total : 0.0;
      final color = CategoryIcons.getCategoryColor(entry.key);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CategoryIcons.getIcon(entry.key),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(entry.value),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(color),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 5,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}% of total expenses',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;

  const _SummaryRow({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Income',
          amount: totalIncome,
          color: AppColors.income,
          icon: Icons.arrow_upward_rounded,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Expense',
          amount: totalExpense,
          color: AppColors.expense,
          icon: Icons.arrow_downward_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChartTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No data yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add transactions to see analytics',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
