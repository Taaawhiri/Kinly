import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';

/// Meteo attuale in un punto, tradotto dal codice WMO di Open-Meteo (API
/// gratuita, senza chiave) in qualcosa di leggibile in italiano.
class WeatherInfo {
  const WeatherInfo({required this.temperatureCelsius, required this.code, required this.isDay});

  final double temperatureCelsius;
  final int code;
  final bool isDay;

  String label(AppLocalizations l10n) => _labelForCode(code, l10n);
  IconData get icon => _iconForCode(code, isDay);

  /// Colori del gradiente della card, coerenti con condizione e ora del
  /// giorno (più caldi/chiari di giorno con sole, più scuri di notte).
  List<Color> get gradient {
    if (!isDay) return const [Color(0xFF232B4D), Color(0xFF171C36)];
    if (code == 0 || code == 1) return const [Color(0xFF4FA8E8), Color(0xFF2E7BC7)];
    if (code <= 3) return const [Color(0xFF8FA3BF), Color(0xFF64768F)];
    if (code == 45 || code == 48) return const [Color(0xFFA9AFB8), Color(0xFF7C828C)];
    if (code >= 51 && code <= 67) return const [Color(0xFF5C7A99), Color(0xFF3C5670)];
    if (code >= 71 && code <= 86) return const [Color(0xFF9FB4C9), Color(0xFF6E8AA3)];
    if (code >= 95) return const [Color(0xFF4A4468), Color(0xFF2C2846)];
    return const [Color(0xFF4FA8E8), Color(0xFF2E7BC7)];
  }

  static String _labelForCode(int code, AppLocalizations l10n) {
    if (code == 0) return l10n.weatherClear;
    if (code <= 2) return l10n.weatherPartlyCloudy;
    if (code == 3) return l10n.weatherOvercast;
    if (code == 45 || code == 48) return l10n.weatherFog;
    if (code >= 51 && code <= 57) return l10n.weatherDrizzle;
    if (code >= 61 && code <= 67) return l10n.weatherRain;
    if (code >= 71 && code <= 77) return l10n.weatherSnow;
    if (code >= 80 && code <= 82) return l10n.weatherShowers;
    if (code >= 85 && code <= 86) return l10n.weatherSnowShowers;
    if (code >= 95) return l10n.weatherStorm;
    return l10n.weatherNow;
  }

  static IconData _iconForCode(int code, bool isDay) {
    if (code == 0) return isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
    if (code <= 2) return isDay ? Icons.wb_cloudy_rounded : Icons.nightlight_round;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.umbrella_rounded;
    if (code >= 85 && code <= 86) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.thermostat_rounded;
  }
}

class WeatherService {
  WeatherService._();
  static final instance = WeatherService._();

  static const _ttl = Duration(minutes: 30);
  final Map<String, _CacheEntry> _cache = {};

  /// Arrotonda le coordinate per non rifare la stessa chiamata per
  /// spostamenti piccoli: il meteo non cambia in modo apprezzabile su
  /// pochi km, quindi la cache è per zona, non per punto esatto.
  Future<WeatherInfo?> fetch(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _ttl) {
      return cached.info;
    }
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code,is_day',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return null;
      final info = WeatherInfo(
        temperatureCelsius: (current['temperature_2m'] as num).toDouble(),
        code: (current['weather_code'] as num).toInt(),
        isDay: (current['is_day'] as num).toInt() == 1,
      );
      _cache[key] = _CacheEntry(info, DateTime.now());
      return info;
    } catch (_) {
      return null;
    }
  }
}

class _CacheEntry {
  _CacheEntry(this.info, this.fetchedAt);
  final WeatherInfo info;
  final DateTime fetchedAt;
}
