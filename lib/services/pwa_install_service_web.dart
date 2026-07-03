import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('kinlyPwaCanInstall')
external bool _canInstallJS();

@JS('kinlyPwaIsStandalone')
external bool _isStandaloneJS();

@JS('kinlyPwaIsIOS')
external bool _isIOSJS();

@JS('kinlyPwaPromptInstall')
external JSPromise<JSBoolean> _promptInstallJS();

/// Implementazione web: si appoggia al piccolo ponte JS in web/index.html
/// che intercetta l'evento beforeinstallprompt (non standard, non
/// tipizzato da package:web) e lo espone come funzioni globali semplici.
class PwaInstallServiceImpl {
  PwaInstallServiceImpl() {
    web.window.addEventListener('kinly-pwa-can-install-changed', _onChanged.toJS);
  }

  final _controller = StreamController<bool>.broadcast();

  void _onChanged(web.Event _) => _controller.add(canInstall);

  bool get isSupported => true;
  bool get isIOS => _isIOSJS();
  bool get isStandalone => _isStandaloneJS();
  bool get canInstall => _canInstallJS();
  Stream<bool> get canInstallStream => _controller.stream;

  Future<bool> promptInstall() => _promptInstallJS().toDart.then((v) => v.toDart);
}
