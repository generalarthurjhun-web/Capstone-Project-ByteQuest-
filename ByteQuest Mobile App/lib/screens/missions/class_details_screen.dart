import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../data/missions_data.dart';
import '../../models/assigned_activity_model.dart';
import '../../models/learning_resource_model.dart';
import '../../models/mission_model.dart';
import '../../services/authoritative_assessment_service.dart';
import '../simulation/mission_launcher.dart';
import '../resources/resource_viewer_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classId;
  final String classTitle;
  final List<AssignedActivity> assignments;
  final List<LearningResource> resources;

  const ClassDetailsScreen({
    super.key,
    required this.classId,
    required this.classTitle,
    required this.assignments,
    required this.resources,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  final _assessment = AuthoritativeAssessmentService.instance;
  String? _startingId;

  List<AssignedActivity> get _classAssignments => widget.assignments
      .where((item) => item.classId == widget.classId)
      .toList(growable: false);

  List<LearningResource> get _classResources => widget.resources
      .where((item) => item.classId == widget.classId)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            LearnerPageHeader(
              title: widget.classTitle,
              subtitle: 'Authorized class learning space',
              padding: EdgeInsets.zero,
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close class details',
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const SizedBox(height: 14),
            _Summary(
              assignments: _classAssignments.length,
              resources: _classResources.length,
            ),
            const SizedBox(height: 22),
            const LearnerSectionHeader(
              title: 'Assigned learning',
              supportingText: 'Activities shared by your Instructor',
            ),
            const SizedBox(height: 10),
            if (_classAssignments.isEmpty)
              const LearnerSurface(
                child:
                    Text('No activities have been assigned in this class yet.'),
              )
            else
              ..._classAssignments.map(_assignmentCard),
            const SizedBox(height: 22),
            const LearnerSectionHeader(
              title: 'Class resources',
              supportingText: 'Private files shared with this class',
            ),
            const SizedBox(height: 10),
            if (_classResources.isEmpty)
              const LearnerSurface(
                child: Text('No learning resources have been shared yet.'),
              )
            else
              ..._classResources.map(_resourceCard),
          ],
        ),
      ),
    );
  }

  Widget _assignmentCard(AssignedActivity assignment) {
    final starting = _startingId == assignment.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LearnerSurface(
        semanticLabel:
            '${assignment.title}, ${assignment.isAssessment ? 'assessment' : 'practice'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.title, style: AppTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              assignment.isAssessment ? 'Assessment' : 'Practice activity',
              style: AppTheme.labelMedium.copyWith(
                color: assignment.isAssessment
                    ? AppTheme.accentOrange
                    : AppTheme.primaryBlue,
              ),
            ),
            if (assignment.instructions?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(assignment.instructions!, style: AppTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: starting ? null : () => _start(assignment),
                icon: starting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(starting ? 'Starting…' : 'Open activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceCard(LearningResource resource) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LearnerSurface(
        semanticLabel: 'Resource ${resource.title}',
        onTap: () => _openResource(resource),
        child: Row(
          children: [
            const Icon(Icons.folder_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.title, style: AppTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(resource.mimeType ?? 'Learning resource',
                      style: AppTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.visibility_outlined),
          ],
        ),
      ),
    );
  }

  Future<void> _start(AssignedActivity assignment) async {
    setState(() => _startingId = assignment.id);
    try {
      final missionId = assignment.missionId;
      final localMission = _resolveMission(missionId);
      if (localMission == null) {
        throw StateError(
            'This activity has no installed mobile simulation mapping.');
      }
      if (!mounted) return;
      if (assignment.isBypassAccess) {
        // Instructor bypass grants practice access only. Reuse the normal
        // practice launcher and do not create an authoritative attempt.
        _assessment.abandonLocalSession();
        await MissionLauncher.launch(
          context,
          localMission,
          learnerPayload: assignment.learnerPayload,
        );
        return;
      }
      await _assessment.startAttempt(assignment);
      if (!mounted) return;
      await MissionLauncher.launch(
        context,
        localMission,
        learnerPayload: assignment.learnerPayload,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This activity could not be opened. Try again.')),
      );
      debugPrint('Class activity launch failed: $error');
    } finally {
      if (mounted) setState(() => _startingId = null);
    }
  }

  Mission? _resolveMission(String missionId) {
    // Class detail uses the same installed catalog resolver as Learn. Keeping
    // this lookup local avoids creating a second mission data source.
    return MissionsData.getMissionById(missionId);
  }

  Future<void> _openResource(LearningResource resource) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResourceViewerScreen(resource: resource),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int assignments;
  final int resources;

  const _Summary({required this.assignments, required this.resources});

  @override
  Widget build(BuildContext context) => LearnerSurface(
        child: Row(
          children: [
            Expanded(
                child: _Metric(label: 'Activities', value: '$assignments')),
            Expanded(child: _Metric(label: 'Resources', value: '$resources')),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  AppTheme.displaySmall.copyWith(color: AppTheme.primaryBlue)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelMedium),
        ],
      );
}
