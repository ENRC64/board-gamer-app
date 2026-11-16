import 'package:intl/intl.dart';

/// Hilfsfunktionen für Datum und Uhrzeit auf Deutsch.
///
/// Voraussetzung: `initializeDateFormatting('de_DE')` wurde beim Start
/// aufgerufen (siehe `main.dart`), sonst kennt `intl` die deutschen
/// Monats- und Wochentagsnamen nicht.
abstract final class AppDate {
  static const _locale = 'de_DE';

  /// z. B. „Freitag, 4. Dezember 2026“
  static String longDate(DateTime d) =>
      DateFormat('EEEE, d. MMMM y', _locale).format(d);

  /// z. B. „19:00 Uhr“
  static String time(DateTime d) => '${DateFormat.Hm(_locale).format(d)} Uhr';

  /// z. B. „04.12.2026, 19:00“
  static String short(DateTime d) =>
      DateFormat('dd.MM.y, HH:mm', _locale).format(d);

  /// Countdown bis [target] als Text, z. B. „in 3 Tagen und 4 Stunden“.
  static String countdown(DateTime target, DateTime now) {
    final diff = target.difference(now);
    if (diff.inMinutes < 1) return 'jetzt';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) {
      return hours > 0
          ? 'in ${_plural(days, 'Tag', 'Tagen')} und '
                '${_plural(hours, 'Stunde', 'Stunden')}'
          : 'in ${_plural(days, 'Tag', 'Tagen')}';
    }
    if (hours > 0) {
      return minutes > 0
          ? 'in ${_plural(hours, 'Stunde', 'Stunden')} und '
                '${_plural(minutes, 'Minute', 'Minuten')}'
          : 'in ${_plural(hours, 'Stunde', 'Stunden')}';
    }
    return 'in ${_plural(minutes, 'Minute', 'Minuten')}';
  }

  /// Vergangene Zeit als Text, z. B. „vor 5 Min.“ (Statusverlauf).
  static String ago(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inHours < 1) return 'vor ${diff.inMinutes} Min.';
    if (diff.inDays < 1) return 'vor ${diff.inHours} Std.';
    return short(then);
  }

  static String _plural(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';
}

/// Link, der die Adresse in Google Maps (App oder Browser) öffnet.
Uri mapsUri(String address) => Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query': address,
});
