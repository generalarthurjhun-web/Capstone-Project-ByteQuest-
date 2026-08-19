import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/get_started_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/dashboard/main_navigation_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/edit_profile_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/settings/help_center_screen.dart';
import 'screens/settings/terms_privacy_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/mission_service.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/learner_realtime_coordinator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint(
        'Warning: .env file not found. Make sure to create it with Supabase credentials.');
  }

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ByteQuestApp());
}

class ByteQuestApp extends StatelessWidget {
  const ByteQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => MissionService()),
        ChangeNotifierProvider(create: (_) => LearnerRealtimeCoordinator()),
      ],
      child: MaterialApp(
        title: 'ByteQuest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/get-started': (context) => const GetStartedScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/profile-setup': (context) => const ProfileSetupScreen(),
          '/dashboard': (context) => const MainNavigationScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
          '/help-center': (context) => const HelpCenterScreen(),
          '/terms-privacy': (context) => const TermsPrivacyScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/achievements': (context) => const AchievementsScreen(),
        },
      ),
    );
  }
}
