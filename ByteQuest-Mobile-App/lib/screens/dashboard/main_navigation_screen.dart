import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/supabase_config.dart';
import '../../services/learner_realtime_coordinator.dart';
import '../../widgets/bytequest_bottom_nav.dart';
import 'dashboard_screen.dart';
import '../missions/missions_screen.dart';
import '../progress/progress_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

/// Main learner navigation. IndexedStack preserves active mission/list state
/// while the short cross-fade keeps navigation feeling immediate.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // Home
    const MissionsScreen(), // Missions (merged Courses + Simulation)
    const ProgressScreen(), // Progress
    const LeaderboardScreen(), // Leaderboard (new)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (mounted && userId != null) {
        context.read<LearnerRealtimeCoordinator>().start(userId);
      }
    });
  }

  @override
  void dispose() {
    context.read<LearnerRealtimeCoordinator>().stop();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(
          _screens.length,
          (index) => IgnorePointer(
            ignoring: index != _currentIndex,
            child: AnimatedOpacity(
              opacity: index == _currentIndex ? 1 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: TickerMode(
                enabled: index == _currentIndex,
                child: _screens[index],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ByteQuestBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      extendBody: true,
    );
  }
}
