// TODO: Dokumentation ergänzen, was ist games_suggestion_rules.dart?

// TODO: Dokumentation ergänzen
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

// TODO: Dokumentation ergänzen
int? parsePlayerCount(String? value) {
  final number = int.tryParse((value ?? '').trim());
  if (number == null || number < 1) return null;
  return number;
}

// TODO: Dokumentation ergänzen
String? validatePlayerCount(String? value) {
  if (parsePlayerCount(value) == null) {
    return 'Ganze Zahl > 0 eingeben.';
  }
  return null;
}

// TODO: Dokumentation ergänzen
String? validatePlayerRange(int minPlayers, int maxPlayers) {
  if (minPlayers > maxPlayers) {
    return 'Die maximale Spielerzahl muss größer als die Mindestzahl sein.';
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