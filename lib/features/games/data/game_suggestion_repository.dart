import 'package:board_gamer_app/core/models/game_suggestion_model.dart';
import 'package:board_gamer_app/features/event/data/event_failure.dart';
import 'package:board_gamer_app/features/games/domain/game_suggestion_rules.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-Zugriff auf die Sammlung „gameSuggestions“: Live-Stream sowie
/// Anlegen, Ändern und Löschen. Prüft Eingaben und dass nur der Urheber
/// den eigenen Vorschlag ändern oder löschen darf.
class GameSuggestionRepository {
  const GameSuggestionRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _suggestions =>
      _db.collection('gameSuggestions');

  /// Live-Stream aller Vorschläge: snapshots() liefert bei jeder Änderung
  /// eine neue Liste. Sortiert wird bewusst im Client (siehe _compare).
  Stream<List<GameSuggestionModel>> watch() {
    return _suggestions.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return GameSuggestionModel.fromMap(doc.id, doc.data());
      }).toList(); // toList(), damit sortieren möglich ist

      list.sort(_compare);
      return list;
    });
  }

  /// Älteste zuerst. createdAt kann direkt nach dem Anlegen noch null sein
  /// (Server-Zeitstempel folgt) und kommt dann ans Ende; die id sorgt für
  /// eine stabile Reihenfolge bei Gleichstand.
  static int _compare(GameSuggestionModel a, GameSuggestionModel b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime != null) return 1;
    if (aTime != null && bTime == null) return -1;
    if (aTime != null && bTime != null) {
      final byTime = aTime.compareTo(bTime);
      if (byTime != 0) return byTime;
    }
    return a.id.compareTo(b.id);
  }

  void _validateContent(String title, int minPlayers, int maxPlayers) {
    final titleError = validateTitle(title);
    if (titleError != null) throw EventFailure(titleError);
    if (minPlayers < 1 || maxPlayers < 1) {
      throw const EventFailure(
        'Das Spiel muss zumindest für eine Person spielbar sein.',
      );
    }
    final rangeError = validatePlayerRange(minPlayers, maxPlayers);
    if (rangeError != null) throw EventFailure(rangeError);
  }

  Future<void> _validateSuggestionOwnership(
    String suggestionId,
    String userId,
  ) async {
    final snapshot = await _suggestions.doc(suggestionId).get();
    if (!snapshot.exists) {
      throw const EventFailure('Der Vorschlag existiert nicht mehr.');
    }
    if (snapshot.data()?['userId'] != userId) {
      throw const EventFailure(
        'Nur eigene Vorschläge können geändert oder gelöscht werden.',
      );
    }
  }

  /// Neue Auto-ID: dieselbe Person darf mehrere Vorschläge erstellen.
  Future<void> add({
    required String userId,
    required String title,
    required String description,
    required int minPlayers,
    required int maxPlayers,
  }) async {
    final cleanTitle = title.trim();
    _validateContent(cleanTitle, minPlayers, maxPlayers);

    try {
      final suggestion = GameSuggestionModel(
        id: '',
        title: cleanTitle,
        description: description.trim(),
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        userId: userId,
        createdAt: null,
      );
      await _suggestions.add(suggestion.toCreateMap());
    } on FirebaseException {
      throw const EventFailure(
        'Speichern nicht möglich. '
        'Verbindung und Berechtigung prüfen und erneut versuchen.',
      );
    }
  }

  /// Ändert einen eigenen Vorschlag (Besitzerprüfung; zusätzlich Firestore-Rules).
  Future<void> update({
    required String suggestionId,
    required String userId,
    required String title,
    required String description,
    required int minPlayers,
    required int maxPlayers,
  }) async {
    final cleanTitle = title.trim();
    _validateContent(cleanTitle, minPlayers, maxPlayers);
    try {
      await _validateSuggestionOwnership(suggestionId, userId);
      final suggestion = GameSuggestionModel(
        id: suggestionId,
        userId: userId,
        title: cleanTitle,
        description: description.trim(),
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        createdAt: null,
      );
      await _suggestions.doc(suggestionId).update(suggestion.toUpdateMap());
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        throw const EventFailure('Der Vorschlag existiert nicht mehr.');
      }
      throw const EventFailure(
        'Ändern nicht möglich. '
        'Verbindung und Berechtigung prüfen und erneut versuchen.',
      );
    }
  }

  /// Löscht einen eigenen Vorschlag (Besitzerprüfung; zusätzlich Firestore-Rules).
  Future<void> delete({
    required String suggestionId,
    required String userId,
  }) async {
    try {
      await _validateSuggestionOwnership(suggestionId, userId);
      await _suggestions.doc(suggestionId).delete();
    } on FirebaseException {
      throw const EventFailure(
        'Löschen nicht möglich. '
        'Liste neu laden und erneut versuchen.',
      );
    }
  }
}
