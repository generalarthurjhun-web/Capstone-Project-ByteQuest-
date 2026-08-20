import 'dart:ui' show Tristate;

import 'package:bytequest/screens/simulation/interactions/mission_interactions.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('incompatible tool attempt records evidence and stable feedback',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    final feedback = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolTray(
            phase: _phase(
              InteractionFamily.tool,
              presentation: {
                'tools': [
                  {
                    'id': 'crimper',
                    'label': 'Crimper',
                    'category': 'termination',
                    'compatible_categories': ['cable'],
                  },
                ],
              },
            ),
            state: MissionRuntimeState.initial('mission'),
            targetId: 'switch',
            targetCategory: 'network_device',
            onFeedbackRequested: feedback.add,
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tool-tray-tool-crimper')));
    await tester.pump();

    expect(actions, hasLength(1));
    expect(actions.single['target'], 'switch');
    expect(actions.single['value'], containsPair('compatible', false));
    expect(actions.single['value'], containsPair('input_method', 'tap'));
    expect(feedback, ['tool_incompatible']);
    expect(find.text('Wrong'), findsNothing);
    expect(find.text('Correct'), findsNothing);
  });

  testWidgets('active tool exposes selected and enabled semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolTray(
            phase: _toolPhase,
            state: MissionRuntimeState(
              missionId: 'mission',
              selectedToolId: 'tester',
            ),
            targetId: 'cable',
            targetCategory: 'test_point',
            onAction: (_, __, ___) async {},
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('tool-tray-tool-tester')),
    );
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    expect(tester.getSize(find.byKey(const ValueKey('tool-tray-tool-tester'))).height,
        greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('tool application requires a selected hotspot target',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    final phase = _phase(
      InteractionFamily.tool,
      presentation: {
        'targets': [
          {'id': 'uplink', 'label': 'Uplink port', 'category': 'port'},
        ],
        'tools': [
          {
            'id': 'tester',
            'label': 'Cable tester',
            'category': 'diagnostic',
            'compatible_categories': ['port'],
          },
        ],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolSelectionInteraction(
            phase: phase,
            state: MissionRuntimeState.initial('mission'),
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        ),
      ),
    );

    final tool = find.byKey(const ValueKey('tool-tray-tool-tester'));
    expect(
      tester.widget<OutlinedButton>(
        find.descendant(of: tool, matching: find.byType(OutlinedButton)),
      ).onPressed,
      isNull,
    );
    expect(actions, isEmpty);

    await tester.tap(find.byKey(const ValueKey('tool-target-uplink')));
    await tester.pump();
    await tester.tap(tool);
    await tester.pump();

    expect(actions, hasLength(1));
    expect(actions.single['type'], 'tool_attempted');
    expect(actions.single['target'], 'uplink');
    expect(actions.single['value'], containsPair('tool_id', 'tester'));
    expect(actions.single['value'], containsPair('input_method', 'tap'));
  });

  testWidgets('multi-select preserves drafts but reconciles a new phase',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    final firstPhase = _phase(
      InteractionFamily.select,
      id: 'first',
      presentation: {
        'options': [
          {'id': 'a', 'label': 'Alpha'},
          {'id': 'b', 'label': 'Beta'},
        ],
      },
    );
    final firstState = MissionRuntimeState(
      missionId: 'mission',
      hotspotStates: const {'a': HotspotVisualState.selected},
    );

    Future<void> pump(MissionPhaseDefinition phase, MissionRuntimeState state) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiSelectInteraction(
                phase: phase,
                state: state,
                onAction: (type, target, value) async => actions.add({
                  'type': type,
                  'target': target,
                  'value': value,
                }),
              ),
            ),
          ),
        );

    await pump(firstPhase, firstState);
    await tester.tap(find.byKey(const ValueKey('multi-select-b')));
    await tester.pump();
    await pump(firstPhase, firstState);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('multi-select-b')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    final secondPhase = _phase(
      InteractionFamily.select,
      id: 'second',
      presentation: {
        'options': [
          {'id': 'c', 'label': 'Gamma'},
        ],
      },
    );
    await pump(
      secondPhase,
      MissionRuntimeState(
        missionId: 'mission',
        hotspotStates: const {'c': HotspotVisualState.selected},
      ),
    );
    expect(find.byKey(const ValueKey('multi-select-b')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('multi-select-confirm')));
    await tester.pump();
    expect(actions.single['target'], 'second');
    expect(actions.single['value'], containsPair('selected_ids', ['c']));
  });

  testWidgets('configuration preserves drafts and reconciles resumed state',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    MissionPhaseDefinition phase(String id) => _phase(
          InteractionFamily.configure,
          id: id,
          presentation: {
            'fields': [
              {'id': 'address', 'label': 'Address', 'type': 'text'},
            ],
          },
        );
    Future<void> pump(
      MissionPhaseDefinition currentPhase,
      MissionRuntimeState state,
    ) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConfigurationPanel(
                phase: currentPhase,
                state: state,
                onAction: (type, target, value) async => actions.add({
                  'type': type,
                  'target': target,
                  'value': value,
                }),
              ),
            ),
          ),
        );

    final firstPhase = phase('first');
    final firstState = MissionRuntimeState(
      missionId: 'mission',
      configurationValues: const {'address': '192.0.2.1'},
    );
    await pump(firstPhase, firstState);
    await tester.enterText(
      find.byKey(const ValueKey('configuration-field-address')),
      'draft-address',
    );
    await pump(firstPhase, firstState);
    expect(find.text('draft-address'), findsOneWidget);

    await pump(
      phase('second'),
      MissionRuntimeState(
        missionId: 'mission',
        configurationValues: const {'address': '198.51.100.8'},
      ),
    );
    expect(find.text('198.51.100.8'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply configuration'));
    await tester.pump();
    expect(actions.single['target'], 'second');
    expect(
      actions.single['value'],
      containsPair('values', {'address': '198.51.100.8'}),
    );
  });

  testWidgets('sequencing preserves drafts but loads consecutive phase order',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    MissionPhaseDefinition phase(
      String id,
      String firstId,
      String secondId,
    ) =>
        _phase(
          InteractionFamily.sequence,
          id: id,
          presentation: {
            'items': [
              {'id': firstId, 'label': firstId.toUpperCase()},
              {'id': secondId, 'label': secondId.toUpperCase()},
            ],
          },
        );
    Future<void> pump(
      MissionPhaseDefinition currentPhase,
      MissionRuntimeState state,
    ) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SequencingInteraction(
                phase: currentPhase,
                state: state,
                onAction: (type, target, value) async => actions.add({
                  'type': type,
                  'target': target,
                  'value': value,
                }),
              ),
            ),
          ),
        );

    final firstPhase = phase('first', 'a', 'b');
    final firstState = MissionRuntimeState(
      missionId: 'mission',
      sequenceOrder: const ['a', 'b'],
    );
    await pump(firstPhase, firstState);
    await tester.tap(find.byTooltip('Move B up'));
    await tester.pump();
    await pump(firstPhase, firstState);
    expect(_sequenceLabels(tester), ['B', 'A']);

    await pump(
      phase('second', 'c', 'd'),
      MissionRuntimeState(
        missionId: 'mission',
        sequenceOrder: const ['d', 'c'],
      ),
    );
    expect(_sequenceLabels(tester), ['D', 'C']);
  });

  testWidgets('connection supports source then destination selection',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectionInteraction(
            phase: _phase(
              InteractionFamily.connect,
              presentation: {
                'sources': [
                  {'id': 'client', 'label': 'Client'},
                ],
                'destinations': [
                  {'id': 'switch', 'label': 'Switch'},
                ],
              },
            ),
            state: MissionRuntimeState.initial('mission'),
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('connection-source-client')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connection-destination-switch')));
    await tester.pump();

    expect(actions, hasLength(1));
    expect(actions.single['target'], 'switch');
    expect(actions.single['value'], {
      'source_id': 'client',
      'destination_id': 'switch',
      'input_method': 'tap',
    });
  });

  testWidgets('controlled placement supports select then Place button',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ControlledPlacementInteraction(
            phase: _phase(
              InteractionFamily.place,
              presentation: {
                'items': [
                  {
                    'id': 'memory',
                    'label': 'Memory module',
                    'category': 'dimm',
                    'orientations': ['notch_left', 'notch_right'],
                  },
                ],
                'destinations': [
                  {
                    'id': 'slot_a',
                    'label': 'Slot A',
                    'accepted_categories': ['dimm'],
                  },
                ],
              },
            ),
            state: MissionRuntimeState.initial('mission'),
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('placement-item-memory')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('placement-destination-slot_a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('placement-orientation-notch_left')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Place'));
    await tester.pump();

    expect(actions, hasLength(1));
    expect(actions.single['target'], 'slot_a');
    expect(actions.single['value'], containsPair('item_id', 'memory'));
    expect(actions.single['value'], containsPair('orientation', 'notch_left'));
    expect(actions.single['value'], containsPair('input_method', 'button'));
  });

  testWidgets('sequencing exposes semantic Move up and Move down controls',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SequencingInteraction(
            phase: _phase(
              InteractionFamily.sequence,
              presentation: {
                'items': [
                  {'id': 'inspect', 'label': 'Inspect'},
                  {'id': 'isolate', 'label': 'Isolate'},
                ],
              },
            ),
            state: MissionRuntimeState(
              missionId: 'mission',
              sequenceOrder: const ['inspect', 'isolate'],
            ),
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Move Isolate up'), findsOneWidget);
    expect(find.byTooltip('Move Inspect down'), findsOneWidget);
    await tester.tap(find.byTooltip('Move Isolate up'));
    await tester.pump();

    expect(actions.single['value'], containsPair('input_method', 'button'));
    expect(actions.single['value'], containsPair('order', ['isolate', 'inspect']));
  });

  testWidgets('matching supports two-column tap selection', (tester) async {
    final actions = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchingInteraction(
            phase: _phase(
              InteractionFamily.match,
              presentation: {
                'sources': [
                  {'id': 'router', 'label': 'Router'},
                ],
                'destinations': [
                  {'id': 'gateway_role', 'label': 'Gateway role'},
                ],
              },
            ),
            state: MissionRuntimeState.initial('mission'),
            onAction: (type, target, value) async => actions.add({
              'type': type,
              'target': target,
              'value': value,
            }),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('matching-source-router')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('matching-destination-gateway_role')),
    );
    await tester.pump();

    expect(actions.single['value'], {
      'source_id': 'router',
      'destination_id': 'gateway_role',
      'input_method': 'tap',
    });
  });

  testWidgets('configuration serializes dropdown toggle and text values',
      (tester) async {
    final actions = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConfigurationPanel(
              phase: _phase(
                InteractionFamily.configure,
                presentation: {
                  'fields': [
                    {
                      'id': 'mode',
                      'label': 'Mode',
                      'type': 'dropdown',
                      'options': [
                        {'id': 'manual', 'label': 'Manual'},
                        {'id': 'auto', 'label': 'Automatic'},
                      ],
                    },
                    {'id': 'enabled', 'label': 'Enabled', 'type': 'toggle'},
                    {'id': 'address', 'label': 'Address', 'type': 'text'},
                  ],
                },
              ),
              state: MissionRuntimeState.initial('mission'),
              onAction: (type, target, value) async => actions.add({
                'type': type,
                'target': target,
                'value': value,
              }),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('configuration-field-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manual').last);
    await tester.ensureVisible(
      find.byKey(const ValueKey('configuration-field-enabled')),
    );
    tester
        .widget<Switch>(
          find.descendant(
            of: find.byKey(const ValueKey('configuration-field-enabled')),
            matching: find.byType(Switch),
          ),
        )
        .onChanged!(true);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('configuration-field-address')),
      '192.0.2.10',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Apply configuration'));
    await tester.pump();

    final value = actions.single['value'] as Map<String, dynamic>;
    expect(value['values'], {
      'mode': 'manual',
      'enabled': true,
      'address': '192.0.2.10',
    });
    expect(value['input_method'], 'button');
  });

  testWidgets('tap inspection reveals technical panel from runtime state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TapInspectInteraction(
            phase: _phase(
              InteractionFamily.inspect,
              objectIds: const ['port'],
              presentation: {
                'objects': [
                  {
                    'id': 'port',
                    'label': 'Uplink port',
                    'inspection': 'Link indicator is inactive.',
                  },
                ],
              },
            ),
            state: MissionRuntimeState(
              missionId: 'mission',
              hotspotStates: const {
                'port': HotspotVisualState.selected,
              },
            ),
            onAction: (_, __, ___) async {},
          ),
        ),
      ),
    );

    expect(find.text('Link indicator is inactive.'), findsOneWidget);
    expect(find.textContaining('Correct'), findsNothing);
    expect(find.textContaining('Wrong'), findsNothing);
  });

  testWidgets('legacy placement restores connection semantic detail',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComponentPlacement(
            stage: _legacyMatchingStage,
            selectedMatchField: null,
            fieldValues: const {'source': 'port'},
            writing: false,
            onFieldSelected: (_, __) {},
            onSourceSelected: (_) {},
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('assessment-match-source-source')),
          )
          .label,
      'Source, connected to Port',
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('assessment-match-destination-port')),
          )
          .label,
      'Port, connected from Source',
    );
    expect(find.text('Source'), findsWidgets);
    handle.dispose();
  });
}

