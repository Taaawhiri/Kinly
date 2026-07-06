import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/person.dart';
import '../../services/sos_flow.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/person_avatar.dart';
import '../people/simple_person_detail_screen.dart';

/// Modalità Rapida: la home a mappa sostituita da una schermata più diretta —
/// un saluto, un'anteprima piccola della mappa, due azioni evidenti (SOS e
/// chiamata rapida) e una riga grande per ogni persona con un solo pulsante
/// per chiamarla. Attivabile da Profilo → Accessibilità. Resta dentro Kinly
/// (stessa barra in basso, stesse schede): cambia solo cosa mostra questa
/// scheda, non cosa condividi.
class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  /// Mostra la mappa vera a schermo intero (al posto della lista) quando si
  /// tocca l'anteprima: un solo pannello mappa vivo per volta, mai due
  /// insieme, per non appesantire i telefoni più vecchi.
  bool _showFullMap = false;

  /// Aggiorna l'orologio in cima ogni tanto senza tenere un timer al minuto
  /// perfettamente allineato: basta che non resti indietro.
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _clock() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openPerson(Person person) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePersonDetailScreen(personId: person.id)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.others;
        if (_showFullMap) return _buildFullMap(state, people);
        return _buildSimpleHome(context, state, people);
      },
    );
  }

  // -----------------------------------------------------------------------
  // Mappa a schermo intero, aperta dall'anteprima.
  // -----------------------------------------------------------------------

  Widget _buildFullMap(AppState state, List<Person> people) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: KinlyMap(
              people: [state.me, ...people.where((p) => p.isSharingWithMe)],
              safeZones: state.visibleSafeZones(),
              meetingPoints: state.visibleMeetingPoints(),
              onPersonTap: (id) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SimplePersonDetailScreen(personId: id)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _showFullMap = false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.simpleModeCloseMap,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Home semplificata.
  // -----------------------------------------------------------------------

  Widget _buildSimpleHome(BuildContext context, AppState state, List<Person> people) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = state.me.name.trim().split(RegExp(r'\s+')).first;
    // Primo contatto chiamabile: la prima persona con un numero salvato.
    final callable = people.where((p) => (p.phoneNumber ?? '').isNotEmpty).toList();
    final primaryCall = callable.isNotEmpty ? callable.first : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l10n.simpleModeGreeting(firstName),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ),
                Text(_clock(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),
            _MapPreviewCard(
              label: l10n.simpleModeOpenMap,
              hint: l10n.simpleModeOpenMapHint,
              onTap: () => setState(() => _showFullMap = true),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.warning_amber_rounded,
                    label: l10n.simpleModeSosButton,
                    color: AppTheme.accentCoral,
                    onTap: () => SosFlow.confirmAndTrigger(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: primaryCall != null
                      ? _QuickAction(
                          icon: Icons.call_rounded,
                          label: l10n.simpleModeCall(primaryCall.name.trim().split(RegExp(r'\s+')).first),
                          color: AppTheme.accentGreen,
                          onTap: () => _call(primaryCall.phoneNumber!),
                        )
                      : _QuickAction(
                          icon: Icons.map_rounded,
                          label: l10n.simpleModeOpenMap,
                          color: AppTheme.primary,
                          onTap: () => setState(() => _showFullMap = true),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              l10n.mapYourCircle,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.mapEmptyCircleMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
                ),
              )
            else
              for (final p in people)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SimplePersonRow(
                    person: p,
                    onTap: () => _openPerson(p),
                    onCall: (p.phoneNumber ?? '').isNotEmpty ? () => _call(p.phoneNumber!) : null,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Anteprima statica della mappa (nessuna mappa MapLibre viva qui): apre la
/// mappa vera a schermo intero al tocco. Volutamente NON una mini-mappa
/// interattiva — tenere un solo pannello mappa vivo per volta in tutta l'app
/// evita che, creando e distruggendo più superfici native passando da una
/// modalità all'altra, il pin con l'avatar sparisca (MapLibre perde i simboli
/// aggiunti a mano quando la superficie viene ricreata).
class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.label, required this.hint, required this.onTap});

  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Stack(
            children: [
              // Griglia leggera, a evocare una mappa senza istanziarne una.
              Positioned.fill(
                child: CustomPaint(painter: _MapGridPainter(color: AppTheme.divider)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded, size: 30, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full_rounded, size: 13, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(hint, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sottile griglia a quadretti per la card d'anteprima mappa: puramente
/// decorativa, disegnata a mano così non serve nessuna immagine né mappa.
class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => oldDelegate.color != color;
}

/// Uno dei due grandi pulsanti d'azione in alto (SOS / chiamata / mappa).
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riga persona in Modalità Rapida: avatar, nome grande, stato in chiaro e un
/// solo tondo per chiamare (se c'è un numero). Il resto della riga apre la
/// scheda completa, come nella lista normale.
class _SimplePersonRow extends StatelessWidget {
  const _SimplePersonRow({required this.person, required this.onTap, this.onCall});

  final Person person;
  final VoidCallback onTap;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSee = person.isSharingWithMe;
    final live = canSee && !person.isStale;
    final statusText = canSee
        ? (person.address.trim().isNotEmpty ? person.address : person.lastUpdateLabel(l10n))
        : l10n.simpleModeLocationHidden;

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PersonAvatar(person: person, size: 44, showActivityBadge: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: live ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onCall != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.surfaceAlt,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onCall,
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Icon(Icons.call_rounded, size: 18, color: AppTheme.accentGreen),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
