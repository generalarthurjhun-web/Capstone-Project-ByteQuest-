import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../splash/splash_screen.dart';
import '../dashboard/main_navigation_screen.dart';
import '../auth/login_screen.dart';

/// Resolves both the Supabase session and the trusted profile lifecycle before
/// entering the Learner application.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _subscription;
  bool _checking = true;
  bool _hasLearnerAccess = false;

  @override
  void initState() {
    super.initState();
    _validateSession();
    _subscription = SupabaseConfig.client.auth.onAuthStateChange.listen((_) {
      _validateSession();
    });
  }

  Future<void> _validateSession() async {
    final hasSession = SupabaseConfig.client.auth.currentSession != null;
    var allowed = false;
    if (hasSession) {
      allowed = await _authService.isAccountActive();
      if (!allowed) await _authService.signOut();
    }
    if (!mounted) return;
    setState(() {
      _hasLearnerAccess = allowed;
      _checking = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const SplashScreen();
    return _hasLearnerAccess
        ? const MainNavigationScreen()
        : const LoginScreen();
  }
}
