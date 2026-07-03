import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/services/app_update_service.dart';

/// Test sulla logica pura di lettura di una release GitHub: nessuna rete,
/// così girano ovunque e non dipendono dallo stato reale della repo.
void main() {
  group('AppUpdateService.parseRelease', () {
    test('trova un aggiornamento quando il tag è più recente del build corrente', () {
      final result = AppUpdateService.parseRelease({
        'tag_name': 'beta-42',
        'body': 'Novità di questa build.',
        'assets': [
          {'name': 'app-release.apk', 'browser_download_url': 'https://example.com/app-release.apk'},
        ],
      }, 40);

      expect(result, isNotNull);
      expect(result!.buildNumber, 42);
      expect(result.downloadUrl, 'https://example.com/app-release.apk');
      expect(result.notes, 'Novità di questa build.');
    });

    test('nessun aggiornamento se il tag non è più recente del build corrente', () {
      final result = AppUpdateService.parseRelease({
        'tag_name': 'beta-10',
        'assets': [
          {'name': 'app-release.apk', 'browser_download_url': 'https://example.com/app-release.apk'},
        ],
      }, 10);

      expect(result, isNull);
    });

    test('nessun aggiornamento se il tag non segue il formato beta-<numero>', () {
      final result = AppUpdateService.parseRelease({
        'tag_name': 'v1.0.0',
        'assets': [
          {'name': 'app-release.apk', 'browser_download_url': 'https://example.com/app-release.apk'},
        ],
      }, 0);

      expect(result, isNull);
    });

    test('nessun aggiornamento se la release non ha un asset .apk', () {
      final result = AppUpdateService.parseRelease({
        'tag_name': 'beta-99',
        'assets': <Map<String, dynamic>>[],
      }, 0);

      expect(result, isNull);
    });
  });
}
