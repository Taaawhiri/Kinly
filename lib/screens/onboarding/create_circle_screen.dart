import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/circle_group.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../premium/paywall_screen.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key, this.isOnboarding = true});

  final bool isOnboarding;

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

const _iconChoices = [
  Icons.favorite_rounded,
  Icons.groups_rounded,
  Icons.work_rounded,
  Icons.school_rounded,
  Icons.pets_rounded,
  Icons.celebration_rounded,
];

const _colorChoices = [
  AppTheme.primary,
  Color(0xFFE8608A),
  AppTheme.accentGreen,
  AppTheme.accentAmber,
  Color(0xFF9B6BD6),
  Color(0xFF1AA6A0),
];

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final _nameController = TextEditingController();
  IconData _icon = _iconChoices.first;
  Color _color = _colorChoices.first;
  CircleGroup? _created;
  bool _creating = false;
  String? _error;
  bool _limitReached = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _creating = true;
      _error = null;
      _limitReached = false;
    });
    try {
      final circle = await AppState.instance.createCircle(name, _icon, _color);
      if (!mounted) return;
      setState(() => _created = circle);
    } on FreeLimitException {
      if (mounted) {
        setState(() {
          _error = 'Nel piano gratuito puoi far parte di massimo 2 cerchie. Passa a Kinly+ per non avere limiti.';
          _limitReached = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a creare la cerchia. Riprova.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _finish() {
    if (widget.isOnboarding) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pop(_created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea la tua cerchia')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _created == null ? _buildForm() : _buildSuccess(_created!),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Come si chiama?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text('Ad esempio "Famiglia" o "Weekend in montagna".', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nome della cerchia',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        Text('Icona', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: [
            for (final icon in _iconChoices)
              _PickerDot(
                selected: icon == _icon,
                color: _color,
                onTap: () => setState(() => _icon = icon),
                child: Icon(icon, color: icon == _icon ? Colors.white : AppTheme.textSecondary, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Colore', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: [
            for (final color in _colorChoices)
              GestureDetector(
                onTap: () => setState(() => _color = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: color == _color ? AppTheme.textPrimary : Colors.transparent, width: 2.4),
                  ),
                ),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
        ],
        if (_limitReached) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: const Text('Scopri Kinly+'),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _creating ? null : _create,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: _creating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : const Text('Crea la cerchia'),
        ),
      ],
    );
  }

  Widget _buildSuccess(CircleGroup circle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circle.color),
          alignment: Alignment.center,
          child: Icon(circle.icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        Text('"${circle.name}" è pronta!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(
          'Condividi questo codice con chi vuoi invitare. Solo chi lo ha può entrare.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                circle.inviteCode,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: circle.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice copiato')));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copia codice'),
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _finish,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: const Text('Continua'),
        ),
      ],
    );
  }
}

class _PickerDot extends StatelessWidget {
  const _PickerDot({required this.selected, required this.color, required this.onTap, required this.child});
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : AppTheme.surface,
          border: Border.all(color: AppTheme.divider),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
