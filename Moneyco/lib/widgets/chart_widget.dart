import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/utils.dart';

// ─── Bar Chart: Monthly Income vs Expense ────────────────────────────────────

class MonthlyBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyData;

  const MonthlyBarChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const _EmptyChartMessage(message: 'No data to display');
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    final last6 = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    final barGroups = last6.asMap().entries.map((entry) {
      final idx = entry.key;
      final key = entry.value;
      final income = monthlyData[key]?['income'] ?? 0;
      final expense = monthlyData[key]?['expense'] ?? 0;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: income,
            color: AppColors.income,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expense,
            color: AppColors.expense,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();

    double maxY = 0;
    for (final key in last6) {
      final income = monthlyData[key]?['income'] ?? 0;
      final expense = monthlyData[key]?['expense'] ?? 0;
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 4,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                AppUtils.formatCompactCurrency(value),
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= last6.length) return const SizedBox();
                final key = last6[idx];
                final parts = key.split('-');
                final month = int.parse(parts[1]);
                final months = [
                  '',
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec',
                ];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    months[month],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${AppUtils.formatCurrency(rod.toY)}',
                GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Pie Chart: Expenses by Category ─────────────────────────────────────────

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> expensesByCategory;

  const ExpensePieChart({super.key, required this.expensesByCategory});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.expensesByCategory.isEmpty) {
      return const _EmptyChartMessage(message: 'No expense data to display');
    }

    final entries = widget.expensesByCategory.entries.toList();
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    final sections = entries.asMap().entries.map((entry) {
      final idx = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final isTouched = idx == _touchedIndex;
      final percentage = (amount / total * 100);
      final color = CategoryIcons.getCategoryColor(category);

      return PieChartSectionData(
        color: color,
        value: amount,
        title: isTouched ? AppUtils.formatCurrency(amount) : '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(80), blurRadius: 8),
                  ],
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.map((entry) {
            final color = CategoryIcons.getCategoryColor(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Line Chart: Balance Trend ────────────────────────────────────────────────

class BalanceTrendChart extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyData;

  const BalanceTrendChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const _EmptyChartMessage(message: 'No data to display');
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    final last6 = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    double runningBalance = 0;
    final spots = last6.asMap().entries.map((entry) {
      final key = entry.value;
      final income = monthlyData[key]?['income'] ?? 0;
      final expense = monthlyData[key]?['expense'] ?? 0;
      runningBalance += (income - expense);
      return FlSpot(entry.key.toDouble(), runningBalance);
    }).toList();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2;
    minY -= padding;
    maxY += padding;
    if (maxY == minY) {
      maxY += 100;
      minY -= 100;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withAlpha(80),
                  AppColors.primary.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white12, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              getTitlesWidget: (value, meta) => Text(
                AppUtils.formatCompactCurrency(value),
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= last6.length) return const SizedBox();
                final key = last6[idx];
                final parts = key.split('-');
                final month = int.parse(parts[1]);
                final months = [
                  '',
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec',
                ];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    months[month],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Balance\n${AppUtils.formatCurrency(spot.y)}',
                  GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyChartMessage extends StatelessWidget {
  final String message;

  const _EmptyChartMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
