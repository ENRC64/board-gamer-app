/// Validierungsregeln für Spielvorschläge: Titel, Spielerzahl und
/// Spielerbereich sowie die Anzeige-Beschriftung der Spielerzahl.
/// Prüft den Titel: nicht leer und höchstens 140 Zeichen (nach dem Trimmen).
String? validateTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) {
    return 'Titel eingeben.';
  }
  if (title.runes.length > 140) {
    return 'Der Titel darf maximal 140 Zeichen lang sein.';
  }
  return null;
}

/// Wandelt die Eingabe in eine positive ganze Zahl um, sonst null.
int? parsePlayerCount(String? value) {
  final number = int.tryParse((value ?? '').trim());
  if (number == null || number < 1) return null;
  return number;
}

/// Formularvalidierung: Fehlermeldung, wenn keine ganze Zahl > 0 vorliegt.
String? validatePlayerCount(String? value) {
  if (parsePlayerCount(value) == null) {
    return 'Ganze Zahl > 0 eingeben.';
  }
  return null;
}

/// Fehlermeldung, wenn die maximale Spielerzahl unter dem Minimum liegt.
String? validatePlayerRange(int minPlayers, int maxPlayers) {
  if (minPlayers > maxPlayers) {
    return 'Die maximale Spielerzahl muss größer oder gleich der Mindestzahl sein.';
  }
  return null;
}

/// „2 Spieler“, „1 Spieler“ oder „3–4 Spieler“ (nie „2–2“).
String playerCountLabel(int minPlayers, int maxPlayers) {
  if (minPlayers == maxPlayers) {
    return maxPlayers == 1 ? '1 Spieler' : '$maxPlayers Spieler';
  }
  return '$minPlayers–$maxPlayers Spieler';
}
