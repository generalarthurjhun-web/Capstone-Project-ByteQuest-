import 'package:bytequest/core/theme/app_theme.dart';
import 'package:bytequest/screens/simulation/components/hotspot_widget.dart';
import 'package:bytequest/screens/simulation/interactions/mission_interactions.dart';
import 'package:bytequest/screens/simulation/mission_simulation_screen.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mission accessibility matrix', () {
    for (final family in InteractionFamily.values) {
      testWidgets('${family.name} has a semantic tap completion path',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final recordedActions = <String>[];
        final interactionCallbacks = <String>[];
        final phase = _phase(family);

        await tester.pumpWidget(
          _interactionHost(
            phase,
            onAction: (type, _, __) async => recordedActions.add(type),
            onInteractionCallback: interactionCallbacks.add,
          ),
        );

        final target = _semanticTarget(family);
        expect(target, findsOneWidget, reason: family.name);
        expect(
          tester
              .getSemantics(target)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
          reason: '${family.name} must not require a drag gesture',
        );

        await _completeWithTaps(tester, family);
        await tester.pump(const Duration(milliseconds: 250));
        if (family == InteractionFamily.review) {
          expect(interactionCallbacks.last, 'submission_confirmed');
        } else {
          expect(
            recordedActions.last,
            _terminalAction(family),
            reason: '${family.name} must reach its terminal action',
          );
        }
        semantics.dispose();
      });
    }

    testWidgets('all interaction families support 2x text in compact layouts',
        (tester) async {
      for (final size in const [Size(320, 568), Size(800, 360)]) {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        for (final family in InteractionFamily.values) {
          await tester.pumpWidget(
            _interactionHost(
              _phase(family, verbose: true),
              textScale: 2,
              onAction: (_, __, ___) async {},
              onInteractionCallback: (_) {},
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${family.name} overflowed at $size with 2x text',
          );
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('every enabled action exposes at least a 48dp tap target',
        (tester) async {
      final semantics = tester.ensureSemantics();
      for (final family in InteractionFamily.values) {
        await tester.pumpWidget(
          _interactionHost(
            _phase(family),
            onAction: (_, __, ___) async {},
            onInteractionCallback: (_) {},
          ),
        );
        await _expectEnabledTapTargetsAtLeast48(
          tester,
          '${family.name}: initial',
        );
        await _completeWithTaps(
          tester,
          family,
          verifyTapTargets: true,
        );
      }
      semantics.dispose();
    });
  });

  group('mission motion matrix', () {
    testWidgets('runtime hotspot state drives a compact completion transition',
        (tester) async {
      final object = SceneObjectDefinition(
        id: 'memory-module',
        label: 'Memory module',
        x: .2,
        y: .2,
        width: .1,
        height: .1,
        hotspotType: 'component',
      );

      await tester.pumpWidget(_hotspotHost(object, HotspotVisualState.neutral));
      await tester.pumpWidget(
        _hotspotHost(object, HotspotVisualState.completed),
      );

      final switcher = tester.widget<AnimatedSwitcher>(
        find.descendant(
          of: find.byType(HotspotWidget),
          matching: find.byType(AnimatedSwitcher),
        ),
      );
      final scale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(HotspotWidget),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(switcher.duration.inMilliseconds, inInclusiveRange(150, 250));
      expect(scale.duration, switcher.duration);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('system reduced motion makes hotspot transitions immediate',
        (tester) async {
      final object = SceneObjectDefinition(
        id: 'status-indicator',
        label: 'Status indicator',
        x: .2,
        y: .2,
        width: .1,
        height: .1,
        hotspotType: 'device',
      );

      await tester.pumpWidget(
        _hotspotHost(
          object,
          HotspotVisualState.completed,
          disableAnimations: true,
        ),
      );

      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
      expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero,
      );
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero,
      );
    });
  });
}

Widget _interactionHost(
  MissionPhaseDefinition phase, {
  required MissionActionCallback onAction,
  required ValueChanged<String> onInteractionCallback,
  double textScale = 1,
}) {
  final initialState =
      MissionRuntimeState.initial('accessibility-mission').copyWith(
    currentPhaseId: phase.id,
  );
  return MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: _MatrixInteractionHarness(
          phase: phase,
          initialState: initialState,
          onAction: onAction,
          onInteractionCallback: onInteractionCallback,
        ),
      ),
    ),
  );
}

