import 'firestore_converters.dart';

/// Mitglied der Spielgruppe, gespeichert unter `/users/{uid}` (A-01, A-02).
class UserModel {
  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.address = '',
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;

  /// Wohnadresse; Pflicht, bevor jemand Gastgeber werden kann (A-02).
  final String address;

  /// Registrierungszeitpunkt, letzter Tie-Breaker der Host-Rotation (A-05).
  final DateTime? createdAt;

  bool get hasAddress => address.trim().isNotEmpty;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      createdAt: dateFromFirestore(map['createdAt']),
    );
  }

  /// Ohne `uid`, da diese die Dokument-ID ist.
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'address': address,
      if (createdAt != null) 'createdAt': dateToFirestore(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? address,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserModel &&
      other.uid == uid &&
      other.displayName == displayName &&
      other.email == email &&
      other.address == address &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(uid, displayName, email, address, createdAt);
}
