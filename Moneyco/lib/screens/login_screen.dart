import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/router/app_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();

    final success = await authProvider.signInWithGoogle();
    if (!context.mounted) return;

    if (success) {
      String? syncWarning;
      try {
        await txProvider.migrateLocalToFirestore();
        if (!context.mounted) return;
        await txProvider.reload();
      } catch (e) {
        syncWarning = e.toString();
      }

      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);

      if (syncWarning != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signed in, but cloud sync failed: $syncWarning',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
  }

  void _continueAsGuest(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B0F), AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      // Logo & App name
                      Hero(
                        tag: 'app-logo-hero',
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(100),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        AppStrings.tagline,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Feature bullets
                      ..._buildFeatureBullets(),
                      const Spacer(flex: 2),
                      // Buttons
                      _GoogleSignInButton(
                        isLoading: authProvider.isLoading,
                        onPressed: () => _signInWithGoogle(context),
                      ),
                      const SizedBox(height: 16),
                      _GuestButton(onPressed: () => _continueAsGuest(context)),
                      const SizedBox(height: 16),
                      Text(
                        'Guest mode stores data locally only',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureBullets() {
    final features = [
      (Icons.sync_rounded, 'Sync across all devices'),
      (Icons.bar_chart_rounded, 'Visual expense analytics'),
      (Icons.security_rounded, 'Secure & private'),
    ];
    return features.map((f) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(f.$1, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              f.$2,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleIcon(),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.continueWithGoogle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;
    final strokeW = w * 0.22;
    final innerR = r - strokeW / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: innerR);

    void arc(double startDeg, double sweepDeg, Color color) {
      const pi = 3.1415926535897932;
      canvas.drawArc(
        rect,
        startDeg * pi / 180,
        sweepDeg * pi / 180,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Draw 4-color ring (Google colors), leaving a gap on the right for the G bar
    arc(-30, 83, const Color(0xFF4285F4)); // Blue top
    arc(90, 120, const Color(0xFFEA4335)); // Red bottom-right
    arc(210, 90, const Color(0xFFFBBC05)); // Yellow bottom-left
    arc(300, 30, const Color(0xFF34A853)); // Green top-left

    // White mask to clear the right-center gap for the G horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(
        cx - strokeW * 0.1,
        cy - strokeW * 0.5,
        r + strokeW * 1.2,
        strokeW,
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Blue G horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - strokeW * 0.38, r * 0.95, strokeW * 0.76),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuestButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GuestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          AppStrings.continueAsGuest,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
