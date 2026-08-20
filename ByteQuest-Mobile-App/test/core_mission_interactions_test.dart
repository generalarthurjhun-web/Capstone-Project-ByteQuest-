import 'dart:ui' show Tristate;

import 'package:bytequest/screens/simulation/interactions/mission_interactions.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
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
}

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
  Map<String, dynamic> presentation = const {},
  List<String> objectIds = const [],
}) =>
    MissionPhaseDefinition(
      id: 'phase',
      title: 'Technical activity',
      instruction: 'Record the technical evidence.',
      primaryInteraction: family,
      availableObjectIds: objectIds,
      presentation: presentation,
    );
