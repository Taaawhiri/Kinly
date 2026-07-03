import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Aggiornamento beta disponibile: numero di build, link diretto all'APK
/// su GitHub Releases e note di rilascio (facoltative).
class UpdateInfo {
  const UpdateInfo({required this.buildNumber, required this.downloadUrl, this.notes});

  final int buildNumber;
  final String downloadUrl;
  final String? notes;
}

/// Controlla se è disponibile una build più recente di quella installata,
/// pubblicata automaticamente da GitHub Actions ad ogni push sul branch di
/// sviluppo (vedi .github/workflows/build-apk.yml) come GitHub Release
/// pubblica — nessun token necessario, la repo è pubblica.
///
/// Pensato solo per i beta tester (vedi profiles.is_beta_tester). L'APK
/// viene scaricato QUI dentro l'app (non passando dal browser di sistema:
/// aprire l'URL con un Intent esterno faceva restare il download di Chrome
/// bloccato al 99% su alcuni dispositivi, un bug noto di Chrome per i
/// download avviati da un'altra app, non risolvibile lato nostro). Una
/// volta scaricato, aprirlo (vedi privacy_security_screen.dart, con
/// OpenFilex) fa comunque comparire la schermata di installazione di
/// sistema: quel tocco resta manuale, come per qualunque APK non
/// distribuito dal Play Store.
class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  static const _latestReleaseUrl = 'https://api.github.com/repos/Taaawhiri/Kinly/releases/latest';

  /// Incorporato in fase di build (vedi --dart-define=BUILD_NUMBER nel
  /// workflow): 0 per una build locale di sviluppo, mai per una beta vera.
  static int get currentBuildNumber => int.tryParse(const String.fromEnvironment('BUILD_NUMBER', defaultValue: '0')) ?? 0;

  static final _tagPattern = RegExp(r'beta-(\d+)');

  /// Scarica l'APK nella cache dell'app (non nei Download pubblici: non
  /// serve più nulla lì una volta installato) riportando l'avanzamento via
  /// [onProgress] (0.0-1.0). Il file va poi aperto con OpenFilex per far
  /// comparire la schermata di installazione di sistema.
  Future<String> downloadApk(String url, {void Function(double progress)? onProgress}) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw Exception('Download fallito (${response.statusCode})');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kinly_update.apk');
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Torna null se non c'è un aggiornamento (o in caso di qualunque errore
  /// di rete/formato): un controllo aggiornamenti fallito non deve mai
  /// interrompere l'uso dell'app.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_latestReleaseUrl), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return parseRelease(jsonDecode(response.body) as Map<String, dynamic>, currentBuildNumber);
    } catch (_) {
      return null;
    }
  }

  /// Logica pura di lettura di una risposta "releases/latest" di GitHub,
  /// separata da [checkForUpdate] per poterla testare senza rete.
  static UpdateInfo? parseRelease(Map<String, dynamic> release, int currentBuildNumber) {
    final tag = release['tag_name'] as String? ?? '';
    final match = _tagPattern.firstMatch(tag);
    if (match == null) return null;

    final buildNumber = int.parse(match.group(1)!);
    if (buildNumber <= currentBuildNumber) return null;

    final assets = release['assets'] as List? ?? [];
    String? downloadUrl;
    for (final asset in assets) {
      final name = (asset as Map<String, dynamic>)['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'] as String?;
        break;
      }
    }
    if (downloadUrl == null) return null;

    return UpdateInfo(buildNumber: buildNumber, downloadUrl: downloadUrl, notes: release['body'] as String?);
  }
}
