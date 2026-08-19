import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please agree to the Terms of Service and Privacy Policy'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    // Sign up with Supabase
    try {
      final response = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if signup was successful
        if (response.user != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Check if email confirmation is required
          if (response.session == null) {
            // Email confirmation required
            _showEmailConfirmationDialog();
          } else {
            // Navigate to profile setup
            Navigator.of(context).pushReplacementNamed('/profile-setup');
          }
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup failed. Please try again.'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Parse error message to provide user-friendly feedback
        String errorMessage = 'Sign up failed. Please try again.';
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('user already registered') ||
            errorStr.contains('email already exists') ||
            errorStr.contains('already registered')) {
          errorMessage =
              'This email is already registered. Please log in instead.';
        } else if (errorStr.contains('invalid email') ||
            errorStr.contains('email address') &&
                errorStr.contains('invalid')) {
          errorMessage = 'Email validation failed. Please check:\n'
              '• Email format is correct\n'
              '• Email confirmation is disabled in Supabase settings\n'
              'Try a different email if the issue persists.';
        } else if (errorStr.contains('password') && errorStr.contains('weak')) {
          errorMessage =
              'Password is too weak. Please use a stronger password.';
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorStr.contains('no host specified')) {
          errorMessage = 'Configuration error. Please contact support.';
        } else if (errorStr.contains('email') && errorStr.contains('confirm')) {
          errorMessage =
              'Email confirmation required. Please check your email inbox.';
        } else if (errorStr.contains('row-level security')) {
          errorMessage =
              'Database permission error. Please contact support or check RLS_FIX_GUIDE.md';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        // Log technical error for debugging
        debugPrint('Sign up error: $e');
      }
    }
  }

  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.email, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            const Text('Verify Your Email'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ve sent a verification link to:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your email and click the verification link to activate your account.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        actions: [
          AppButton.primary(
            label: 'Go to Login',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // System Unit Mascot
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPaleBlue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/System Unit Mascot.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: AppTheme.displaySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your CSS NC II learning journey',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                Text('Full Name', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email
                Text('Email Address', style: AppTheme.labelLarge),
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

                // Password
                Text('Password', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Create a password (min. 6 characters)',
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password
                Text('Confirm Password', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textMedium,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms Checkbox
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _agreedToTerms
                          ? AppTheme.primaryBlue
                          : AppTheme.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: RichText(
                            text: TextSpan(
                              style: AppTheme.bodySmall.copyWith(
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Create Account Button
                AppButton.primary(
                  label: 'Create Account',
                  suffixIcon: Icons.arrow_forward,
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        'Log In',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
