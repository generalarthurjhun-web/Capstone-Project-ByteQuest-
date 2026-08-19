import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final imageHeight = screenHeight * 0.40; // 40% for image

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),

                  // Main Illustration
                  Flexible(
                    flex: 7,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: imageHeight,
                        maxWidth: constraints.maxWidth - 48,
                      ),
                      child: Image.asset(
                        'assets/images/Onboarding Get Started.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Title
                  Text(
                    'Ready to Start Your\nByteQuest Journey?',
                    textAlign: TextAlign.center,
                    style: AppTheme.displaySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Learn CSS NC II through gamified missions, real-world simulations, and hands-on challenges.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMedium,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Subtitle/Accent Text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'Learn',
                          style: TextStyle(color: AppTheme.primaryBlue),
                        ),
                        TextSpan(
                          text: '. ',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                        TextSpan(
                          text: 'Build',
                          style: TextStyle(color: AppTheme.primaryBlue),
                        ),
                        TextSpan(
                          text: '. ',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                        TextSpan(
                          text: 'Level Up',
                          style: TextStyle(color: AppTheme.accentOrange),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Primary Button - Get Started
                  AppButton.primary(
                    label: 'Get Started',
                    suffixIcon: Icons.arrow_forward,
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/signup');
                    },
                    width: double.infinity,
                  ),

                  const SizedBox(height: 16),

                  // Secondary Button - Already have account
                  AppButton.secondary(
                    label: 'I already have an account',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    width: double.infinity,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
