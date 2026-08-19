import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/config/supabase_config.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Check authentication and navigate after delay
    _navigationTimer = Timer(
      const Duration(seconds: 3),
      _navigateFromAuthState,
    );
  }

  /// Check if user is logged in and navigate accordingly
  Future<void> _navigateFromAuthState() async {
    if (!mounted) return;

    try {
      // Check if user is already logged in
      final currentUser = SupabaseConfig.currentUser;
      final session = SupabaseConfig.client.auth.currentSession;

      if (currentUser != null && session != null) {
        // A session alone is not sufficient: a deactivated account must not
        // enter the learner shell. AuthService performs the trusted profile
        // state check against Supabase before navigation.
        final isActive = await AuthService().isAccountActive();
        if (!mounted) return;
        if (isActive) {
          debugPrint('Active learner session found: ${currentUser.email}');
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          await AuthService().signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      } else {
        // No active session - go to onboarding
        debugPrint('No active session - showing onboarding');
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      // On error, go to onboarding to be safe
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardWhite,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // System Unit Mascot
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundPaleBlue,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Image.asset(
                          'assets/images/System Unit Mascot.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ByteQuest Logo with Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/ByteQuest Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppConstants.appName,
                            style: AppTheme.displayMedium.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tagline with colored words
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Learn',
                              style: TextStyle(color: AppTheme.primaryBlue),
                            ),
                            const TextSpan(text: '. '),
                            TextSpan(
                              text: 'Build',
                              style: TextStyle(color: AppTheme.primaryBlue),
                            ),
                            const TextSpan(text: '. '),
                            TextSpan(
                              text: 'Level Up',
                              style: TextStyle(color: AppTheme.accentOrange),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Loading Indicator
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      ),
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
}
