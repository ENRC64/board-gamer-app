// Tests für initialsOf: Initialen aus Namen, Leerzeichen und Unicode.

import 'package:board_gamer_app/core/utils/name_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nimmt die Initialen aus Vor- und Nachname', () {
    expect(initialsOf('Anna Adler'), 'AA');
  });
  test('Verwendet bei mehreren Vornamen den ersten und letzten Namensteil', () {
    expect(initialsOf('Anna Maria Adler'), 'AA');
  });
  test('Ignoriert führende, folgende und mehrfache Leerzeichen', () {
    expect(initialsOf('  Anna   Maria   Adler  '), 'AA');
  });
  test('Ein einzelner Namensteil ergibt eine Initiale', () {
    expect(initialsOf('Anna'), 'A');
  });
  test(
    'Ein leerer oder nur aus Leerzeichen bestehender Name ergibt Fragezeichen',
    () {
      expect(initialsOf(''), '?');
      expect(initialsOf('   '), '?');
    },
  );
  test('Liest Unicode-Zeichen vollständig', () {
    expect(initialsOf('😀 Adler'), '😀A');
  });
}
