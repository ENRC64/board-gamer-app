/// Fachlicher Fehler rund um Termine, mit deutschem Text für die UI.
class EventFailure implements Exception {
  const EventFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
