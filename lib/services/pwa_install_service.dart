import 'pwa_install_service_stub.dart' if (dart.library.js_interop) 'pwa_install_service_web.dart' as impl;

/// Punto d'accesso al prompt "Installa app" del browser (solo web): su
/// Chrome/Edge Android intercetta il vero evento beforeinstallprompt, su
/// iOS Safari (dove quell'evento non esiste) segnala solo che va fatto a
/// mano da Condividi > Aggiungi alla schermata Home.
class PwaInstallService {
  PwaInstallService._() : _impl = impl.PwaInstallServiceImpl();
  static final instance = PwaInstallService._();

  final impl.PwaInstallServiceImpl _impl;

  bool get isSupported => _impl.isSupported;
  bool get isIOS => _impl.isIOS;
  bool get isStandalone => _impl.isStandalone;
  bool get canInstall => _impl.canInstall;
  Stream<bool> get canInstallStream => _impl.canInstallStream;
  Future<bool> promptInstall() => _impl.promptInstall();
}
