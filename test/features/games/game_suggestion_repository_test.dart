// TODO: Dokumentation ergänzen
import 'package:board_gamer_app/features/event/data/event_failure.dart';
import 'package:board_gamer_app/features/games/data/game_suggestion_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late GameSuggestionRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = GameSuggestionRepository(db);
  });

  Future<QuerySnapshot<Map<String, dynamic>>> suggestions() =>
      db.collection('gameSuggestions').get();

  Future<String> ownSuggestion() async {
    await repo.add(
      userId: 'anna',
      title: 'Catan',
      description: 'Ursprüngliche Beschreibung.',
      minPlayers: 3,
      maxPlayers: 4,
    );
    return (await suggestions()).docs.single.id;
  }

  test('mehrere Vorschläge desselben Nutzers werden gespeichert', () async {
    await repo.add(
      userId: 'anna',
      title: '  Catan ',
      description: ' Gemeinsam eine Insel besiedeln. ',
      minPlayers: 3,
      maxPlayers: 4,
    );
    await repo.add(
      userId: 'anna',
      title: 'Azul',
      description: '',
      minPlayers: 2,
      maxPlayers: 4,
    );

    final snapshot = await suggestions();
    expect(snapshot.docs, hasLength(2));
    final catan = snapshot.docs
        .map((doc) => doc.data())
        .firstWhere((data) => data['title'] == 'Catan');
    expect(
      catan.keys,
      unorderedEquals([
        'title', 'description', 'minPlayers', 'maxPlayers', 'userId', 'createdAt',
      ]),
    );
    expect(catan['userId'], 'anna');
    expect(catan['description'], 'Gemeinsam eine Insel besiedeln.');
    expect(catan['createdAt'], isNotNull);
  });

  test('gleiche Min/Max-Grenze ist erlaubt', () async {
    await repo.add(
      userId: 'anna',
      title: 'Schach',
      description: '',
      minPlayers: 2,
      maxPlayers: 2,
    );
    expect((await suggestions()).docs, hasLength(1));
  });

  test('eigene Bearbeitung behält ID, Urheber und Erstellungszeit', () async {
    final id = await ownSuggestion();
    final before = (await suggestions()).docs.single.data();
    await repo.update(
      suggestionId: id,
      userId: 'anna',
      title: '  Catan aktualisiert  ',
      description: ' Neue Beschreibung. ',
      minPlayers: 4,
      maxPlayers: 4,
    );
    final docs = (await suggestions()).docs;
    expect(docs, hasLength(1));
    expect(docs.single.id, id);
    final after = docs.single.data();
    expect(after['title'], 'Catan aktualisiert');
    expect(after['description'], 'Neue Beschreibung.');
    expect(after['minPlayers'], 4);
    expect(after['maxPlayers'], 4);
    expect(after['userId'], before['userId']);
    expect(after['createdAt'], before['createdAt']);
  });

  test('ungültige Bearbeitung lässt gespeicherte Inhalte unverändert', () async {
    final id = await ownSuggestion();
    final before = (await suggestions()).docs.single.data();
    for (final title in ['   ', List.filled(141, 'a').join()]) {
      await expectLater(
        repo.update(
          suggestionId: id,
          userId: 'anna',
          title: title,
          description: 'Darf nicht gespeichert werden.',
          minPlayers: 3,
          maxPlayers: 4,
        ),
        throwsA(isA<EventFailure>()),
      );
    }
    await expectLater(
      repo.update(
        suggestionId: id,
        userId: 'anna',
        title: 'Gültiger Titel',
        description: '',
        minPlayers: 5,
        maxPlayers: 2,
      ),
      throwsA(isA<EventFailure>()),
    );
    expect((await suggestions()).docs.single.data(), before);
  });

  test('fremde Vorschläge können nicht bearbeitet oder gelöscht werden', () async {
    final id = await ownSuggestion();
    final before = (await suggestions()).docs.single.data();
    await expectLater(
      repo.update(
        suggestionId: id,
        userId: 'ben',
        title: 'Fremde Änderung',
        description: '',
        minPlayers: 2,
        maxPlayers: 4,
      ),
      throwsA(isA<EventFailure>()),
    );
    await expectLater(
      repo.delete(suggestionId: id, userId: 'ben'),
      throwsA(isA<EventFailure>()),
    );
    expect((await suggestions()).docs.single.data(), before);
  });

  test('Löschen entfernt nur den ausgewählten eigenen Vorschlag', () async {
    final id = await ownSuggestion();
    await repo.add(
      userId: 'ben',
      title: 'Azul',
      description: '',
      minPlayers: 2,
      maxPlayers: 4,
    );
    await repo.delete(suggestionId: id, userId: 'anna');
    final docs = (await suggestions()).docs;
    expect(docs, hasLength(1));
    expect(docs.single.data()['title'], 'Azul');
    expect(docs.single.data()['userId'], 'ben');
  });

  test('gelöschter Vorschlag wird beim Bearbeiten nicht neu angelegt', () async {
    final id = await ownSuggestion();
    await repo.delete(suggestionId: id, userId: 'anna');
    await expectLater(
      repo.update(
        suggestionId: id,
        userId: 'anna',
        title: 'Darf nicht neu entstehen',
        description: '',
        minPlayers: 2,
        maxPlayers: 4,
      ),
      throwsA(isA<EventFailure>()),
    );
    expect((await suggestions()).docs, isEmpty);
  });

  test('ungültige Eingaben werden abgelehnt und nichts gespeichert', () async {
    Future<void> add(String title, int min, int max) => repo.add(
      userId: 'anna',
      title: title,
      description: '',
      minPlayers: min,
      maxPlayers: max,
    );

    await expectLater(add('   ', 2, 4), throwsA(isA<EventFailure>()));
    await expectLater(
      add(List.filled(141, 'a').join(), 2, 4),
      throwsA(
        isA<EventFailure>().having(
          (error) => error.message,
          'message',
          'Der Titel darf maximal 140 Zeichen lang sein.',
        ),
      ),
    );
    await expectLater(add('Spiel', 0, 4), throwsA(isA<EventFailure>()));
    await expectLater(add('Spiel', 2, 0), throwsA(isA<EventFailure>()));
    await expectLater(add('Spiel', 4, 2), throwsA(isA<EventFailure>()));
    expect((await suggestions()).docs, isEmpty);
  });

  test('Titel mit genau 140 Zeichen und Beschreibung wird gespeichert', () async {
    final title140 = List.filled(140, 'a').join();
    await repo.add(
      userId: 'anna',
      title: '  $title140  ',
      description: 'Ein Spiel ohne Terminbindung.',
      minPlayers: 2,
      maxPlayers: 4,
    );
    final data = (await suggestions()).docs.single.data();
    expect(data['title'], title140);
    expect(
      data.keys,
      unorderedEquals([
        'title', 'description', 'minPlayers', 'maxPlayers', 'userId', 'createdAt',
      ]),
    );
  });

  test('Vorschlagen benötigt keinen Termin und ignoriert dessen Status', () async {
    // Das erste Spiel wird gespeichert, obwohl die Events-Kollektion leer ist.
    await repo.add(
      userId: 'anna',
      title: 'Ohne Termin',
      description: '',
      minPlayers: 2,
      maxPlayers: 4,
    );
    for (final status in ['planned', 'active', 'completed']) {
      await db.collection('events').doc('nur-zum-testen').set({
        'status': status,
      });
      await repo.add(
        userId: 'ben',
        title: 'Weiterer Vorschlag bei $status',
        description: '',
        minPlayers: 2,
        maxPlayers: 4,
      );
    }
    final docs = (await suggestions()).docs;
    expect(docs, hasLength(4));
    expect(docs.map((doc) => doc.data()['userId']), containsAll(['anna', 'ben']));
    expect(
      (await db.collection('events').doc('nur-zum-testen')
          .collection('gameSuggestions').get()).docs,
      isEmpty,
    );
  });

  test('Stream ist stabil nach createdAt, dann nach ID sortiert', () async {
    final col = db.collection('gameSuggestions');
    Map<String, dynamic> data(String title, DateTime at) => {
      'title': title,
      'description': '',
      'minPlayers': 2,
      'maxPlayers': 4,
      'userId': 'anna',
      'createdAt': Timestamp.fromDate(at),
    };
    await col.doc('z1').set(data('Früh', DateTime(2026, 11, 20, 10)));
    await col.doc('m1').set(data('Spät B', DateTime(2026, 11, 20, 11)));
    await col.doc('a1').set(data('Spät A', DateTime(2026, 11, 20, 11)));

    final list = await repo.watch().first;
    expect(list.map((s) => s.title), ['Früh', 'Spät A', 'Spät B']);
  });
}