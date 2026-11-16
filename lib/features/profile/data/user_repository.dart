import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';

/// Lesen und Ändern der Profile unter `/users/{uid}`.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Profil als Stream; `null`, wenn das Dokument (noch) nicht existiert.
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : UserModel.fromMap(snap.id, data);
    });
  }

  /// Alle Mitglieder in Registrierungsreihenfolge (Basis für A-05).
  Stream<List<UserModel>> watchAllUsers() {
    return _users
        .orderBy('createdAt')
        .snapshots()
        .map(
          (q) => q.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Ändert Anzeigename und Adresse; legt das Dokument an, falls es fehlt.
  Future<void> updateProfile({
    required String uid,
    required String email,
    required String displayName,
    required String address,
  }) {
    return _users.doc(uid).set({
      'displayName': displayName.trim(),
      'email': email,
      'address': address.trim(),
    }, SetOptions(merge: true));
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

/// Profil des angemeldeten Nutzers.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
});

/// Alle Mitglieder in Registrierungsreihenfolge.
final allUsersProvider = StreamProvider<List<UserModel>>(
  (ref) => ref.watch(userRepositoryProvider).watchAllUsers(),
);
