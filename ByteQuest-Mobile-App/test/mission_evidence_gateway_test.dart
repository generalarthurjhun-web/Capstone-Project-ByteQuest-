import 'dart:async';

import 'package:bytequest/screens/simulation/runtime/mission_evidence_gateway.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/authoritative_assessment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reconcile appends each missing action once in occurrence order',
      () async {
    final transport = _FakeEvidenceTransport(existingIds: {'stable-1'});
    final gateway = MissionEvidenceGateway(transport: transport);

    await gateway.reconcile([
      _action('stable-3', occurredAt: DateTime.utc(2026, 1, 1, 0, 0, 3)),
      _action('stable-1', occurredAt: DateTime.utc(2026, 1, 1, 0, 0, 1)),
      _action('stable-2', occurredAt: DateTime.utc(2026, 1, 1, 0, 0, 2)),
      _action('stable-2', occurredAt: DateTime.utc(2026, 1, 1, 0, 0, 2)),
    ]);

    expect(transport.appendedIds, ['stable-2', 'stable-3']);
  });

  test('record serializes concurrent writes in dispatch order', () async {
    final firstWrite = Completer<void>();
    final transport = _FakeEvidenceTransport(firstWrite: firstWrite);
    final gateway = MissionEvidenceGateway(transport: transport);

    final first = gateway.record(_action('stable-1'));
    final second = gateway.record(_action('stable-2'));
    await Future<void>.delayed(Duration.zero);

    expect(transport.appendedIds, ['stable-1']);
    firstWrite.complete();
    await Future.wait([first, second]);
    expect(transport.appendedIds, ['stable-1', 'stable-2']);
  });

  test('reconcile preserves iterable order for equal occurrence times',
      () async {
    final transport = _FakeEvidenceTransport();
    final gateway = MissionEvidenceGateway(transport: transport);
    final occurredAt = DateTime.utc(2026, 1, 1, 0, 0, 1);

    await gateway.reconcile([
      _action('stable-first', occurredAt: occurredAt),
      _action('stable-second', occurredAt: occurredAt),
    ]);

    expect(transport.appendedIds, ['stable-first', 'stable-second']);
  });

  test('authoritative transport rejects writes without an active attempt',
      () async {
    await expectLater(
      AuthoritativeAssessmentService.instance.append(_action('stable-1')),
      throwsStateError,
    );
  });
}

MissionEvidenceAction _action(
  String clientActionId, {
  DateTime? occurredAt,
}) {
  return MissionEvidenceAction(
    clientActionId: clientActionId,
    missionId: 'coc2_m3',
    phaseId: 'verify',
    actionType: 'test_run',
    value: const {'result': 'link_detected'},
    occurredAt: occurredAt ?? DateTime.utc(2026),
  );
}

final class _FakeEvidenceTransport implements MissionEvidenceTransport {
  _FakeEvidenceTransport({
    Set<String> existingIds = const {},
    this.firstWrite,
  }) : existingIds = Set<String>.from(existingIds);

  final Set<String> existingIds;
  final Completer<void>? firstWrite;
  final List<String> appendedIds = [];

  @override
  Future<List<AcknowledgedMissionEvidenceAction>>
      readAcknowledgedActions() async => [
            for (final (index, id) in existingIds.indexed)
              AcknowledgedMissionEvidenceAction(
                action: _action(id),
                serverRecordId: 'server-$id',
                serverOrder: index + 1,
                recordedAt: DateTime.utc(2026),
              ),
          ];

  @override
  Future<void> append(MissionEvidenceAction action) async {
    appendedIds.add(action.clientActionId);
    if (appendedIds.length == 1 && firstWrite != null) {
      await firstWrite!.future;
    }
    existingIds.add(action.clientActionId);
  }
}
