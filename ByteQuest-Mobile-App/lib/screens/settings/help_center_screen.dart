import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _faqs = <({String question, String answer})>[
    (
      question: 'How do I complete a mission?',
      answer:
          'Follow the instructions and complete the task. Practice gives local feedback; an assigned assessment is evaluated and released through your Instructor.',
    ),
    (
      question: 'How is XP calculated?',
      answer:
          'XP is temporarily unavailable until an Admin activates an approved gamification configuration. XP never changes an official competency result.',
    ),
    (
      question: 'What happens if I do not satisfy a mission criterion?',
      answer:
          'You may retry practice activities. Assigned-assessment availability and final competency outcomes are controlled by your class and Instructor.',
    ),
    (
      question: 'How do I unlock new learning content?',
      answer:
          'Your Instructor assigns assessment content and may unlock practice access. An unlock never grants an automatic score or competency result.',
    ),
    (
      question: 'Can I reset my progress?',
      answer:
          'Assessment history is preserved for accountability. Contact your Instructor or authorized ByteQuest administrator if a record needs review.',
    ),
  ];

  String _query = '';

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
          'Help Center',
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
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMedium),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // FAQs
              Text(
                'Frequently Asked Questions',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._filteredFaqs.expand(
                (faq) => [
                  _buildFAQItem(faq.question, faq.answer),
                  const SizedBox(height: 12),
                ],
              ),
              if (_filteredFaqs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No help article matches your search.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Contact Support
              SoftCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Still need help?',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact our support team',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact your class Instructor or an authorized ByteQuest administrator through your school’s established support channel.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMedium,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<({String question, String answer})> get _filteredFaqs {
    final query = _query.toLowerCase();
    if (query.isEmpty) return _faqs;
    return _faqs
        .where((faq) =>
            faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Widget _buildFAQItem(String question, String answer) {
    return SoftCard(
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
          title: Text(
            question,
            style: AppTheme.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
