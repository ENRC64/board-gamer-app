import 'package:board_gamer_app/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 11, 15, 18, 30);
  final user = UserModel(
    uid: 'u1',
    displayName: 'Enrico',
    email: 'e@example.com',
    address: 'Hauptstr. 1, 10115 Berlin',
    createdAt: created,
  );

  test('toMap/fromMap Round-Trip ergibt dasselbe Modell', () {
    expect(UserModel.fromMap('u1', user.toMap()), user);
  });

  test('toMap speichert createdAt als Timestamp und ohne uid', () {
    final map = user.toMap();
    expect(map['createdAt'], isA<Timestamp>());
    expect(map.containsKey('uid'), isFalse);
  });

  test('fromMap setzt Standardwerte bei fehlenden Feldern', () {
    final u = UserModel.fromMap('u2', {});
    expect(u.displayName, '');
    expect(u.address, '');
    expect(u.createdAt, isNull);
    expect(u.hasAddress, isFalse);
  });

  test('copyWith ändert nur angegebene Felder', () {
    final changed = user.copyWith(address: 'Neue Str. 2');
    expect(changed.address, 'Neue Str. 2');
    expect(changed.displayName, user.displayName);
    expect(changed.uid, user.uid);
  });
}
