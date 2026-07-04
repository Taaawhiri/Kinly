import 'package:flutter/material.dart';

/// Icona batteria coerente ovunque nell'app in base alla percentuale
/// (dettaglio persona, lista persone, ecc.): stesse soglie per non avere
/// due punti dell'app che "raccontano" la stessa batteria in modo diverso.
IconData batteryIconFor(int percent) {
  if (percent >= 80) return Icons.battery_full;
  if (percent >= 40) return Icons.battery_5_bar;
  if (percent >= 15) return Icons.battery_2_bar;
  return Icons.battery_alert;
}
