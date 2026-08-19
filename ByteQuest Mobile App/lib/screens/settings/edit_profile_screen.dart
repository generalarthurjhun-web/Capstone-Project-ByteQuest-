import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _learnerIdController = TextEditingController();
  final _schoolController = TextEditingController();
  final _courseSectionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;

      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final profileService = ProfileService();
      final profile = await profileService.getProfileByUserId(userId);

      if (profile == null) {
        throw Exception('Profile not found');
      }

      setState(() {
        _fullNameController.text = profile.fullName;
        _learnerIdController.text = profile.learnerId ?? '';
        _schoolController.text = profile.school ?? '';
        _courseSectionController.text = profile.courseSection ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;

      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final profileService = ProfileService();
      await profileService.updateProfile(userId, {
        'full_name': _fullNameController.text.trim(),
        'learner_id': _learnerIdController.text.trim().isEmpty
            ? null
            : _learnerIdController.text.trim(),
        'school': _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
        'course_section': _courseSectionController.text.trim().isEmpty
            ? null
            : _courseSectionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate changes were saved
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _learnerIdController.dispose();
    _schoolController.dispose();
    _courseSectionController.dispose();
    super.dispose();
  }

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
          'Edit Profile',
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Avatar Section
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.primaryBlue,
                                  child: Text(
                                    _fullNameController.text.isNotEmpty
                                        ? _fullNameController.text[0]
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Full Name Field
                          Text(
                            'Full Name *',
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Learner ID Field
                          Text(
                            'Learner ID',
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _learnerIdController,
                            decoration: InputDecoration(
                              hintText: 'Enter your learner ID (optional)',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // School Field
                          Text(
                            'School',
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _schoolController,
                            decoration: InputDecoration(
                              hintText: 'Enter your school (optional)',
                              prefixIcon: Icon(
                                Icons.school_outlined,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Course/Section Field
                          Text(
                            'Course / Section',
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _courseSectionController,
                            decoration: InputDecoration(
                              hintText: 'Enter your course/section (optional)',
                              prefixIcon: Icon(
                                Icons.class_outlined,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          AppButton.primary(
                            label: 'Save Changes',
                            onPressed: _saveChanges,
                            isLoading: _isSaving,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Profile',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: 'Retry',
              onPressed: _loadProfile,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}
