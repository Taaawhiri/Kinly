import 'dart:io';
import 'package:flutter/services.dart';

/// Su molti telefoni Android (Samsung, Xiaomi, Huawei e simili sono i casi
/// più aggressivi) il sistema "addormenta" le app in background per
/// risparmiare batteria, anche con "Tracciamento in background" attivo: il
/// processo di Kinly può essere sospeso del tutto, non solo lo stream di
/// posizione, e a quel punto nessun riavvio automatico lato Dart può
/// aiutare perché il codice semplicemente non gira più. L'unica soluzione
/// reale è escludere Kinly dall'ottimizzazione batteria di sistema.
///
/// Non esposto da nessun pacchetto già usato nel progetto: canale nativo
/// minimo definito in MainActivity.kt.
class BatteryOptimizationService {
  BatteryOptimizationService._();
  static final instance = BatteryOptimizationService._();

  static const _channel = MethodChannel('com.kinly.app/battery');

  Future<bool> isIgnoringOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestIgnoreOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {
      // Non deve mai bloccare il resto del flusso di attivazione.
    }
  }
}
