import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

/// Owns the 30s unread-count poll (AC9), mirroring `NotificationBell.tsx`'s
/// "poll on mount, every 30s" -- scoped to the logged-in [AppShell] (S-027)
/// for the lifetime of the session. Deliberately **not**
/// `.autoDispose` (Architect spec, S-025 "Cache / side effects") so the
/// badge stays live across tab navigation instead of resetting every time
/// nothing happens to be watching it.
class UnreadCountController extends Notifier<int> {
  Timer? _timer;

  @override
  int build() {
    final user = ref.watch(authControllerProvider).valueOrNull;
    ref.onDispose(_stopPolling);

    _stopPolling();
    if (user != null) {
      _startPolling();
    }
    return 0;
  }

  void _startPolling() {
    unawaited(_poll());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final unread = await ref.read(notificationsRepositoryProvider).list(unreadOnly: true);
      state = unread.length;
    } catch (_) {
      // A failed poll degrades to the last-known count rather than crashing
      // or blanking the badge (UX notes).
    }
  }

  /// Nudges the count to re-sync immediately after a mark-read/mark-all
  /// mutation elsewhere, instead of waiting up to 30s (AC3/4).
  Future<void> refreshNow() => _poll();

  /// Optimistic badge update after a successful mark-one-read (AC3).
  void decrement() {
    if (state > 0) state = state - 1;
  }

  /// Optimistic badge clear after a successful mark-all-read (AC4 / Architect flow).
  void clear() => state = 0;
}

final unreadCountProvider = NotifierProvider<UnreadCountController, int>(UnreadCountController.new);

/// The Notifications screen's own full list, with local mark-read/mark-all
/// mutations (AC3/4 flip `isRead` in place, no refetch).
class NotificationsListController extends AutoDisposeAsyncNotifier<List<NotificationResponse>> {
  @override
  FutureOr<List<NotificationResponse>> build() {
    return ref.watch(notificationsRepositoryProvider).list();
  }

  Future<void> markRead(String notificationId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((n) => n.id == notificationId);
    if (index == -1 || current[index].isRead) return;

    state = AsyncValue.data([
      for (final notification in current)
        if (notification.id == notificationId) notification.rebuild((b) => b..isRead = true) else notification,
    ]);

    try {
      await ref.read(notificationsRepositoryProvider).markRead(notificationId);
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
    // Immediate badge decrement (AC3); poll can re-sync later.
    ref.read(unreadCountProvider.notifier).decrement();
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || current.every((n) => n.isRead)) return;

    state = AsyncValue.data([for (final notification in current) notification.rebuild((b) => b..isRead = true)]);

    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
    // Architect flow: set count = 0 immediately, don't wait for the poll (AC4).
    ref.read(unreadCountProvider.notifier).clear();
  }
}

final notificationsListProvider =
    AsyncNotifierProvider.autoDispose<NotificationsListController, List<NotificationResponse>>(
  NotificationsListController.new,
);
