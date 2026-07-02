import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/help_request.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kinly_map.dart';

/// Dettaglio di una richiesta di aiuto: motivo, nota opzionale e posizione.
/// A differenza dell'SOS non bypassa la privacy: condivide solo la
/// posizione al momento della richiesta.
class HelpRequestScreen extends StatefulWidget {
  const HelpRequestScreen({super.key, required this.request, required this.person});
  final HelpRequest request;
  final Person person;

  @override
  State<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends State<HelpRequestScreen> {
  String? _address;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    try {
      final placemarks = await placemarkFromCoordinates(widget.request.lat, widget.request.lng);
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
      await AppState.instance.resolveHelpRequest(widget.request.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a chiudere la richiesta. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.request.profileId == AppState.instance.me.id;
    final reason = widget.request.reason;
    final markerPerson = Person(
      id: widget.person.id,
      name: widget.person.name,
      color: widget.person.color,
      lat: widget.request.lat,
      lng: widget.request.lng,
      address: _address ?? '${widget.request.lat.toStringAsFixed(4)}, ${widget.request.lng.toStringAsFixed(4)}',
      lastUpdate: widget.request.createdAt,
      batteryPercent: widget.person.batteryPercent,
      isSharingWithMe: true,
      mode: widget.person.mode,
      isMe: widget.person.isMe,
      avatarKey: widget.person.avatarKey,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Aiuto · ${widget.person.name}')),
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
                      decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(reason.icon, color: AppTheme.accentAmber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMine ? 'Hai chiesto aiuto: ${reason.label}' : '${widget.person.name} ha bisogno di aiuto: ${reason.label}',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((widget.request.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                        child: Text(widget.request.note!, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, height: 1.4)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _InfoRow(icon: Icons.access_time, label: 'Richiesto alle ${_formatTime(widget.request.createdAt)}'),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.place_outlined, label: _address ?? 'In attesa dell\'indirizzo...'),
                    if (!isMine && (widget.person.phoneNumber ?? '').isNotEmpty) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _call(widget.person.phoneNumber!),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: Text('Chiama ${widget.person.name}'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppTheme.accentAmber),
                      ),
                    ],
                    if (isMine) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _resolving ? null : _resolve,
                        icon: _resolving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Va tutto bene, chiudi richiesta'),
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
