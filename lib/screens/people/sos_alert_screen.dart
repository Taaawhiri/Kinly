import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/person.dart';
import '../../models/sos_alert.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kinly_map.dart';

/// Dettaglio di un SOS: solo posizione (arrotondata mai, è un'emergenza),
/// nessuna registrazione audio. Chi l'ha attivato può segnarlo risolto.
class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key, required this.alert, required this.person});
  final SosAlert alert;
  final Person person;

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen> {
  String? _address;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    try {
      final placemarks = await placemarkFromCoordinates(widget.alert.lat, widget.alert.lng);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [if ((p.street ?? '').isNotEmpty) p.street, if ((p.locality ?? '').isNotEmpty) p.locality];
        if (parts.isNotEmpty) setState(() => _address = parts.join(', '));
      }
    } catch (_) {
      // Va bene anche senza indirizzo leggibile.
    }
  }

  Future<void> _call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _resolve() async {
    setState(() => _resolving = true);
    try {
      await AppState.instance.resolveSos(widget.alert.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti ad annullare l\'SOS. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.alert.profileId == AppState.instance.me.id;
    final markerPerson = Person(
      id: widget.person.id,
      name: widget.person.name,
      color: widget.person.color,
      lat: widget.alert.lat,
      lng: widget.alert.lng,
      address: _address ?? '${widget.alert.lat.toStringAsFixed(4)}, ${widget.alert.lng.toStringAsFixed(4)}',
      lastUpdate: widget.alert.createdAt,
      batteryPercent: widget.person.batteryPercent,
      isSharingWithMe: true,
      mode: widget.person.mode,
      isMe: widget.person.isMe,
      avatarKey: widget.person.avatarKey,
    );

    return Scaffold(
      appBar: AppBar(title: Text('SOS · ${widget.person.name}')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 260, child: KinlyMap(people: [markerPerson], interactive: false)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.accentCoral.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.emergency_rounded, color: AppTheme.accentCoral),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMine ? 'Il tuo SOS è attivo' : '${widget.person.name} ha attivato l\'SOS',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(icon: Icons.access_time, label: 'Attivato alle ${_formatTime(widget.alert.createdAt)}'),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.place_outlined, label: _address ?? 'In attesa dell\'indirizzo...'),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textSecondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'In caso di reale emergenza chiama il 112. Kinly condivide solo la posizione: nessuna registrazione audio.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMine && (widget.person.phoneNumber ?? '').isNotEmpty) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _call(widget.person.phoneNumber!),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: Text('Chiama ${widget.person.name}'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppTheme.accentCoral),
                      ),
                    ],
                    if (isMine) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _resolving ? null : _resolve,
                        icon: _resolving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Sono al sicuro, annulla SOS'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppTheme.accentGreen),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5))),
      ],
    );
  }
}
