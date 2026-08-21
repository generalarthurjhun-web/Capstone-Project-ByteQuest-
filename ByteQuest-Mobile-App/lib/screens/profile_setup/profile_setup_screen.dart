import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

@visibleForTesting
String? resolveProfileSetupFullName(Map<String, dynamic>? userMetadata) {
  final value = userMetadata?['full_name']?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _schoolController = TextEditingController();
  final _sectionController = TextEditingController();

  String? _selectedGoal;
  bool _isLoading = false;

  final List<String> _goals = [
    'Complete CSS NC II Certification',
    'Learn Computer Systems Servicing',
    'Improve Technical Skills',
    'Career Development'
  ];

  @override
  void initState() {
    super.initState();
    _prefillSignedUpName();
    _loadExistingProfile();
  }

  void _prefillSignedUpName() {
    final metadataName = resolveProfileSetupFullName(
      AuthService().currentUser?.userMetadata,
    );
    if (metadataName != null) {
      _fullNameController.text = metadataName;
    }
  }

  Future<void> _loadExistingProfile() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final initialFullName = _fullNameController.text;
    final initialStudentId = _studentIdController.text;
    final initialSchool = _schoolController.text;
    final initialSection = _sectionController.text;

    try {
      final profile = await ProfileService().getProfileByUserId(userId);
      if (!mounted || profile == null) return;

      // Do not overwrite anything the learner typed while the profile request
      // was in flight. The trusted profile is preferred over Auth metadata
      // when the field is still unchanged.
      if (_fullNameController.text == initialFullName &&
          profile.fullName.trim().isNotEmpty) {
        _fullNameController.text = profile.fullName.trim();
      }
      if (_studentIdController.text == initialStudentId &&
          profile.learnerId?.trim().isNotEmpty == true) {
        _studentIdController.text = profile.learnerId!.trim();
      }
      if (_schoolController.text == initialSchool &&
          profile.school?.trim().isNotEmpty == true) {
        _schoolController.text = profile.school!.trim();
      }
      if (_sectionController.text == initialSection &&
          profile.courseSection?.trim().isNotEmpty == true) {
        _sectionController.text = profile.courseSection!.trim();
      }
    } catch (error) {
      // Auth metadata already provides the sign-up name. A profile refresh
      // failure must not block the learner from completing this form.
      debugPrint('Could not prefill existing profile details: $error');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _schoolController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;
      final userEmail = authService.currentUser?.email;

      if (userId == null || userEmail == null) {
        throw Exception('User not logged in');
      }

      // Create profile in Supabase
      final profileService =
          Provider.of<ProfileService>(context, listen: false);
      await profileService.createProfile(
        userId: userId,
        fullName: _fullNameController.text.trim(),
        email: userEmail,
        learnerId: _studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : null,
        school: _schoolController.text.trim().isNotEmpty
            ? _schoolController.text.trim()
            : null,
        courseSection: _sectionController.text.trim().isNotEmpty
            ? _sectionController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: AppTheme.headlineMedium,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            // Add keyboard inset so the focused field/button is never covered
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 1 of 1',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: 1.0,
                              backgroundColor:
                                  AppTheme.primaryBlue.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Upload Profile Picture',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                Text('Full Name', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('profileSetupFullNameField'),
                  controller: _fullNameController,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    helperText: 'Carried over from sign up. You can edit it.',
                    prefixIcon: Icon(Icons.person, color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Student ID
                Text('Student ID', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _studentIdController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your student ID',
                    prefixIcon: Icon(Icons.badge, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),

                // School
                Text('School or Institution', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _schoolController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your school or institution',
                    prefixIcon: Icon(Icons.school, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),

                // Section / Set
                Text('Section or Set', style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('profileSetupSectionField'),
                  controller: _sectionController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: InputDecoration(
                    hintText: 'Enter your section or set',
                    helperText: 'Example: CSS NC II – Section A or Set 1',
                    counterText: '',
                    prefixIcon: Icon(Icons.class_, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),

                // Learning Goal
                Text('Learning Goal / Preferred Track',
                    style: AppTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select your learning goal or track',
                    prefixIcon: Icon(Icons.flag, color: AppTheme.primaryBlue),
                  ),
                  items: _goals.map((goal) {
                    return DropdownMenuItem(
                      value: goal,
                      child: Text(
                        goal,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGoal = value;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Save Button
                AppButton.primary(
                  label: 'Save & Continue',
                  onPressed: _handleSaveProfile,
                  suffixIcon: Icons.arrow_forward,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Skip for now
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.accentGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can update your profile anytime in settings.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
