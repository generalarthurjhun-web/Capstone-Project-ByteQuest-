import 'mission_runtime_models.dart';

abstract interface class MissionEvidenceTransport {
  Future<void> append(MissionEvidenceAction action);

  Future<List<AcknowledgedMissionEvidenceAction>> readAcknowledgedActions();
}

/// One server-acknowledged action with stable record identity and ordering.
///
/// This transport envelope is intentionally separate from the persisted
/// runtime JSON contract, which remains schema version 1.
final class AcknowledgedMissionEvidenceAction {
  const AcknowledgedMissionEvidenceAction({
    required this.action,
    required this.serverRecordId,
    required this.serverOrder,
    required this.recordedAt,
  });

  final MissionEvidenceAction action;
  final String serverRecordId;
  final int serverOrder;
  final DateTime recordedAt;
}

/// Serializes evidence writes and reconciles locally durable actions against
/// the RLS-scoped server timeline.
final class MissionEvidenceGateway {
  MissionEvidenceGateway({required MissionEvidenceTransport transport})
      : _transport = transport;

  final MissionEvidenceTransport _transport;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> record(MissionEvidenceAction action) {
    return _enqueue(() => _transport.append(action));
  }

  Future<List<AcknowledgedMissionEvidenceAction>> readAcknowledgedActions() {
    return _enqueue(() async {
      final records = await _transport.readAcknowledgedActions();
      final byRecordId = <String, AcknowledgedMissionEvidenceAction>{};
      final byActionId = <String>{};
      for (final record in records.toList()
        ..sort((left, right) {
          final order = left.serverOrder.compareTo(right.serverOrder);
          if (order != 0) return order;
          final time = left.recordedAt.compareTo(right.recordedAt);
          if (time != 0) return time;
          return left.serverRecordId.compareTo(right.serverRecordId);
        })) {
        if (byRecordId.containsKey(record.serverRecordId) ||
            !byActionId.add(record.action.clientActionId)) {
          continue;
        }
        byRecordId[record.serverRecordId] = record;
      }
      return List.unmodifiable(byRecordId.values);
    });
  }

  Future<Set<String>> reconcile(Iterable<MissionEvidenceAction> actions) {
    return _enqueue(() async {
      final records = await _transport.readAcknowledgedActions();
      final acknowledged =
          records.map((record) => record.action.clientActionId).toSet();
      var iterableIndex = 0;
      final ordered = actions
          .map((action) => _IndexedEvidenceAction(action, iterableIndex++))
          .toList()
        ..sort((left, right) {
          final occurrenceOrder =
              left.action.occurredAt.compareTo(right.action.occurredAt);
          return occurrenceOrder != 0
              ? occurrenceOrder
              : left.iterableIndex.compareTo(right.iterableIndex);
        });

      for (final indexedAction in ordered) {
        final action = indexedAction.action;
        if (!acknowledged.add(action.clientActionId)) continue;
        try {
          await _transport.append(action);
        } catch (_) {
          acknowledged.remove(action.clientActionId);
          rethrow;
        }
      }
      return Set<String>.unmodifiable(acknowledged);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completion = _writeQueue.then((_) => operation());
    _writeQueue = completion.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return completion;
  }
}

final class _IndexedEvidenceAction {
  const _IndexedEvidenceAction(this.action, this.iterableIndex);

  final MissionEvidenceAction action;
  final int iterableIndex;
}
