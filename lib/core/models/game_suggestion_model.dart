import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

// Spielvorschlag - terminunabhängig
/// Datenmodell eines Spielvorschlags (Titel, Beschreibung, Spielerzahl, Urheber).
/// Wandelt zwischen Firestore-Dokument und Dart-Objekt um (fromMap, toCreateMap,
/// toUpdateMap).
class GameSuggestionModel {
  const GameSuggestionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final int minPlayers;
  final int maxPlayers;
  final String userId;
  final DateTime? createdAt;

  factory GameSuggestionModel.fromMap(String id, Map<String, dynamic> map) {
    return GameSuggestionModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      minPlayers: map['minPlayers'] as int? ?? 0,
      maxPlayers: map['maxPlayers'] as int? ?? 0,
      userId: map['userId'] as String? ?? '',
      createdAt: dateFromFirestore(map['createdAt']),
    );
  }

  /// Felder fürs Anlegen: createdAt per Server-Zeitstempel, userId und
  /// createdAt gibt es nur hier (Firestore-Regel: createdAt == request.time).
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Nur die vier änderbaren Felder; userId und createdAt bleiben unberührt.
  Map<String, dynamic> toUpdateMap() => {
    'title': title,
    'description': description,
    'minPlayers': minPlayers,
    'maxPlayers': maxPlayers,
  };

  @override
  bool operator ==(Object other) =>
      other is GameSuggestionModel &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.minPlayers == minPlayers &&
      other.maxPlayers == maxPlayers &&
      other.userId == userId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    minPlayers,
    maxPlayers,
    userId,
    createdAt,
  );
}
