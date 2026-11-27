// Widget-Tests für den GamesScreen: Gruppen, Leerzustand sowie Anlegen,
// Bearbeiten und Löschen von Vorschlägen.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  late FakeFirebaseFirestore db;

  Future<void> addUser(String uid, String name, int day) =>
      db.collection('users').doc(uid).set({
        'displayName': name,
        'email': '$uid@x.de',
        'address': 'Weg 1',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, day)),
      });

  Future<void> addSuggestion(
    String userId,
    String title,
    int min,
    int max,
    int hour,
  ) => db.collection('gameSuggestions').add({
    'title': title,
    'description': 'Beschreibung zu $title',
    'minPlayers': min,
    'maxPlayers': max,
    'userId': userId,
    'createdAt': Timestamp.fromDate(DateTime(2026, 11, 20, hour)),
  });

  Future<void> openGames(WidgetTester tester, String uid) async {
    await pumpApp(
      tester,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: uid, email: '$uid@x.de', displayName: uid),
      ),
      firestore: db,
    );
    await tester.tap(find.text('Spiele').last);
    await tester.pumpAndSettle();
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    await addUser('anna', 'Anna Schmidt', 1);
    await addUser('ben', 'Ben Meyer', 2);
  });

  testWidgets('Leerzustand: beide Gruppen mit eigenem Hinweis', (tester) async {
    await openGames(tester, 'ben');
    expect(find.text('Von dir vorgeschlagen'), findsOneWidget);
    expect(find.text('Du hast noch kein Spiel vorgeschlagen.'), findsOneWidget);
    expect(find.text('Von anderen vorgeschlagen'), findsOneWidget);
    expect(
      find.text('Andere haben noch kein Spiel vorgeschlagen.'),
      findsOneWidget,
    );
  });

  testWidgets('Eigene und fremde Vorschläge getrennt, mit Initialen', (
    tester,
  ) async {
    await addSuggestion('ben', 'Azul', 2, 2, 10);
    await addSuggestion('anna', 'Catan', 3, 4, 11);
    await openGames(tester, 'ben');

    expect(find.text('Azul'), findsOneWidget);
    expect(find.text('2 Spieler'), findsOneWidget);
    expect(find.text('Catan'), findsOneWidget);
    expect(find.text('3–4 Spieler'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.textContaining('Beschreibung zu Catan'), findsOneWidget);
    expect(find.text('Du hast noch kein Spiel vorgeschlagen.'), findsNothing);

    final own = tester.getTopLeft(find.text('Azul')).dy;
    final other = tester.getTopLeft(find.text('Catan')).dy;
    expect(own, lessThan(other));
  });

  testWidgets('nur eigene Vorschläge haben Bearbeiten- und Löschen-Aktionen', (
    tester,
  ) async {
    await addSuggestion('ben', 'Azul', 2, 2, 10);
    await addSuggestion('anna', 'Catan', 3, 4, 11);
    final docs = (await db.collection('gameSuggestions').get()).docs;
    final ownId = docs.firstWhere((doc) => doc.data()['userId'] == 'ben').id;
    final otherId = docs.firstWhere((doc) => doc.data()['userId'] == 'anna').id;
    await openGames(tester, 'ben');
    expect(find.byKey(Key('editSuggestion-$ownId')), findsOneWidget);
    expect(find.byKey(Key('deleteSuggestion-$ownId')), findsOneWidget);
    expect(find.byKey(Key('editSuggestion-$otherId')), findsNothing);
    expect(find.byKey(Key('deleteSuggestion-$otherId')), findsNothing);
  });

  testWidgets('Bearbeiten verwendet vorhandenes Dokument und neue Inhalte', (
    tester,
  ) async {
    await addSuggestion('ben', 'Azul', 2, 2, 10);
    final original = (await db.collection('gameSuggestions').get()).docs.single;
    await openGames(tester, 'ben');
    await tester.tap(find.byKey(Key('editSuggestion-${original.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Spiel bearbeiten'), findsOneWidget);
    final titleField = tester.widget<TextFormField>(
      find.byKey(const Key('suggestionTitleField')),
    );
    expect(titleField.controller?.text, 'Azul');
    await tester.enterText(
      find.byKey(const Key('suggestionTitleField')),
      'Azul aktualisiert',
    );
    await tester.enterText(
      find.byKey(const Key('suggestionDescriptionField')),
      'Eine aktualisierte Beschreibung.',
    );
    await tester.ensureVisible(find.byKey(const Key('suggestionSaveButton')));
    await tester.tap(find.byKey(const Key('suggestionSaveButton')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final after = (await db.collection('gameSuggestions').get()).docs.single;
    expect(after.id, original.id);
    expect(after.data()['title'], 'Azul aktualisiert');
    expect(after.data()['description'], 'Eine aktualisierte Beschreibung.');
    expect(after.data()['createdAt'], original.data()['createdAt']);
    expect(after.data()['userId'], 'ben');
  });

  testWidgets('Löschen erfordert Bestätigung; Abbruch verändert nichts', (
    tester,
  ) async {
    await addSuggestion('ben', 'Azul', 2, 2, 10);
    final id = (await db.collection('gameSuggestions').get()).docs.single.id;
    await openGames(tester, 'ben');
    await tester.tap(find.byKey(Key('deleteSuggestion-$id')));
    await tester.pumpAndSettle();
    expect(find.text('Spielvorschlag löschen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect((await db.collection('gameSuggestions').get()).docs, hasLength(1));
    await tester.tap(find.byKey(Key('deleteSuggestion-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteSuggestionButton')));
    await tester.pumpAndSettle();
    expect((await db.collection('gameSuggestions').get()).docs, isEmpty);
    expect(find.text('Azul'), findsNothing);
    expect(find.text('Du hast noch kein Spiel vorgeschlagen.'), findsOneWidget);
  });

  testWidgets('Unbekanntes Profil zeigt Platzhalter statt Absturz', (
    tester,
  ) async {
    await addSuggestion('geist', 'Dixit', 3, 6, 10);
    await openGames(tester, 'ben');
    expect(find.text('Dixit'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('Speichern schließt den Dialog und legt das Dokument an', (
    tester,
  ) async {
    await openGames(tester, 'ben');
    await tester.tap(find.byKey(const Key('addSuggestionButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('suggestionTitleField')),
      'Carcassonne',
    );
    await tester.enterText(
      find.byKey(const Key('suggestionDescriptionField')),
      'Eine Landschaft aus Plättchen aufbauen.',
    );
    await tester.enterText(find.byKey(const Key('suggestionMinField')), '2');
    await tester.enterText(find.byKey(const Key('suggestionMaxField')), '5');
    await tester.tap(find.byKey(const Key('suggestionSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final docs = await db.collection('gameSuggestions').get();
    expect(docs.docs, hasLength(1));
    expect(docs.docs.single.data()['userId'], 'ben');
    expect(
      docs.docs.single.data()['description'],
      'Eine Landschaft aus Plättchen aufbauen.',
    );
    expect(find.text('Carcassonne'), findsOneWidget);
  });

  testWidgets('Ungültige Eingabe zeigt Fehler und speichert nichts', (
    tester,
  ) async {
    await openGames(tester, 'ben');
    await tester.tap(find.byKey(const Key('addSuggestionButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('suggestionTitleField')), 'X');
    await tester.enterText(find.byKey(const Key('suggestionMinField')), '4');
    await tester.enterText(find.byKey(const Key('suggestionMaxField')), '2');
    await tester.tap(find.byKey(const Key('suggestionSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text(
        'Die maximale Spielerzahl muss größer oder gleich der Mindestzahl sein.',
      ),
      findsOneWidget,
    );
    final docs = await db.collection('gameSuggestions').get();
    expect(docs.docs, isEmpty);
  });

  testWidgets('Titel mit 141 Zeichen: Fehler und keine Speicherung', (
    tester,
  ) async {
    await openGames(tester, 'ben');
    await tester.tap(find.byKey(const Key('addSuggestionButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('suggestionTitleField')),
      List.filled(141, 'a').join(),
    );
    await tester.enterText(find.byKey(const Key('suggestionMinField')), '2');
    await tester.enterText(find.byKey(const Key('suggestionMaxField')), '4');
    await tester.ensureVisible(find.byKey(const Key('suggestionSaveButton')));
    await tester.tap(find.byKey(const Key('suggestionSaveButton')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Der Titel darf maximal 140 Zeichen lang sein.'),
      findsOneWidget,
    );
    final docs = await db.collection('gameSuggestions').get();
    expect(docs.docs, isEmpty);
  });

  testWidgets('Terminstatuswechsel sperrt ein geöffnetes Formular nicht', (
    tester,
  ) async {
    await openGames(tester, 'ben');
    await tester.tap(find.byKey(const Key('addSuggestionButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('suggestionTitleField')),
      'Uno',
    );
    await tester.enterText(find.byKey(const Key('suggestionMinField')), '2');
    await tester.enterText(find.byKey(const Key('suggestionMaxField')), '8');

    await db.collection('events').doc('nur-zum-testen').set({
      'status': 'active',
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('suggestionSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Uno'), findsOneWidget);
    final docs = await db.collection('gameSuggestions').get();
    expect(docs.docs, hasLength(1));
  });

  testWidgets('Neue fremde Vorschläge erscheinen live ohne Termin', (
    tester,
  ) async {
    await openGames(tester, 'ben');
    expect(find.text('Catan'), findsNothing);
    expect(find.byKey(const Key('addSuggestionButton')), findsOneWidget);
    await addSuggestion('anna', 'Catan', 3, 4, 11);
    await tester.pumpAndSettle();
    expect(find.text('Catan'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.byKey(const Key('addSuggestionButton')), findsOneWidget);
  });
}
