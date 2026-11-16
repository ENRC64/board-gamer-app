import 'package:board_gamer_app/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));
  final now = DateTime(2026, 11, 20, 12);

  test('Datum und Uhrzeit auf Deutsch', () {
    final d = DateTime(2026, 12, 4, 19);
    expect(AppDate.longDate(d), 'Freitag, 4. Dezember 2026');
    expect(AppDate.time(d), '19:00 Uhr');
    expect(AppDate.short(d), '04.12.2026, 19:00');
  });

  test('Countdown', () {
    expect(
      AppDate.countdown(DateTime(2026, 11, 23, 16), now),
      'in 3 Tagen und 4 Stunden',
    );
    expect(AppDate.countdown(DateTime(2026, 11, 21, 12), now), 'in 1 Tag');
    expect(
      AppDate.countdown(DateTime(2026, 11, 20, 14, 5), now),
      'in 2 Stunden und 5 Minuten',
    );
    expect(AppDate.countdown(DateTime(2026, 11, 20, 13), now), 'in 1 Stunde');
    expect(
      AppDate.countdown(DateTime(2026, 11, 20, 12, 1), now),
      'in 1 Minute',
    );
    expect(AppDate.countdown(DateTime(2026, 11, 20, 11), now), 'jetzt');
  });

  test('Vergangene Zeit', () {
    expect(AppDate.ago(now, now), 'gerade eben');
    expect(AppDate.ago(DateTime(2026, 11, 20, 11, 55), now), 'vor 5 Min.');
    expect(AppDate.ago(DateTime(2026, 11, 20, 9), now), 'vor 3 Std.');
    expect(AppDate.ago(DateTime(2026, 11, 18, 9), now), '18.11.2026, 09:00');
  });

  test('Karten-Link kodiert die Adresse', () {
    final uri = mapsUri('Hauptstr. 1, 10115 Berlin');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['query'], 'Hauptstr. 1, 10115 Berlin');
    expect(uri.queryParameters['api'], '1');
  });
}
