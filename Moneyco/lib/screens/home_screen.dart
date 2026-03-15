import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      context.read<TransactionProvider>().loadMoreTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final theme = Theme.of(context);
    final hasDailyGoal = (txProvider.dailyGoal ?? 0) > 0;
    final hasMonthlyLimit = (txProvider.monthlyLimit ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'app-logo-hero',
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: txProvider.isLoading && txProvider.transactions.isEmpty
          ? const HomeLoadingShimmer()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => txProvider.reload(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          height: connectivityProvider.isOffline ? 38 : 0,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withAlpha(90),
                            ),
                          ),
                          child: connectivityProvider.isOffline
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.wifi_off_rounded,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Offline mode. Changes will sync when connection returns.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        SizedBox(
                          height: connectivityProvider.isOffline ? 12 : 0,
                        ),
                        // Greeting
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              Text(
                                authProvider.isLoggedIn
                                    ? (authProvider.userDisplayName ?? 'User')
                                    : 'Guest',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Balance card
                        RepaintBoundary(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.98,
                                    end: 1,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: BalanceCard(
                              key: ValueKey(
                                '${txProvider.totalBalance}-${txProvider.totalIncome}-${txProvider.totalExpense}',
                              ),
                              totalBalance: txProvider.totalBalance,
                              totalIncome: txProvider.totalIncome,
                              totalExpense: txProvider.totalExpense,
                            ),
                          ),
                        ),
                        if (hasDailyGoal || hasMonthlyLimit)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                if (hasDailyGoal)
                                  _DailyGoalProgress(
                                    todayExpense: txProvider.todayExpense,
                                    dailyGoal: txProvider.dailyGoal!,
                                  ),
                                if (hasDailyGoal && hasMonthlyLimit)
                                  const SizedBox(height: 10),
                                if (hasMonthlyLimit)
                                  _MonthlyLimitProgress(
                                    monthExpense:
                                        txProvider.currentMonthExpense,
                                    monthlyLimit: txProvider.monthlyLimit!,
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Transactions',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (txProvider.transactions.isNotEmpty)
                                Text(
                                  '${txProvider.transactions.length} total',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (txProvider.transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tx = txProvider.sortedTransactions[index];
                        return RepaintBoundary(
                          child: TransactionTile(
                            transaction: tx,
                            onDelete: () async {
                              try {
                                await txProvider.deleteTransaction(tx.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Transaction deleted',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                      action: SnackBarAction(
                                        label: 'OK',
                                        textColor: AppColors.primary,
                                        onPressed: () {},
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete: $e',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }, childCount: txProvider.sortedTransactions.length),
                    ),
                  if (txProvider.isFetchingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

class _DailyGoalProgress extends StatelessWidget {
  final double todayExpense;
  final double dailyGoal;

  const _DailyGoalProgress({
    required this.todayExpense,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (todayExpense / dailyGoal).clamp(0.0, 1.0);
    final exceeded = todayExpense > dailyGoal;

    return _BudgetProgressCard(
      title: 'Daily Spend',
      spentAmount: todayExpense,
      limitAmount: dailyGoal,
      progress: progress,
      exceeded: exceeded,
      warningText: exceeded
          ? 'Warning: Daily goal exceeded by ৳${(todayExpense - dailyGoal).toStringAsFixed(0)}.'
          : null,
    );
  }
}

class _MonthlyLimitProgress extends StatelessWidget {
  final double monthExpense;
  final double monthlyLimit;

  const _MonthlyLimitProgress({
    required this.monthExpense,
    required this.monthlyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (monthExpense / monthlyLimit).clamp(0.0, 1.0);
    final exceeded = monthExpense > monthlyLimit;
    final overBy = (monthExpense - monthlyLimit).clamp(0.0, double.infinity);

    return _BudgetProgressCard(
      title: 'Monthly Spend',
      spentAmount: monthExpense,
      limitAmount: monthlyLimit,
      progress: progress,
      exceeded: exceeded,
      warningText: exceeded
          ? 'Warning: Monthly limit exceeded by ৳${overBy.toStringAsFixed(0)}.'
          : null,
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final String title;
  final double spentAmount;
  final double limitAmount;
  final double progress;
  final bool exceeded;
  final String? warningText;

  const _BudgetProgressCard({
    required this.title,
    required this.spentAmount,
    required this.limitAmount,
    required this.progress,
    required this.exceeded,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = exceeded
        ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
        : [const Color(0xFF1DB954), const Color(0xFF158F3F)];
    final shadowColor = (exceeded ? AppColors.expense : AppColors.primary)
        .withAlpha(80);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '৳${spentAmount.toStringAsFixed(0)} / ৳${limitAmount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  minHeight: 8,
                  value: animatedValue,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 8),
            Text(
              warningText!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.noTransactions,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noTransactionsSubtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
