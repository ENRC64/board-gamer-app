/// Hilfsfunktion für Anzeigenamen: Liefert die Initialen (erster und letzter
/// Namensteil, Großbuchstaben) oder „?“ bei leerem Namen, z. B. für Avatare.
String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  if (parts.isEmpty) return '?';
  final first = String.fromCharCode(parts.first.runes.first);
  final last = parts.length > 1
      ? String.fromCharCode(parts.last.runes.first)
      : '';
  return '$first$last'.toUpperCase();
}
