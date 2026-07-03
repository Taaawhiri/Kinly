import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/weather_service.dart';

/// Card del meteo nel punto dato: uno sguardo veloce a cosa sta vivendo un
/// membro della cerchia ("piove da nonna?"), senza dover cercare altrove.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, required this.lat, required this.lng, this.placeLabel});

  final double lat;
  final double lng;
  final String? placeLabel;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late Future<WeatherInfo?> _future;

  @override
  void initState() {
    super.initState();
    _future = WeatherService.instance.fetch(widget.lat, widget.lng);
  }

  @override
  void didUpdateWidget(covariant WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _future = WeatherService.instance.fetch(widget.lat, widget.lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherInfo?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final weather = snapshot.data!;
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: weather.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: weather.gradient.last.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Icon(weather.icon, color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperatureCelsius.round()}°',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      widget.placeLabel != null ? '${weather.label(l10n)} · ${widget.placeLabel}' : weather.label(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
