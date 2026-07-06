import 'package:flutter/material.dart';
import '../utils/haptics.dart';

/// Switch standard con un leggero feedback tattile al tocco, così attivare o
/// disattivare qualcosa si "sente" oltre che vedersi. Sostituisce Switch in
/// tutti i punti dell'app che ne fanno un uso semplice (solo value/onChanged).
class HapticSwitch extends StatelessWidget {
  const HapticSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: (v) {
        Haptics.light();
        onChanged(v);
      },
    );
  }
}
