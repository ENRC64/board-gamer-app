import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/status_message_model.dart';
import '../auth/data/auth_repository.dart';
import '../event/data/event_repository.dart';
import '../status/data/status_repository.dart';
import 'notification_service.dart';

/// Schlüssel für den obersten [ScaffoldMessenger] der App. Damit kann auch
/// Code außerhalb eines Screens eine Snackbar (In-App-Hinweis) zeigen.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Liefert, ob die App gerade im Vordergrund ist. In Tests überschreibbar.
final isAppInForegroundProvider = Provider<bool Function()>(
  (ref) => () {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  },
);

/// Filtert aus [messages] die Meldungen, die neu sind (ID noch nicht in
/// [seenIds]) und nicht vom Nutzer selbst stammen ([myUid]).
List<StatusMessageModel> findNewIncoming({
  required Set<String> seenIds,
  required List<StatusMessageModel> messages,
  required String myUid,
}) {
  return messages
      .where((m) => !seenIds.contains(m.id) && m.userId != myUid)
      .toList();
}

/// Beobachtet die Statusmeldungen des nächsten Termins und meldet neue
/// Meldungen anderer Mitglieder (T-44, US-06, A-12):
/// - App im Vordergrund → In-App-Hinweis (Snackbar)
/// - App im Hintergrund → lokale Benachrichtigung
///
/// Beim ersten Laden werden die vorhandenen Meldungen nur gemerkt, nicht
/// gemeldet; sonst gäbe es nach jedem App-Start eine Flut alter Hinweise.
///
/// Der Provider liefert keinen Wert (`void`); er wird nur „eingeschaltet“,
/// indem die App-Shell ihn beobachtet (`ref.watch`).
final statusNotificationsProvider = Provider<void>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  final eventId = ref.watch(nextEventProvider).value?.id;
  if (uid == null || eventId == null) return;

  Set<String>? seenIds;
  ref.listen<AsyncValue<List<StatusMessageModel>>>(
    statusMessagesProvider(eventId),
    (_, next) {
      final messages = next.value;
      if (messages == null) return;
      if (seenIds == null) {
        seenIds = messages.map((m) => m.id).toSet();
        return;
      }
      final fresh = findNewIncoming(
        seenIds: seenIds!,
        messages: messages,
        myUid: uid,
      );
      seenIds!.addAll(messages.map((m) => m.id));
      for (final m in fresh.reversed) {
        _notify(ref, m);
      }
    },
    fireImmediately: true,
  );
});

void _notify(Ref ref, StatusMessageModel m) {
  if (ref.read(isAppInForegroundProvider)()) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Builder(
          builder: (context) => Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('${m.userName}: ${m.text}')),
            ],
          ),
        ),
      ),
    );
  } else {
    ref
        .read(notificationServiceProvider)
        .show(id: m.id.hashCode, title: m.userName, body: m.text);
  }
}
