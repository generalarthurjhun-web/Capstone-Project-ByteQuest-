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
        final recordedActions = <String>[];
        var interactionCallbacks = 0;
        final phase = _phase(family);

        await tester.pumpWidget(
          _interactionHost(
            phase,
            onAction: (type, _, __) async => recordedActions.add(type),
            onInteractionCallback: () => interactionCallbacks++,
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
        expect(
          recordedActions.isNotEmpty || interactionCallbacks > 0,
          isTrue,
          reason: '${family.name} must complete without dragging',
        );
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
              onInteractionCallback: () {},
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

    testWidgets('representative controls expose at least 48dp tap targets',
        (tester) async {
      for (final family in InteractionFamily.values) {
        await tester.pumpWidget(
          _interactionHost(
            _phase(family),
            onAction: (_, __, ___) async {},
            onInteractionCallback: () {},
          ),
        );
        final target = _semanticTarget(family);
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(48), reason: family.name);
        expect(size.height, greaterThanOrEqualTo(48), reason: family.name);
      }
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
  required VoidCallback onInteractionCallback,
  double textScale = 1,
}) {
  final state = MissionRuntimeState.initial('accessibility-mission').copyWith(
    currentPhaseId: phase.id,
    revealedFactIds: phase.primaryInteraction == InteractionFamily.troubleshoot
        ? const {'link-state'}
        : const {},
    selectedBranchActionIds:
        phase.primaryInteraction == InteractionFamily.troubleshoot
            ? const {'apply-fix'}
            : const {},
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
        child: MissionPhaseInteraction(
          phase: phase,
          state: state,
          onAction: onAction,
          onRuntimeTransition: (_) => onInteractionCallback(),
          onReturnFromReview: onInteractionCallback,
          onConfirmReview: onInteractionCallback,
          canSubmit: true,
        ),
      ),
    ),
  );
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
      InteractionFamily.review => find.widgetWithText(OutlinedButton, 'Return'),
    };

Future<void> _completeWithTaps(
  WidgetTester tester,
  InteractionFamily family,
) async {
  switch (family) {
    case InteractionFamily.inspect:
      await tester.tap(find.byKey(const ValueKey('inspect-target-device')));
    case InteractionFamily.select:
      await tester.tap(find.byKey(const ValueKey('multi-select-device')));
      await tester.tap(find.byKey(const ValueKey('multi-select-confirm')));
    case InteractionFamily.tool:
      await tester.tap(find.byKey(const ValueKey('tool-target-device')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tool-tray-tool-meter')));
    case InteractionFamily.connect:
      await tester.tap(find.byKey(const ValueKey('connection-source-source')));
      await tester.pump();
      await tester.tap(
          find.byKey(const ValueKey('connection-destination-destination')));
    case InteractionFamily.configure:
      await tester
          .tap(find.widgetWithText(FilledButton, 'Apply configuration'));
    case InteractionFamily.sequence:
      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.arrow_downward_rounded).first,
      );
    case InteractionFamily.match:
      await tester.tap(find.byKey(const ValueKey('matching-source-source')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('matching-destination-destination')),
      );
    case InteractionFamily.place:
      await tester.tap(find.byKey(const ValueKey('placement-item-part')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('placement-destination-slot')),
      );
      await tester.tap(
        find.byKey(const ValueKey('placement-orientation-upright')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('placement-place')));
    case InteractionFamily.troubleshoot:
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Inspect link state'),
      );
    case InteractionFamily.testRun:
      await tester.tap(find.widgetWithText(FilledButton, 'Run test'));
    case InteractionFamily.observe:
      await tester.enterText(
        find.byKey(const ValueKey('observation-input-phase-observe')),
        'Link indicator is dark.',
      );
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Record observation'),
      );
    case InteractionFamily.decide:
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Isolate the device'),
      );
    case InteractionFamily.interpret:
      await tester.enterText(
        find.byKey(const ValueKey('interpretation-input-phase-interpret')),
        'The interface has no physical link.',
      );
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Record interpretation'),
      );
    case InteractionFamily.review:
      await tester.tap(find.widgetWithText(OutlinedButton, 'Return'));
  }
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
