/// Implementazione no-op per le piattaforme native (Android/iOS): l'app
/// installata da store è già "installata", non serve nessun prompt.
class PwaInstallServiceImpl {
  bool get isSupported => false;
  bool get isIOS => false;
  bool get isStandalone => false;
  bool get canInstall => false;
  Stream<bool> get canInstallStream => const Stream<bool>.empty();
  Future<bool> promptInstall() async => false;
}
