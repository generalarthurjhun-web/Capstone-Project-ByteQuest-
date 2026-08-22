import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/screens/simulation/components/hotspot_widget.dart';
import 'package:bytequest/screens/simulation/components/scene_connection_painter.dart';
import 'package:bytequest/screens/simulation/components/simulation_scene.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tiny hotspot keeps a 48 dp semantic tap target', (tester) async {
    await tester.pumpWidget(_sceneHarness());

    final hotspot = find.byKey(const Key('hotspot-port-1'));
    final size = tester.getSize(hotspot);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Server LAN port, neutral'), findsOneWidget);
  });

  testWidgets('hotspot states have distinct visual semantics', (tester) async {
    for (final state in HotspotVisualState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HotspotWidget(
                object: _scene.objects.first,
                state: state,
                enabled: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Server LAN port, ${state.name}'),
        findsOneWidget,
      );
      expect(find.byIcon(_stateIcon(state)), findsOneWidget);
    }
  });

  testWidgets('reset camera returns InteractiveViewer to identity',
      (tester) async {
    await tester.pumpWidget(_sceneHarness());
    final viewer = find.byType(InteractiveViewer);

    await tester.drag(viewer, const Offset(120, 40));
    await tester.pump();
    var controller =
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    expect(controller.value.isIdentity(), isFalse);

    await tester.tap(find.byTooltip('Reset workspace view'));
    await tester.pump();
    controller =
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    expect(controller.value.isIdentity(), isTrue);
  });

  testWidgets('object list and hotspot invoke the same selection callback',
      (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(_sceneHarness(onSelected: selected.add));

    await tester.tap(find.byKey(const Key('hotspot-port-1')));
    await tester.pump();
    await tester.tap(find.text('Objects'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('object-list-port-1')));
    await tester.pumpAndSettle();

    expect(selected, ['port-1', 'port-1']);
  });

  testWidgets('compact portrait and landscape scenes do not overflow',
      (tester) async {
    for (final size in [const Size(320, 568), const Size(800, 360)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_sceneHarness());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
      expect(find.byType(InteractiveViewer), findsOneWidget);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('portrait and landscape preserve the 1200 by 720 workspace ratio',
      (tester) async {
    for (final size in [const Size(320, 568), const Size(800, 360)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_sceneHarness());
      await tester.pump();

      final workspace = tester.getRect(
        find.byKey(const Key('simulation-logical-workspace')),
      );
      expect(
        workspace.width / workspace.height,
        closeTo(1200 / 720, .001),
        reason: 'viewport $size rendered $workspace',
      );
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('connections draw over 200 ms or immediately for reduced motion',
      (tester) async {
    await tester.pumpWidget(_sceneHarness());
    expect(_connectionPainter(tester).progress, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(_connectionPainter(tester).progress, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_connectionPainter(tester).progress, 1);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _sceneHarness(),
      ),
    );
    expect(_connectionPainter(tester).progress, 1);
    expect(
        SceneConnectionPainter.drawDuration, const Duration(milliseconds: 200));
  });

  testWidgets('catalog object IDs resolve to connection nodes', (tester) async {
    final definition = MissionSimulationDefinitions.byId('coc2_m3');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimulationScene(
            scene: definition.scene,
            connectedNodePairs: const {'router>switch'},
            onObjectSelected: (_) {},
          ),
        ),
      ),
    );

    expect(_connectionPainter(tester).connections, hasLength(1));
    expect(_connectionPainter(tester).connections.single.id, 'router>switch');
  });
}

Widget _sceneHarness({ValueChanged<String>? onSelected}) => MaterialApp(
      home: Scaffold(
        body: SimulationScene(
          scene: _scene,
          hotspotStates: const {
            'port-1': HotspotVisualState.neutral,
            'switch-1': HotspotVisualState.completed,
          },
          connectedNodePairs: const {'lan>uplink'},
          onObjectSelected: onSelected ?? (_) {},
        ),
      ),
    );

final _scene = SimulationSceneDefinition(
  id: 'network-lab',
  objects: [
    SceneObjectDefinition(
      id: 'port-1',
      label: 'Server LAN port',
      x: .08,
      y: .18,
      width: .005,
      height: .005,
      hotspotType: 'port',
      connectionNodeIds: const ['lan'],
    ),
    SceneObjectDefinition(
      id: 'switch-1',
      label: 'Access switch',
      x: .68,
      y: .58,
      width: .12,
      height: .10,
      hotspotType: 'device',
      connectionNodeIds: const ['uplink'],
    ),
  ],
  initialStatus: const {'title': 'Network workspace'},
);

IconData _stateIcon(HotspotVisualState state) => switch (state) {
      HotspotVisualState.neutral => Icons.cable_outlined,
      HotspotVisualState.selected => Icons.radio_button_checked_rounded,
      HotspotVisualState.completed => Icons.check_rounded,
      HotspotVisualState.error => Icons.priority_high_rounded,
    };

SceneConnectionPainter _connectionPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const Key('scene-connections')))
    .painter! as SceneConnectionPainter;
