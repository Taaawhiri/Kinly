import Flutter
import UIKit
import CoreLocation
import CoreMotion

/// Tracciamento in background "vero" su iOS: il Significant Location
/// Change Service sveglia l'app (anche se il sistema l'ha sospesa o
/// terminata per inattività/memoria — non se l'utente la chiude a forza,
/// limite di iOS impossibile da aggirare) ogni volta che il dispositivo si
/// sposta di alcune centinaia di metri, usando le celle telefoniche invece
/// del GPS continuo: molto più parco di batteria della sola
/// allowBackgroundLocationUpdates (vedi LocationTracker._buildLocationSettings
/// lato Dart), che smette di funzionare non appena il sistema sospende
/// l'app. CoreMotion decide se vale la pena affinare la posizione
/// approssimativa dell'SLC con un breve fix GPS preciso (solo se il
/// telefono risulta davvero in movimento), invece di accendere sempre il
/// GPS e vanificare il risparmio energetico.
@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var significantLocationManager: CLLocationManager?

  /// Manager separato e temporaneo per il fix preciso dopo un evento SLC:
  /// acceso solo per pochi secondi (vedi startLocationBurst), mai lasciato
  /// attivo, altrimenti si perderebbe il risparmio di batteria che l'SLC
  /// dovrebbe garantire.
  private var burstLocationManager: CLLocationManager?
  private var burstTimeoutTimer: Timer?

  private let motionActivityManager = CMMotionActivityManager()
  private var backgroundChannel: FlutterMethodChannel?

  private static let pendingLocationDefaultsKey = "kinly_pending_background_location"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "kinly/background_location", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "startSignificantLocationMonitoring":
          self?.startSignificantLocationMonitoring()
          result(nil)
        case "stopSignificantLocationMonitoring":
          self?.stopSignificantLocationMonitoring()
          result(nil)
        case "consumePendingBackgroundLocation":
          result(self?.consumePendingBackgroundLocation())
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      backgroundChannel = channel
    }

    // Il sistema può rilanciare l'app in background specificamente per un
    // evento di localizzazione, senza che l'utente l'abbia aperta: bisogna
    // ricreare subito il location manager qui, in modo sincrono — Apple
    // richiede che avvenga in questo metodo, non più tardi, altrimenti
    // l'evento va perso.
    if launchOptions?[.location] != nil {
      startSignificantLocationMonitoring()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startSignificantLocationMonitoring() {
    guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
    let manager = significantLocationManager ?? CLLocationManager()
    manager.delegate = self
    manager.startMonitoringSignificantLocationChanges()
    significantLocationManager = manager
  }

  private func stopSignificantLocationMonitoring() {
    significantLocationManager?.stopMonitoringSignificantLocationChanges()
    significantLocationManager = nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    if manager === burstLocationManager {
      finishBurst(with: location)
    } else if manager === significantLocationManager {
      consultMotionThenMaybeRefine(fallback: location)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if manager === burstLocationManager {
      // Niente fix preciso disponibile: non lasciamo il burst acceso in
      // attesa di qualcosa che non arriverà.
      burstTimeoutTimer?.invalidate()
      burstTimeoutTimer = nil
      burstLocationManager?.stopUpdatingLocation()
      burstLocationManager = nil
    }
  }

  /// Un evento SLC da solo è impreciso (da qualche centinaio di metri a
  /// pochi km): decidiamo se vale la pena di un fix GPS preciso guardando
  /// l'attività recente rilevata da CoreMotion, invece di accendere sempre
  /// il GPS anche quando il telefono è semplicemente fermo su un tavolo.
  private func consultMotionThenMaybeRefine(fallback: CLLocation) {
    guard CMMotionActivityManager.isActivityAvailable() else {
      sendLocation(fallback)
      return
    }
    let now = Date()
    motionActivityManager.queryActivityStarting(from: now.addingTimeInterval(-180), to: now, to: .main) { [weak self] activities, _ in
      guard let self = self else { return }
      let latest = activities?.last
      let isMoving = (latest?.walking ?? false) || (latest?.running ?? false) || (latest?.automotive ?? false) || (latest?.cycling ?? false)
      if isMoving {
        self.startLocationBurst(fallback: fallback)
      } else {
        // Fermo: l'evento SLC (per quanto approssimativo) basta, niente
        // GPS acceso per una precisione che qui non serve davvero.
        self.sendLocation(fallback)
      }
    }
  }

  private func startLocationBurst(fallback: CLLocation) {
    burstTimeoutTimer?.invalidate()
    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.startUpdatingLocation()
    burstLocationManager = manager
    // Non deve mai restare acceso a lungo: se non arriva un fix buono entro
    // pochi secondi si ripiega sulla posizione approssimativa dell'SLC,
    // piuttosto che consumare batteria in background senza limite.
    burstTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
      self?.finishBurst(with: fallback)
    }
  }

  private func finishBurst(with location: CLLocation) {
    burstTimeoutTimer?.invalidate()
    burstTimeoutTimer = nil
    burstLocationManager?.stopUpdatingLocation()
    burstLocationManager = nil
    sendLocation(location)
  }

  /// Prova a consegnare subito la posizione a Flutter via method channel, e
  /// la salva SEMPRE anche in UserDefaults. Se l'app è stata rilanciata dal
  /// sistema solo per questo evento, l'isolate Dart potrebbe non aver
  /// ancora finito di registrare il proprio handler quando questa chiamata
  /// parte: senza una copia persistita, quell'aggiornamento andrebbe perso
  /// invece di essere recuperato al prossimo avvio (vedi
  /// consumePendingBackgroundLocation, richiamato da Dart ad ogni start()).
  private func sendLocation(_ location: CLLocation) {
    let args: [String: Any] = [
      "lat": location.coordinate.latitude,
      "lng": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy,
      "timestampMs": Int(location.timestamp.timeIntervalSince1970 * 1000)
    ]
    if let data = try? JSONSerialization.data(withJSONObject: args), let json = String(data: data, encoding: .utf8) {
      UserDefaults.standard.set(json, forKey: AppDelegate.pendingLocationDefaultsKey)
    }
    backgroundChannel?.invokeMethod("onBackgroundLocation", arguments: args)
  }

  private func consumePendingBackgroundLocation() -> String? {
    let defaults = UserDefaults.standard
    let json = defaults.string(forKey: AppDelegate.pendingLocationDefaultsKey)
    defaults.removeObject(forKey: AppDelegate.pendingLocationDefaultsKey)
    return json
  }
}
