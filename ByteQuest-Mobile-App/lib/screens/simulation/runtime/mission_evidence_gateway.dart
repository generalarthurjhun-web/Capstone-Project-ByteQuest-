import 'mission_runtime_models.dart';

abstract interface class MissionEvidenceTransport {
  Future<void> append(MissionEvidenceAction action);

  Future<Set<String>> acknowledgedClientActionIds();
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

  Future<Set<String>> reconcile(Iterable<MissionEvidenceAction> actions) {
    return _enqueue(() async {
      final acknowledged = await _transport.acknowledgedClientActionIds();
      final ordered = actions.toList()
        ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));

      for (final action in ordered) {
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
