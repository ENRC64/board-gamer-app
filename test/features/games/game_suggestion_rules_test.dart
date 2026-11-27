import 'package:board_gamer_app/features/games/domain/game_suggestion_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateTitle', () {
    test('leere und nur aus Leerzeichen bestehende Titel sind ungültig', () {
      for (final title in ['', '   ']) {
        expect(validateTitle(title), 'Titel eingeben.');
      }
    });

    test('akzeptiert Titel mit höchstens 140 Runen nach dem Trimmen', () {
      final title140 = List.filled(140, 'a').join();

      expect(validateTitle(title140), isNull);
      expect(validateTitle('  $title140  '), isNull);
      expect(validateTitle('${List.filled(139, 'a').join()}😀'), isNull);
    });

    test('lehnt Titel mit mehr als 140 Runen ab', () {
      final title141 = List.filled(141, 'a').join();

      expect(
        validateTitle(title141),
        'Der Titel darf maximal 140 Zeichen lang sein.',
      );
      expect(
        validateTitle('  $title141  '),
        'Der Titel darf maximal 140 Zeichen lang sein.',
      );
    });
  });

  group('parsePlayerCount', () {
    test('parst positive ganze Zahlen auch mit äußeren Leerzeichen', () {
      expect(parsePlayerCount('4'), 4);
      expect(parsePlayerCount('  12  '), 12);
    });

    test('gibt für ungültige Eingaben null zurück', () {
      for (final value in ['', 'Text', '1.5', null, '0', '-1']) {
        expect(parsePlayerCount(value), isNull);
      }
    });
  });

  group('validatePlayerCount', () {
    test('gibt für gültige Spielerzahlen null zurück', () {
      expect(validatePlayerCount(' 3 '), isNull);
    });

    test('meldet ungültige Spielerzahlen', () {
      for (final value in ['', 'Text', '1.5', null, '0', '-1']) {
        expect(validatePlayerCount(value), 'Ganze Zahl > 0 eingeben.');
      }
    });
  });

  group('validatePlayerRange', () {
    test('akzeptiert aufsteigende und gleiche Grenzen', () {
      expect(validatePlayerRange(2, 4), isNull);
      expect(validatePlayerRange(4, 4), isNull);
    });

    test('lehnt eine maximale Spielerzahl unter dem Minimum ab', () {
      expect(
        validatePlayerRange(4, 2),
        'Die maximale Spielerzahl muss größer oder gleich der Mindestzahl sein.',
      );
    });
  });

  group('playerCountLabel', () {
    test('formatiert einzelne Spielerzahlen und einen Spielerbereich', () {
      expect(playerCountLabel(1, 1), '1 Spieler');
      expect(playerCountLabel(4, 4), '4 Spieler');
      expect(playerCountLabel(2, 4), '2–4 Spieler');
    });
  });
}