class _MatrixInteractionHarness extends StatefulWidget {
  const _MatrixInteractionHarness({
    required this.phase,
    required this.initialState,
    required this.onAction,
    required this.onInteractionCallback,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState initialState;
  final MissionActionCallback onAction;
  final ValueChanged<String> onInteractionCallback;

  @override
  State<_MatrixInteractionHarness> createState() =>
      _MatrixInteractionHarnessState();
}

class _MatrixInteractionHarnessState extends State<_MatrixInteractionHarness> {
  late MissionRuntimeState _state = widget.initialState;

  @override
  Widget build(BuildContext context) => MissionPhaseInteraction(
        phase: widget.phase,
        state: _state,
        onAction: _record,
        onRuntimeTransition: (transition) => setState(() {
          _state = transition(_state);
          widget.onInteractionCallback('runtime_transition');
        }),
        onReturnFromReview: () =>
            widget.onInteractionCallback('review_returned'),
        onConfirmReview: () =>
            widget.onInteractionCallback('submission_confirmed'),
        canSubmit: true,
      );

  Future<void> _record(
    String type,
    String? target,
    Map<String, dynamic> value,
  ) async {
    await widget.onAction(type, target, value);
    if (!mounted) return;
    setState(() => _state = _transition(_state, type, target, value));
  }

  MissionRuntimeState _transition(
    MissionRuntimeState state,
    String type,
    String? target,
    Map<String, dynamic> value,
  ) {
    final testStatus = value['test_status'];
    if (target != null && testStatus is String) {
      return state.withTestStatus(
        target,
        MissionTestStatus.values.byName(testStatus),
      );
    }
    switch (type) {
      case 'placement_attempted':
        final item = value['item_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (item != null &&
            destination != null &&
            value['compatible'] == true) {
          return state.copyWith(
            placements: {...state.placements, item: destination},
          );
        }
        return state;
      case 'diagnostic_action':
        final fact = value['reveals_fact_id'] as String?;
        if (fact != null) {
          return state.copyWith(
            revealedFactIds: {...state.revealedFactIds, fact},
          );
        }
        return state;
      case 'correction_applied':
        if (target != null) {
          return state.copyWith(
            selectedBranchActionIds: {
              ...state.selectedBranchActionIds,
              target,
            },
          );
        }
        return state;
    }
    return state;
  }
}

Widget _hotspotHost(
  SceneObjectDefinition object,
  HotspotVisualState state, {
  bool disableAnimations = false,
}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: HotspotWidget(
              key: const ValueKey('stateful-hotspot'),
              object: object,
              state: state,
              enabled: true,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

Finder _semanticTarget(InteractionFamily family) => switch (family) {
      InteractionFamily.inspect =>
        find.byKey(const ValueKey('inspect-target-device')),
      InteractionFamily.select =>
        find.byKey(const ValueKey('multi-select-confirm')),
      InteractionFamily.tool =>
        find.byKey(const ValueKey('tool-target-device')),
      InteractionFamily.connect =>
        find.byKey(const ValueKey('connection-source-source')),
      InteractionFamily.configure =>
        find.widgetWithText(FilledButton, 'Apply configuration'),
      InteractionFamily.sequence =>
        find.widgetWithIcon(IconButton, Icons.arrow_downward_rounded).first,
      InteractionFamily.match =>
        find.byKey(const ValueKey('matching-source-source')),
      InteractionFamily.place =>
        find.byKey(const ValueKey('placement-item-part')),
      InteractionFamily.troubleshoot =>
        find.widgetWithText(OutlinedButton, 'Inspect link state'),
      InteractionFamily.testRun =>
        find.widgetWithText(FilledButton, 'Run test'),
      InteractionFamily.observe =>
        find.byKey(const ValueKey('observation-input-phase-observe')),
      InteractionFamily.decide =>
        find.widgetWithText(OutlinedButton, 'Isolate the device'),
      InteractionFamily.interpret =>
        find.byKey(const ValueKey('interpretation-input-phase-interpret')),
      InteractionFamily.review =>
        find.widgetWithText(FilledButton, 'Confirm submission'),
    };

Future<void> _completeWithTaps(
  WidgetTester tester,
  InteractionFamily family, {
  bool verifyTapTargets = false,
}) async {
  Future<void> verify(String step) async {
    if (verifyTapTargets) {
      await _expectEnabledTapTargetsAtLeast48(
        tester,
        '${family.name}: $step',
      );
    }
  }

  Future<void> tap(Finder finder, String step) async {
    await verify('before $step');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await verify('after $step');
  }

  await verify('start');
  switch (family) {
    case InteractionFamily.inspect:
      await tap(
        find.byKey(const ValueKey('inspect-target-device')),
        'inspect',
      );
    case InteractionFamily.select:
      await tap(
        find.byKey(const ValueKey('multi-select-device')),
        'select option',
      );
      await tap(
        find.byKey(const ValueKey('multi-select-confirm')),
        'confirm selection',
      );
    case InteractionFamily.tool:
      await tap(
        find.byKey(const ValueKey('tool-target-device')),
        'select tool target',
      );
      await tap(
        find.byKey(const ValueKey('tool-tray-tool-meter')),
        'apply tool',
      );
    case InteractionFamily.connect:
      await tap(
        find.byKey(const ValueKey('connection-source-source')),
        'select connection source',
      );
      await tap(
        find.byKey(const ValueKey('connection-destination-destination')),
        'select connection destination',
      );
    case InteractionFamily.configure:
      await tap(
        find.widgetWithText(FilledButton, 'Apply configuration'),
        'apply configuration',
      );
    case InteractionFamily.sequence:
      await tap(
        find.widgetWithIcon(IconButton, Icons.arrow_downward_rounded).first,
        'move sequence item',
      );
    case InteractionFamily.match:
      await tap(
        find.byKey(const ValueKey('matching-source-source')),
        'select match source',
      );
      await tap(
        find.byKey(const ValueKey('matching-destination-destination')),
        'select match destination',
      );
    case InteractionFamily.place:
      await tap(
        find.byKey(const ValueKey('placement-item-part')),
        'select component',
      );
      await tap(
        find.byKey(const ValueKey('placement-destination-slot')),
        'select placement destination',
      );
      await tap(
        find.byKey(const ValueKey('placement-orientation-upright')),
        'select orientation',
      );
      await tap(
        find.byKey(const ValueKey('placement-place')),
        'place component',
      );
    case InteractionFamily.troubleshoot:
      await tap(
        find.widgetWithText(OutlinedButton, 'Inspect link state'),
        'inspect diagnostic',
      );
      await tap(
        find.widgetWithText(FilledButton, 'Apply cable correction'),
        'apply correction',
      );
      await tap(
        find.widgetWithText(OutlinedButton, 'Retest network path'),
        'retest',
      );
    case InteractionFamily.testRun:
      await tap(
        find.widgetWithText(FilledButton, 'Run test'),
        'start test',
      );
      expect(find.text('Complete test'), findsNothing);
      await tester.pump(AppTheme.simulationTransitionDuration);
      await tester.pump();
      await verify('automatic test completion');
    case InteractionFamily.observe:
      await verify('before observation entry');
      await tester.enterText(
        find.byKey(const ValueKey('observation-input-phase-observe')),
        'Link indicator is dark.',
      );
      await tester.pump();
      await verify('after observation entry');
      await tap(
        find.widgetWithText(FilledButton, 'Record observation'),
        'record observation',
      );
    case InteractionFamily.decide:
      await tap(
        find.widgetWithText(OutlinedButton, 'Isolate the device'),
        'record decision',
      );
    case InteractionFamily.interpret:
      await verify('before interpretation entry');
      await tester.enterText(
        find.byKey(const ValueKey('interpretation-input-phase-interpret')),
        'The interface has no physical link.',
      );
      await tester.pump();
      await verify('after interpretation entry');
      await tap(
        find.widgetWithText(FilledButton, 'Record interpretation'),
        'record interpretation',
      );
    case InteractionFamily.review:
      await tap(
        find.widgetWithText(FilledButton, 'Confirm submission'),
        'confirm submission',
      );
  }
}

String _terminalAction(InteractionFamily family) => switch (family) {
      InteractionFamily.inspect => 'object_inspected',
      InteractionFamily.select => 'selection_confirmed',
      InteractionFamily.tool => 'tool_attempted',
      InteractionFamily.connect => 'connection_created',
      InteractionFamily.configure => 'configuration_applied',
      InteractionFamily.sequence => 'sequence_reordered',
      InteractionFamily.match => 'match_created',
      InteractionFamily.place => 'placement_attempted',
      InteractionFamily.troubleshoot => 'retest_requested',
      InteractionFamily.testRun => 'test_completed',
      InteractionFamily.observe => 'observation_recorded',
      InteractionFamily.decide => 'scenario_decision',
      InteractionFamily.interpret => 'result_interpreted',
      InteractionFamily.review => 'submission_confirmed',
    };

Future<void> _expectEnabledTapTargetsAtLeast48(
  WidgetTester tester,
  String step,
) async {
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: step,
  );
}

MissionPhaseDefinition _phase(
  InteractionFamily family, {
  bool verbose = false,
}) {
  final long = verbose ? ' with a descriptive technical label' : '';
  final presentation = switch (family) {
    InteractionFamily.inspect => {
        'objects': [
          {'id': 'device', 'label': 'Network interface$long'},
        ],
      },
    InteractionFamily.select => {
        'options': [
          {'id': 'device', 'label': 'Network interface$long'},
        ],
      },
    InteractionFamily.tool => {
        'targets': [
          {'id': 'device', 'label': 'Network interface$long'},
        ],
        'tools': [
          {'id': 'meter', 'label': 'Digital multimeter$long'},
        ],
      },
    InteractionFamily.connect || InteractionFamily.match => {
        'sources': [
          {'id': 'source', 'label': 'Workstation network adapter$long'},
        ],
        'destinations': [
          {'id': 'destination', 'label': 'Managed switch access port$long'},
        ],
      },
    InteractionFamily.configure => {
        'fields': [
          {'id': 'address', 'label': 'IPv4 address$long'},
        ],
      },
    InteractionFamily.sequence => {
        'items': [
          {'id': 'inspect', 'label': 'Inspect physical link$long'},
          {'id': 'test', 'label': 'Run connectivity test$long'},
        ],
      },
    InteractionFamily.place => {
        'items': [
          {
            'id': 'part',
            'label': 'Memory module$long',
            'category': 'memory',
            'orientations': ['upright'],
          },
        ],
        'destinations': [
          {
            'id': 'slot',
            'label': 'Primary memory slot$long',
            'accepted_categories': ['memory'],
          },
        ],
      },
    InteractionFamily.troubleshoot => {
        'symptom': 'The workstation cannot reach the configured gateway.',
        'facts': {'link-state': 'The physical link indicator is dark.'},
        'diagnostic_actions': [
          {
            'id': 'inspect-link',
            'label': 'Inspect link state',
            'reveals_fact_id': 'link-state',
          },
        ],
        'required_fact_ids': ['link-state'],
        'correction': {'id': 'apply-fix', 'label': 'Apply cable correction'},
        'retest': {'id': 'retest', 'label': 'Retest network path'},
      },
    InteractionFamily.decide => {
        'choices': [
          {'id': 'isolate', 'label': 'Isolate the device$long'},
        ],
      },
    _ => const <String, dynamic>{},
  };
  return MissionPhaseDefinition(
    id: 'phase-${family.name}',
    title: 'Technical activity$long',
    instruction: 'Complete the required technical evidence.$long',
    primaryInteraction: family,
    presentation: presentation,
  );
}
