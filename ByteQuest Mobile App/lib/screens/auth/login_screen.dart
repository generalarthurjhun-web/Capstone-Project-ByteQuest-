import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final result = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.user != null) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/dashboard', (_) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Parse error message to provide user-friendly feedback
        String errorMessage = 'Login failed. Please try again.';
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('invalid login credentials') ||
            errorStr.contains('invalid email or password')) {
          errorMessage =
              'Invalid email or password. Please check your credentials and try again.';
        } else if (errorStr.contains('email not confirmed')) {
          errorMessage = 'Please verify your email address before logging in.';
        } else if (errorStr.contains('learner accounts only')) {
          errorMessage =
              'Instructor and Administrator accounts must use the web dashboard.';
        } else if (errorStr.contains('not active')) {
          errorMessage =
              'This account is not active. Contact your Instructor or Administrator.';
        } else if (errorStr.contains('profile is missing')) {
          errorMessage =
              'Your account profile is incomplete. Contact an Administrator.';
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorStr.contains('no host specified')) {
          errorMessage = 'Configuration error. Please contact support.';
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Log technical error for debugging
        debugPrint('Login error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Image.asset('assets/images/ByteQuest Logo.png'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ByteQuest',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // System Unit Mascot
                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPaleBlue,
                      borderRadius: AppTheme.radiusXl,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/images/System Unit Mascot.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Welcome Back Title
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: AppTheme.displaySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to continue your learning journey',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Field
                Text(
                  'Email or Username',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                Text(
                  'Password',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textMedium,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.text(
                    label: 'Forgot Password?',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                AppButton.primary(
                  label: 'Log In',
                  suffixIcon: Icons.arrow_forward,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 40),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/signup'),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
