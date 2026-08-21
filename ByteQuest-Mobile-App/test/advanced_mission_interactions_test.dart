import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/interactions/mission_interactions.dart';
import 'package:bytequest/screens/simulation/result_screen.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_controller.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/authoritative_assessment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('diagnostic actions reveal only their configured fact',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    var state = MissionRuntimeState(missionId: 'mission');

    Widget app() => _app(
          TroubleshootingBranchInteraction(
            phase: _troubleshootingPhase,
            state: state,
            onAction: (type, target, value) async {
              actions.add({'type': type, 'target': target, 'value': value});
            },
          ),
        );

    await tester.pumpWidget(app());
    expect(find.text('Workstation cannot reach the gateway.'), findsOneWidget);
    expect(find.text('Link light is inactive.'), findsNothing);
    expect(find.text('Patch lead is disconnected.'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Inspect link light'));
    await tester.pump();
    expect(actions.single['type'], 'diagnostic_action');
    expect(actions.single['target'], 'inspect_link');
    expect(actions.single['value'], {
      'reveals_fact_id': 'link_state',
      'input_method': 'tap',
    });

    state = state.copyWith(revealedFactIds: {'link_state'});
    await tester.pumpWidget(app());
    expect(find.text('Link light is inactive.'), findsOneWidget);
    expect(find.text('Patch lead is disconnected.'), findsNothing);
  });

  testWidgets('correction and retest stay gated by diagnostic runtime state',
      (tester) async {
    var state = MissionRuntimeState(missionId: 'mission');

    Widget app() => _app(
          TroubleshootingBranchInteraction(
            phase: _troubleshootingPhase,
            state: state,
            onAction: (_, __, ___) async {},
          ),
        );

    await tester.pumpWidget(app());
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Apply correction'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Retest connection'),
          )
          .onPressed,
      isNull,
    );

    state = state.copyWith(revealedFactIds: {'link_state', 'cable_state'});
    await tester.pumpWidget(app());
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Apply correction'),
          )
          .onPressed,
      isNotNull,
    );

    state = state.copyWith(
      revealedFactIds: {'link_state', 'cable_state'},
      selectedBranchActionIds: {'replace_patch_lead'},
    );
    await tester.pumpWidget(app());
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Retest connection'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('diagnostic-only phase exposes no correction or retest control',
      (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      _app(
        TroubleshootingBranchInteraction(
          phase: _diagnosticOnlyPhase,
          state: MissionRuntimeState(
            missionId: 'mission',
            revealedFactIds: const {'link_state'},
          ),
          onAction: (type, _, __) async => actions.add(type),
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'Apply correction'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Retest'), findsNothing);
    expect(actions, isEmpty);
  });

  testWidgets('test run renders and completes from persisted runtime state',
      (tester) async {
    final actionTypes = <String>[];
    final phase = _phase(InteractionFamily.testRun);
    var state = MissionRuntimeState(missionId: 'mission');
    Widget app() => _app(
          TestRunInteraction(
            phase: phase,
            state: state,
            onAction: (type, target, value) async {
              actionTypes.add(type);
              state = state.withTestStatus(
                target!,
                MissionTestStatus.values.byName(value['test_status'] as String),
              );
            },
          ),
        );

    await tester.pumpWidget(app());

    await tester.tap(find.widgetWithText(FilledButton, 'Run test'));
    await tester.pumpWidget(app());
    expect(actionTypes, ['test_started']);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Complete test'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(actionTypes, ['test_started']);
    await tester.tap(find.widgetWithText(FilledButton, 'Complete test'));
    await tester.pumpWidget(app());
    expect(actionTypes, ['test_started', 'test_completed']);
    expect(state.testStatusFor(phase.id), MissionTestStatus.completed);
    expect(find.byKey(const ValueKey('test-run-completed')), findsOneWidget);
  });

  testWidgets('runtime reduced motion renders test state immediately',
      (tester) async {
    final actionTypes = <String>[];
    final phase = _phase(InteractionFamily.testRun);
    await tester.pumpWidget(
      _app(
        TestRunInteraction(
          phase: phase,
          state: MissionRuntimeState(missionId: 'mission', reducedMotion: true)
              .withTestStatus(phase.id, MissionTestStatus.running),
          onAction: (type, _, __) async => actionTypes.add(type),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Complete test'));
    expect(actionTypes, ['test_completed']);
  });

  testWidgets('platform disabled animations remove test run motion',
      (tester) async {
    final phase = _phase(InteractionFamily.testRun);
    await tester.pumpWidget(
      _app(
        TestRunInteraction(
          phase: phase,
          state: MissionRuntimeState(missionId: 'mission')
              .withTestStatus(phase.id, MissionTestStatus.running),
          onAction: (_, __, ___) async {},
        ),
        disableAnimations: true,
      ),
    );

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('observation and interpretation preserve learner payloads',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    Future<void> record(
      String type,
      String? target,
      Map<String, dynamic> value,
    ) async {
      actions.add({'type': type, 'target': target, 'value': value});
    }

    await tester.pumpWidget(
      _app(
        ListView(
          children: [
            ObservationInteraction(
              phase: _phase(InteractionFamily.observe, id: 'observe'),
              state: MissionRuntimeState(missionId: 'mission'),
              onAction: record,
            ),
            ResultInterpretationInteraction(
              phase: _phase(InteractionFamily.interpret, id: 'interpret'),
              state: MissionRuntimeState(missionId: 'mission'),
              onAction: record,
            ),
          ],
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('observation-input-observe')),
      'Voltage fluctuates between 4.7 V and 4.9 V.',
    );
    await tester.pump();
    final recordObservation =
        find.widgetWithText(FilledButton, 'Record observation');
    await tester.ensureVisible(recordObservation);
    await tester.tap(recordObservation);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('interpretation-input-interpret')),
      'The reading suggests an unstable supply.',
    );
    await tester.pump();
    final recordInterpretation =
        find.widgetWithText(FilledButton, 'Record interpretation');
    await tester.ensureVisible(recordInterpretation);
    await tester.tap(recordInterpretation);
    await tester.pump();

    expect(actions[0]['value'], {
      'observation': 'Voltage fluctuates between 4.7 V and 4.9 V.',
      'input_method': 'keyboard',
    });
    expect(actions[1]['value'], {
      'interpretation': 'The reading suggests an unstable supply.',
      'input_method': 'keyboard',
    });
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Wrong'), findsNothing);
  });

  testWidgets('observation draft synchronizes when authoritative inputs change',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    var phase = _phase(InteractionFamily.observe, id: 'observe-one');
    var state = MissionRuntimeState(
      missionId: 'mission',
      observations: const {'observe-one': 'Persisted first observation'},
    );
    Widget app() => _app(
          ObservationInteraction(
            phase: phase,
            state: state,
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        );

    await tester.pumpWidget(app());
    await tester.enterText(
      find.byKey(const ValueKey('observation-input-observe-one')),
      'Local unsaved draft',
    );
    await tester.pumpWidget(app());
    expect(find.text('Local unsaved draft'), findsOneWidget);

    state = MissionRuntimeState(
      missionId: 'mission',
      observations: const {'observe-one': 'New authoritative observation'},
    );
    await tester.pumpWidget(app());
    expect(find.text('New authoritative observation'), findsOneWidget);

    phase = _phase(InteractionFamily.observe, id: 'observe-two');
    state = MissionRuntimeState(
      missionId: 'mission',
      observations: const {'observe-two': 'Persisted second observation'},
    );
    await tester.pumpWidget(app());
    expect(find.text('Persisted second observation'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Record observation'));
    await tester.pump();
    expect(actions.single['target'], 'observe-two');
    expect(actions.single['value'], {
      'observation': 'Persisted second observation',
      'input_method': 'keyboard',
    });
  });

  testWidgets(
      'interpretation draft synchronizes when authoritative inputs change',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    var phase = _phase(InteractionFamily.interpret, id: 'interpret-one');
    var state = MissionRuntimeState(
      missionId: 'mission',
      interpretations: const {
        'interpret-one': 'Persisted first interpretation'
      },
    );
    Widget app() => _app(
          ResultInterpretationInteraction(
            phase: phase,
            state: state,
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        );

    await tester.pumpWidget(app());
    await tester.enterText(
      find.byKey(const ValueKey('interpretation-input-interpret-one')),
      'Local unsaved interpretation',
    );
    await tester.pumpWidget(app());
    expect(find.text('Local unsaved interpretation'), findsOneWidget);

    state = MissionRuntimeState(
      missionId: 'mission',
      interpretations: const {
        'interpret-one': 'New authoritative interpretation',
      },
    );
    await tester.pumpWidget(app());
    expect(find.text('New authoritative interpretation'), findsOneWidget);

    phase = _phase(InteractionFamily.interpret, id: 'interpret-two');
    state = MissionRuntimeState(
      missionId: 'mission',
      interpretations: const {
        'interpret-two': 'Persisted second interpretation',
      },
    );
    await tester.pumpWidget(app());
    expect(find.text('Persisted second interpretation'), findsOneWidget);
    await tester
        .tap(find.widgetWithText(FilledButton, 'Record interpretation'));
    await tester.pump();
    expect(actions.single['target'], 'interpret-two');
    expect(actions.single['value'], {
      'interpretation': 'Persisted second interpretation',
      'input_method': 'keyboard',
    });
  });

  testWidgets('scenario decision emits choice and runtime transition',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    MissionRuntimeTransition? transition;
    final state = MissionRuntimeState(missionId: 'mission');
    await tester.pumpWidget(
      _app(
        ScenarioDecisionInteraction(
          phase: _phase(
            InteractionFamily.decide,
            presentation: {
              'choices': [
                {
                  'id': 'isolate_switch',
                  'label': 'Isolate the access switch',
                  'available_action_ids': ['inspect_switch', 'run_loopback'],
                },
              ],
            },
          ),
          state: state,
          onAction: (type, target, value) async {
            actions.add({'type': type, 'target': target, 'value': value});
          },
          onRuntimeTransition: (value) => transition = value,
        ),
      ),
    );

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Isolate the access switch'),
    );
    await tester.pump();
    expect(actions.single['type'], 'scenario_decision');
    expect(actions.single['target'], 'isolate_switch');
    expect(actions.single['value'], {
      'available_action_ids': ['inspect_switch', 'run_loopback'],
      'input_method': 'tap',
    });
    final transitioned = transition!(state);
    expect(transitioned.selectedBranchActionIds, {'isolate_switch'});
    expect(transitioned.configurationValues['available_action_ids'],
        ['inspect_switch', 'run_loopback']);
  });

  testWidgets('catalog correction choices emit stable IDs behind enable gate',
      (tester) async {
    const cases = [
      (
        missionId: 'coc2_m5',
        mechanic: 'apply_network_fix',
        actionId: 'apply_network_fix'
      ),
      (
        missionId: 'coc3_m3',
        mechanic: 'correct_access',
        actionId: 'apply_permission_change'
      ),
      (
        missionId: 'coc4_m2',
        mechanic: 'identify_fault',
        actionId: 'apply_component_repair'
      ),
    ];

    for (final item in cases) {
      final phase = _catalogPhase(item.missionId, item.mechanic);
      final actions = <Map<String, dynamic>>[];
      var state = MissionRuntimeState(missionId: item.missionId);
      var enabled = false;
      Widget app() => _app(
            ScenarioDecisionInteraction(
              phase: phase,
              state: state,
              enabled: enabled,
              onRuntimeTransition: (transition) => state = transition(state),
              onAction: (type, target, value) async => actions.add({
                'type': type,
                'target': target,
                'value': value,
              }),
            ),
          );

      await tester.pumpWidget(app());
      final label = ((phase.presentation['choices'] as List).single
          as Map)['label'] as String;
      final button = find.widgetWithText(OutlinedButton, label);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(actions, isEmpty);

      enabled = true;
      await tester.pumpWidget(app());
      await tester.tap(button);
      await tester.pump();
      expect(actions.single['type'], 'scenario_decision');
      expect(actions.single['target'], item.actionId);
      expect(state.selectedBranchActionIds, contains(item.actionId));

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('catalog retests emit configured action and stable target',
      (tester) async {
    const cases = [
      (
        missionId: 'coc2_m5',
        mechanic: 'retest_network_path',
        target: 'retest_network_path'
      ),
      (
        missionId: 'coc3_m3',
        mechanic: 'retest_client_access',
        target: 'retest_client_access'
      ),
      (
        missionId: 'coc4_m2',
        mechanic: 'repair_and_verify',
        target: 'retest_component'
      ),
    ];

    for (final item in cases) {
      final phase = _catalogPhase(item.missionId, item.mechanic);
      final actions = <Map<String, dynamic>>[];
      var enabled = false;
      var state = MissionRuntimeState(missionId: item.missionId);
      Widget app() => _app(
            TestRunInteraction(
              phase: phase,
              state: state,
              enabled: enabled,
              onAction: (type, target, value) async {
                actions.add({
                  'type': type,
                  'target': target,
                  'value': value,
                });
                state = state.withTestStatus(
                  target!,
                  MissionTestStatus.values.byName(
                    value['test_status'] as String,
                  ),
                );
              },
            ),
          );

      await tester.pumpWidget(app());
      final button = find.widgetWithText(FilledButton, 'Run test');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(actions, isEmpty);

      enabled = true;
      await tester.pumpWidget(app());
      await tester.tap(button);
      await tester.pumpWidget(app());
      expect(actions.first['type'], 'retest_requested');
      expect(actions.first['target'], item.target);
      await tester.tap(find.widgetWithText(FilledButton, 'Complete test'));
      await tester.pumpWidget(app());
      expect(actions.last['type'], 'test_completed');
      expect(actions.last['target'], item.target);
      expect(
        state.testStatusFor(item.target),
        MissionTestStatus.completed,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('review blocks pending and failed evidence', (tester) async {
    var returned = false;
    var confirmed = false;
    await tester.pumpWidget(
      _app(
        EvidenceReviewPanel(
          completedPhaseTitles: const ['Inspect', 'Diagnose'],
          authoritativeEvidenceCount: 4,
          pendingEvidenceCount: 1,
          failedEvidenceCount: 1,
          canSubmit: false,
          onReturn: () => returned = true,
          onConfirm: () => confirmed = true,
        ),
      ),
    );

    expect(find.text('2 completed phases'), findsOneWidget);
    expect(find.text('4 synchronized evidence events'), findsOneWidget);
    expect(find.textContaining('1 pending'), findsOneWidget);
    expect(find.textContaining('1 needs retry'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirm submission'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Return'));
    expect(returned, isTrue);
    expect(confirmed, isFalse);
  });

  testWidgets('review enables explicit confirm only when synchronized',
      (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      _app(
        EvidenceReviewPanel(
          completedPhaseTitles: const ['Inspect', 'Diagnose'],
          authoritativeEvidenceCount: 6,
          pendingEvidenceCount: 0,
          failedEvidenceCount: 0,
          canSubmit: true,
          onReturn: () {},
          onConfirm: () => confirmed = true,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm submission'));
    expect(confirmed, isTrue);
    expect(find.textContaining('score'), findsNothing);
    expect(find.textContaining('outcome'), findsNothing);
  });

  testWidgets('result screen keeps authoritative evidence confirmation flow',
      (tester) async {
    final service = AuthoritativeAssessmentService.forTesting(
      activeSession: AttemptSession(
        attemptId: 'attempt',
        assignmentId: 'assignment',
        assignmentType: 'assessment',
        preferenceScope: 'learner',
        startedAt: DateTime(2026),
        submissionKey: 'submission',
      ),
      rpc: (_, __) async => <String, dynamic>{},
      activeActions: () async => [
        {'sequence_number': 1, 'action_type': 'attempt_started'},
        {
          'sequence_number': 2,
          'action_type': 'object_inspected',
          'target': 'uplink',
        },
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          mission: _mission,
          result: MissionResult(
            missionId: 'mission',
            score: 0,
            percentage: 0,
            passed: false,
            xpEarned: 0,
            timeSpent: 20,
            rating: '',
            competencyStatus: '',
          ),
          assessmentService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review assessment submission'), findsOneWidget);
    expect(find.text('1 synchronized evidence event'), findsOneWidget);
    expect(find.text('Your official result will appear only after release.'),
        findsOneWidget);
    final submit =
        find.widgetWithText(FilledButton, 'Submit recorded evidence');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Submit recorded evidence?'), findsOneWidget);
    expect(find.text('Submit evidence'), findsOneWidget);
  });

  testWidgets('advanced controls remain scrollable with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: EvidenceReviewPanel(
            completedPhaseTitles: const ['Inspect', 'Diagnose', 'Retest'],
            authoritativeEvidenceCount: 8,
            pendingEvidenceCount: 0,
            failedEvidenceCount: 0,
            canSubmit: true,
            onReturn: () {},
            onConfirm: () {},
          ),
        ),
        textScale: 1.8,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.widgetWithText(FilledButton, 'Confirm submission'))
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}

Widget _app(
  Widget child, {
  double textScale = 1,
  bool disableAnimations = false,
}) =>
    MaterialApp(
      builder: (context, value) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: value!,
      ),
      home: Scaffold(body: child),
    );

MissionPhaseDefinition _phase(
  InteractionFamily family, {
  String id = 'phase',
  Map<String, dynamic> presentation = const {},
}) =>
    MissionPhaseDefinition(
      id: id,
      title: 'Technical activity',
      instruction: 'Record technical evidence.',
      primaryInteraction: family,
      presentation: presentation,
    );

final _troubleshootingPhase = _phase(
  InteractionFamily.troubleshoot,
  presentation: {
    'symptom': 'Workstation cannot reach the gateway.',
    'facts': {
      'link_state': 'Link light is inactive.',
      'cable_state': 'Patch lead is disconnected.',
      'root_cause': 'Patch lead is disconnected at the switch.',
    },
    'diagnostic_actions': [
      {
        'id': 'inspect_link',
        'label': 'Inspect link light',
        'reveals_fact_id': 'link_state',
      },
      {
        'id': 'trace_cable',
        'label': 'Trace patch lead',
        'reveals_fact_id': 'cable_state',
      },
    ],
    'required_fact_ids': ['link_state', 'cable_state'],
    'correction': {
      'id': 'replace_patch_lead',
      'label': 'Apply correction',
    },
    'retest': {
      'id': 'retest_connection',
      'label': 'Retest connection',
    },
  },
);

final _diagnosticOnlyPhase = _phase(
  InteractionFamily.troubleshoot,
  presentation: {
    'symptom': 'Workstation cannot reach the gateway.',
    'facts': {
      'link_state': 'Switch port 7 reports link down at 0 Mbps.',
    },
    'diagnostic_actions': [
      {
        'id': 'inspect_link',
        'label': 'Inspect link light',
        'reveals_fact_id': 'link_state',
      },
    ],
    'required_fact_ids': ['link_state'],
  },
);

final _mission = Mission(
  id: 'mission',
  cocId: 'coc1',
  missionCode: 'coc1_m1',
  missionNumber: 1,
  title: 'Diagnose connectivity',
  missionType: MissionType.troubleshooting,
  orderIndex: 1,
);

MissionPhaseDefinition _catalogPhase(String missionId, String mechanic) =>
    MissionSimulationDefinitions.byId(missionId).phases.singleWhere(
          (phase) =>
              (phase.presentation['mechanics'] as List).contains(mechanic),
        );
