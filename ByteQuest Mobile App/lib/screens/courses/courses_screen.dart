import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/learner_ui.dart';
import '../../services/mission_database_service.dart';
import '../../models/learner_learning_path_model.dart';
import 'coc_details_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<LearnerCocProjection> _cocModules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCOCs();
  }

  Future<void> _loadCOCs() async {
    try {
      final dbService = MissionDatabaseService();
      final cocModules = await dbService.getLearnerLearningPath();

      if (mounted) {
        setState(() {
          _cocModules = cocModules;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading COCs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'The learning path could not be loaded.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        body: const LearnerLoadingView(label: 'Loading learning path'),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            LearnerPageHeader(
              title: 'Learning path',
              subtitle: 'Released results, assignments, and practice access',
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close learning path',
                icon: const Icon(Icons.close_rounded),
              ),
            ),

            // COC List
            Expanded(
              child: _error != null
                  ? LearnerStateView(
                      icon: Icons.cloud_off_outlined,
                      title: 'Learning path unavailable',
                      message:
                          '${_error!} Check your connection and try again.',
                      actionLabel: 'Try again',
                      onAction: _loadCOCs,
                    )
                  : _cocModules.isEmpty
                      ? const LearnerStateView(
                          icon: Icons.route_outlined,
                          title: 'No learning path yet',
                          message:
                              'Published COC modules will appear here when they are available.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: _cocModules.length,
                          itemBuilder: (context, index) {
                            final coc = _cocModules[index];
                            return _buildCOCCard(context, coc);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCOCCard(BuildContext context, LearnerCocProjection coc) {
    final cocNumber = coc.code.replaceAll('coc', '').replaceAll('COC', '');
    final releasedMissions = coc.releasedMissionCount;
    final totalMissions = coc.missions.length;
    final progress = coc.releasedRatio;

    return SoftCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => COCDetailsScreen(projection: coc),
          ),
        );
      },
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    cocNumber,
                    style: AppTheme.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COC $cocNumber',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coc.title,
                      style: AppTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            coc.description.isEmpty
                ? 'Learn essential skills for this competency'
                : coc.description,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMedium,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.science_outlined,
                        color: AppTheme.primaryBlue, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        coc.assignedMissionCount > 0
                            ? '${coc.assignedMissionCount} assigned activities'
                            : 'Practice catalog available',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$releasedMissions/$totalMissions released',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Instructor-released mission results',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(coc.lifecycleLabel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      coc.lifecycleLabel,
                      style: AppTheme.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(coc.lifecycleLabel),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LearnerProgressBar(
                value: progress,
                semanticLabel:
                    'COC $cocNumber released results, $releasedMissions of $totalMissions missions',
                color: _getStatusColor(coc.lifecycleLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'All results released') return AppTheme.accentGreen;
    if (status == 'In progress') return AppTheme.accentOrange;
    if (status == 'Assigned') return AppTheme.primaryBlue;
    return AppTheme.textMedium;
  }
}
