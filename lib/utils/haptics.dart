import 'package:flutter/services.dart';

/// Punto unico per il feedback tattile dell'app. Flutter non lo dà gratis sui
/// controlli normali (a differenza del suono di sistema su Android): va
/// richiesto esplicitamente, quindi lo centralizziamo qui invece di sparpagliare
/// chiamate dirette a HapticFeedback, cosicché l'intensità usata per ogni tipo
/// di azione resti coerente in tutta l'app.
abstract final class Haptics {
  /// Interruttori e selezioni di routine (Switch, opzioni di una lista).
  static void light() => HapticFeedback.lightImpact();

  /// Azioni con un impatto più concreto (es. attivare/disattivare Non
  /// disturbare o la Modalità Fantasma).
  static void medium() => HapticFeedback.mediumImpact();

  /// Azioni critiche per la sicurezza (SOS): l'intensità più alta deve
  /// comunicare da sola il peso dell'azione appena confermata.
  static void heavy() => HapticFeedback.heavyImpact();
}
