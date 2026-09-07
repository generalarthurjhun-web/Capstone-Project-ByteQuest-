import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

enum LearnerRealtimeDomain {
  account,
  classes,
  learning,
  assessment,
  quizzes,
  resources,
  progress,
  notifications,
}

/// RLS-scoped realtime invalidation for the learner application.
///
/// Events never become authoritative client state. They only tell interested
/// screens to refetch through the existing trusted queries and RPCs.
class LearnerRealtimeCoordinator extends ChangeNotifier {
  LearnerRealtimeCoordinator({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  Timer? _debounce;
  String? _userId;
  Set<LearnerRealtimeDomain> _changedDomains = const {};
  int _revision = 0;

  int get revision => _revision;
  Set<LearnerRealtimeDomain> get changedDomains => _changedDomains;

  Future<void> start(String userId) async {
    if (_userId == userId && _channel != null) return;
    await stop();
    _userId = userId;
    final session = _client.auth.currentSession;
    if (session == null || session.user.id != userId) {
      _userId = null;
      return;
    }
    // Supply the authenticated JWT explicitly before channel creation. This
    // is required for Realtime's per-event RLS visibility check.
    await _client.realtime.setAuth(session.accessToken);

    final channel = _client.channel('learner-sync-$userId');
    _listenFiltered(
      channel,
      table: 'profiles',
      column: 'user_id',
      value: userId,
      domains: const {LearnerRealtimeDomain.account},
    );
    _listenFiltered(
      channel,
      table: 'class_memberships',
      column: 'learner_id',
      value: userId,
      domains: const {
        LearnerRealtimeDomain.classes,
        LearnerRealtimeDomain.learning,
      },
    );
    _listenFiltered(
      channel,
      table: 'attempts',
      column: 'learner_id',
      value: userId,
      domains: const {
        LearnerRealtimeDomain.assessment,
        LearnerRealtimeDomain.progress,
      },
    );
    _listenFiltered(
      channel,
      table: 'quiz_attempts',
      column: 'learner_id',
      value: userId,
      domains: const {LearnerRealtimeDomain.quizzes},
    );
    _listenFiltered(
      channel,
      table: 'coc_bypasses',
      column: 'learner_id',
      value: userId,
      domains: const {LearnerRealtimeDomain.learning},
    );
    _listenFiltered(
      channel,
      table: 'gamification_events',
      column: 'learner_id',
      value: userId,
      domains: const {LearnerRealtimeDomain.progress},
    );
    _listenFiltered(
      channel,
      table: 'user_achievements',
      column: 'user_id',
      value: userId,
      domains: const {LearnerRealtimeDomain.progress},
    );
    _listenFiltered(
      channel,
      table: 'notifications',
      column: 'user_id',
      value: userId,
      domains: const {LearnerRealtimeDomain.notifications},
    );

    // These records do not carry learner_id directly. Existing RLS restricts
    // delivery to the learner's enrolled classes and owned attempts.
    _listen(channel, 'assignments', const {LearnerRealtimeDomain.learning});
    _listen(channel, 'learning_resources', const {
      LearnerRealtimeDomain.resources,
      LearnerRealtimeDomain.learning,
    });
    _listen(channel, 'quiz_assignments', const {LearnerRealtimeDomain.quizzes});
    _listen(channel, 'quiz_results', const {LearnerRealtimeDomain.quizzes});
    _listen(channel, 'criterion_results', const {
      LearnerRealtimeDomain.assessment,
      LearnerRealtimeDomain.progress,
    });
    _listen(channel, 'score_revisions', const {
      LearnerRealtimeDomain.assessment,
      LearnerRealtimeDomain.progress,
    });
    _listen(channel, 'result_releases', const {
      LearnerRealtimeDomain.assessment,
      LearnerRealtimeDomain.progress,
    });

    _channel = channel;
    channel.subscribe();
  }

  void _listenFiltered(
    RealtimeChannel channel, {
    required String table,
    required String column,
    required String value,
    required Set<LearnerRealtimeDomain> domains,
  }) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: column,
        value: value,
      ),
      callback: (_) => _queue(domains),
    );
  }

  void _listen(
    RealtimeChannel channel,
    String table,
    Set<LearnerRealtimeDomain> domains,
  ) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (_) => _queue(domains),
    );
  }

  void _queue(Set<LearnerRealtimeDomain> domains) {
    _changedDomains = {..._changedDomains, ...domains};
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _revision += 1;
      notifyListeners();
      _changedDomains = const {};
    });
  }

  Future<void> stop() async {
    _debounce?.cancel();
    _debounce = null;
    final channel = _channel;
    _channel = null;
    _userId = null;
    _changedDomains = const {};
    if (channel != null) await _client.removeChannel(channel);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(_client.removeChannel(channel));
    super.dispose();
  }
}

mixin LearnerRealtimeRefreshMixin<T extends StatefulWidget> on State<T> {
  LearnerRealtimeCoordinator? _realtimeCoordinator;
  Timer? _realtimeRefreshDebounce;
  int _handledRealtimeRevision = 0;

  Set<LearnerRealtimeDomain> get realtimeDomains;
  Future<void> refreshFromRealtime();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coordinator = context.read<LearnerRealtimeCoordinator>();
    if (identical(coordinator, _realtimeCoordinator)) return;
    _realtimeCoordinator?.removeListener(_handleRealtimeChange);
    _realtimeCoordinator = coordinator;
    _handledRealtimeRevision = coordinator.revision;
    coordinator.addListener(_handleRealtimeChange);
  }

  void _handleRealtimeChange() {
    final coordinator = _realtimeCoordinator;
    if (coordinator == null ||
        coordinator.revision == _handledRealtimeRevision) {
      return;
    }
    _handledRealtimeRevision = coordinator.revision;
    if (coordinator.changedDomains.intersection(realtimeDomains).isEmpty) {
      return;
    }
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) unawaited(refreshFromRealtime());
    });
  }

  @override
  void dispose() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeCoordinator?.removeListener(_handleRealtimeChange);
    super.dispose();
  }
}
