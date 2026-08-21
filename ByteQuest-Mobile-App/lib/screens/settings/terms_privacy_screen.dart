import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Privacy',
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terms of Service
              Text(
                'Terms of Service',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermSection(
                      '1. Acceptance of Terms',
                      'By accessing and using ByteQuest, you accept and agree to be bound by the terms and provision of this agreement.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      '2. Use License',
                      'Permission is granted to temporarily use ByteQuest for personal, non-commercial educational purposes only.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      '3. User Account',
                      'You are responsible for maintaining the confidentiality of your account and password.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      '4. Prohibited Activities',
                      'You may not use the service for any illegal or unauthorized purpose.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Privacy Policy
              Text(
                'Privacy Policy',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermSection(
                      'Information Collection',
                      'We collect information you provide directly, including name, email, and learning progress data.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      'Use of Information',
                      'We use collected information to provide, maintain, and improve our services and educational experience.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      'Data Security',
                      'We implement appropriate security measures to protect your personal information.',
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      'Third-Party Services',
                      'We use Supabase for data storage and authentication. Their privacy policy applies to data they process.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Last Updated
              Center(
                child: Text(
                  'Last updated: January 2026',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textMedium,
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textMedium,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