List<String> _sequenceLabels(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.byType(Text),
      ),
    )
    .map((widget) => widget.data)
    .whereType<String>()
    .toList(growable: false);

const _legacyMatchingStage = AuthoritativeMissionStage(
  id: 'legacy',
  criterionCode: 'criterion',
  type: AuthoritativeStageType.matching,
  title: 'Legacy matching',
  instruction: 'Connect the source.',
  actionType: 'connected',
  requiredCount: 1,
  options: [],
  fields: [
    AuthoritativeStageField(
      id: 'source',
      label: 'Source',
      options: [AuthoritativeStageOption(id: 'port', label: 'Port')],
    ),
  ],
);

MissionPhaseDefinition get _toolPhase => _phase(
      InteractionFamily.tool,
      presentation: {
        'tools': [
          {
            'id': 'tester',
            'label': 'Cable tester',
            'category': 'test',
          },
          {
            'id': 'crimper',
            'label': 'Crimper',
            'category': 'termination',
          },
        ],
      },
    );

MissionPhaseDefinition _phase(
  InteractionFamily family, {
  String id = 'phase',
  Map<String, dynamic> presentation = const {},
  List<String> objectIds = const [],
}) =>
    MissionPhaseDefinition(
      id: id,
      title: 'Technical activity',
      instruction: 'Record the technical evidence.',
      primaryInteraction: family,
      availableObjectIds: objectIds,
      presentation: presentation,
    );
