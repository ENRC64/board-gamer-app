import 'firestore_converters.dart';

/// Kurze Statusmeldung zu einem Termin (US-06, A-11), gespeichert unter
/// `/events/{eventId}/statusMessages/{id}`.
class StatusMessageModel {
  const StatusMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  /// Höchstlänge für Freitext (A-11).
  static const maxLength = 140;

  /// Vordefinierte Meldungen (A-11).
  static const presets = [
    'Pünktlich',
    '+15 Min',
    '+30 Min',
    'Fahre los',
    'Muss absagen',
  ];

  factory StatusMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return StatusMessageModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt:
          dateFromFirestore(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'text': text,
    'createdAt': dateToFirestore(createdAt),
  };

  @override
  bool operator ==(Object other) =>
      other is StatusMessageModel &&
      other.id == id &&
      other.userId == userId &&
      other.userName == userName &&
      other.text == text &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, userId, userName, text, createdAt);
}
