import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Ridimensiona e ricomprime una foto profilo prima di caricarla: una foto
/// scattata con la fotocamera può pesare diversi MB, ma verrà scaricata da
/// OGNI membro della cerchia che vede quella persona (avatar in lista,
/// mappa, dettaglio...). Senza ridurla qui, il consumo di banda del piano
/// gratuito di Supabase salirebbe di colpo. 256x256 (ritagliata al centro,
/// quadrata) basta abbondantemente per un avatar circolare.
Uint8List resizeProfilePhoto(Uint8List bytes, {int size = 256}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final cropSize = decoded.width < decoded.height ? decoded.width : decoded.height;
  final cropX = (decoded.width - cropSize) ~/ 2;
  final cropY = (decoded.height - cropSize) ~/ 2;
  final cropped = img.copyCrop(decoded, x: cropX, y: cropY, width: cropSize, height: cropSize);
  final resized = img.copyResize(cropped, width: size, height: size, interpolation: img.Interpolation.average);

  return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
}
