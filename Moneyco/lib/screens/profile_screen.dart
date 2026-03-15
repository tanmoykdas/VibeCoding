import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & user info
            authProvider.isLoggedIn
                ? _AuthenticatedHeader(authProvider: authProvider)
                : _GuestHeader(),

            const SizedBox(height: 32),

            // Stats
            _StatsRow(txProvider: txProvider),

            const SizedBox(height: 32),

            // Settings section
            _SectionTitle(title: 'Account'),
            const SizedBox(height: 12),

            if (!authProvider.isLoggedIn) ...[
              _ActionTile(
                icon: Icons.login_rounded,
                label: 'Sign in with Google',
                subtitle: 'Sync your data across devices',
                iconColor: AppColors.primary,
                onTap: () async {
                  final success = await authProvider.signInWithGoogle();
                  if (!context.mounted) return;

                  if (success) {
                    String? syncWarning;
                    try {
                      await txProvider.migrateLocalToFirestore();
                      await txProvider.reload();
                    } catch (e) {
                      syncWarning = e.toString();
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          syncWarning == null
                              ? 'Signed in successfully!'
                              : 'Signed in, but cloud sync failed.',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        backgroundColor: syncWarning == null
                            ? AppColors.primary
                            : Colors.orange,
                      ),
                    );
                  } else if (authProvider.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sign-in failed: ${authProvider.errorMessage}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        backgroundColor: AppColors.expense,
                      ),
                    );
                    authProvider.clearError();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],

            _ActionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Clear All Data',
              subtitle: authProvider.isLoggedIn
                  ? 'Delete all Firestore transactions'
                  : 'Delete all local transactions',
              iconColor: AppColors.expense,
              onTap: () => _confirmClear(context, txProvider, authProvider),
            ),

            if (authProvider.isLoggedIn) ...[
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                subtitle: 'You can continue as guest',
                iconColor: Colors.orange,
                onTap: () => _confirmSignOut(context, authProvider, txProvider),
              ),
            ],

            const SizedBox(height: 32),
            _SectionTitle(title: 'Budget'),
            const SizedBox(height: 12),
            _BudgetValueTile(
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.primary,
              label: 'Monthly spending limit',
              value: txProvider.monthlyLimit != null
                  ? '৳${txProvider.monthlyLimit!.toStringAsFixed(0)}'
                  : 'Not set',
              onEdit: () => _showAmountInputDialog(
                context: context,
                title: 'Set Monthly Limit',
                initialValue: txProvider.monthlyLimit,
                onSave: txProvider.setMonthlyLimit,
              ),
            ),
            const SizedBox(height: 8),
            _BudgetValueTile(
              icon: Icons.today_rounded,
              iconColor: Colors.orange,
              label: 'Daily expense goal',
              value: txProvider.dailyGoal != null
                  ? '৳${txProvider.dailyGoal!.toStringAsFixed(0)}'
                  : 'Not set',
              onEdit: () => _showAmountInputDialog(
                context: context,
                title: 'Set Daily Goal',
                initialValue: txProvider.dailyGoal,
                onSave: txProvider.setDailyGoal,
              ),
            ),

            const SizedBox(height: 32),
            _SectionTitle(title: 'App'),
            const SizedBox(height: 12),

            _ThemeTile(
              isDarkMode: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.setDarkMode(value),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.info_outline_rounded,
              label: 'About Moneyco',
              subtitle: 'Version 1.0.0',
              iconColor: Colors.blueGrey,
              onTap: () => _showAbout(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    TransactionProvider txProvider,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete all your transactions. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
            ),
            child: Text(
              'Delete All',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (authProvider.isLoggedIn) {
        await txProvider.clearAllFirestoreData();
      } else {
        await txProvider.clearAllLocalData();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All data cleared',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthProvider authProvider,
    TransactionProvider txProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.signOut();
      await txProvider.reload();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      children: [
        Text(
          'A personal money management app that helps you track income and expenses.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _showAmountInputDialog({
    required BuildContext context,
    required String title,
    required double? initialValue,
    required Future<void> Function(double value) onSave,
  }) async {
    final controller = TextEditingController(
      text: initialValue != null ? initialValue.toStringAsFixed(0) : '',
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter amount in taka',
            prefixText: '৳ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) return;
              Navigator.of(ctx).pop(parsed);
            },
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (value != null && context.mounted) {
      await onSave(value);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title updated',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        );
      }
    }
  }
}

class _AuthenticatedHeader extends StatelessWidget {
  final AuthProvider authProvider;

  const _AuthenticatedHeader({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: authProvider.userPhotoUrl != null
                ? Image.network(
                    authProvider.userPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _DefaultAvatar(
                      name: authProvider.userDisplayName,
                    ),
                  )
                : _DefaultAvatar(name: authProvider.userDisplayName),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          authProvider.userDisplayName ?? 'User',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          authProvider.userEmail ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Synced with Google',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String? name;

  const _DefaultAvatar({this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : 'U';
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardDark,
            border: Border.all(color: Colors.grey.shade700, width: 2),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 44,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.guestMode,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.loginToSync,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TransactionProvider txProvider;

  const _StatsRow({required this.txProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${txProvider.transactions.length}',
          label: 'Transactions',
          icon: Icons.receipt_rounded,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '\$${txProvider.totalBalance.toStringAsFixed(0)}',
          label: 'Net Balance',
          icon: Icons.account_balance_wallet_rounded,
          color: txProvider.totalBalance >= 0 ? AppColors.income : AppColors.expense,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.withAlpha(150),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ThemeTile({
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isDarkMode
                      ? 'Tap sun to switch to light mode'
                      : 'Tap moon to switch to dark mode',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDarkMode,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withAlpha(120),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BudgetValueTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _BudgetValueTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
