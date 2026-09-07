import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Build CSS NC II skills through play',
      description:
          'Complete guided missions and build practical technology skills—one challenge at a time.',
      imagePath: 'assets/images/Onboarding 1.png',
    ),
    OnboardingPage(
      title: 'Learn by making decisions',
      description:
          'Identify, configure, troubleshoot, sequence, match, and place components in interactive simulations.',
      imagePath: 'assets/images/Onboarding 2.png',
    ),
    OnboardingPage(
      title: 'See trusted learning progress',
      description:
          'Review Instructor-released results, criterion feedback, and your growing mission history.',
      imagePath: 'assets/images/Onboarding 3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Logo and Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: Image.asset(
                          'assets/images/ByteQuest Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ByteQuest',
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Skip Button
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed('/get-started');
                      },
                      child: Text(
                        'Skip',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PageView - Takes up the remaining space
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(_pages[index], screenHeight);
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppTheme.primaryBlue,
                      dotColor: AppTheme.textLight.withValues(alpha: 0.3),
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button (floating, no extra card)
                  AppButton.primary(
                    label:
                        _currentPage < _pages.length - 1 ? 'Next' : 'Continue',
                    suffixIcon: Icons.arrow_forward,
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        Navigator.of(context)
                            .pushReplacementNamed('/get-started');
                      }
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page, double screenHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizing
        final availableHeight = constraints.maxHeight;
        final imageHeight = availableHeight * 0.45; // 45% for image

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer at top
              const Spacer(flex: 1),

              // Main Illustration Image
              Flexible(
                flex: 8,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: imageHeight,
                    maxWidth: constraints.maxWidth - 48,
                  ),
                  child: Image.asset(
                    page.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: AppTheme.displaySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMedium,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Spacer at bottom
              const Spacer(flex: 2),
            ],
          ),
        );
      },
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
