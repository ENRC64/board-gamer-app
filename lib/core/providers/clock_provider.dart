import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktuelle Uhrzeit, die sich alle 30 Sekunden aktualisiert.
///
/// Screens mit Countdown oder „vor X Min.“ beobachten diesen Provider und
/// werden dadurch regelmäßig neu gezeichnet. In Tests wird er durch eine
/// feste Uhrzeit ersetzt.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});
