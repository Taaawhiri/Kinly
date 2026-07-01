import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/circle_group.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';
import '../onboarding/create_circle_screen.dart';
import '../onboarding/join_circle_screen.dart';
import '../people/person_detail_screen.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Le tue cerchie'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () => _showAddOptions(context),
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: state.circles.length,
            itemBuilder: (context, i) => _CircleCard(circle: state.circles[i]),
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aggiungi una cerchia', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: AppTheme.surfaceAlt, child: Icon(Icons.add_rounded, color: AppTheme.primary)),
                title: const Text('Crea una nuova cerchia'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateCircleScreen(isOnboarding: false)),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: AppTheme.surfaceAlt, child: Icon(Icons.qr_code_rounded, color: AppTheme.primary)),
                title: const Text('Ho un codice di invito'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final circle = await Navigator.of(context).push<CircleGroup>(
                    MaterialPageRoute(builder: (_) => const JoinCircleScreen(isOnboarding: false)),
                  );
                  if (circle != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sei entrato in "${circle.name}"')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    final members = circle.memberIds.map(AppState.instance.personById).whereType<Person>().toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: circle.color.withOpacity(0.15)),
                alignment: Alignment.center,
                child: Icon(circle.icon, color: circle.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppTheme.textPrimary)),
                    Text('${members.length} persone', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final person = members[i];
                return GestureDetector(
                  onTap: person.isMe
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: person.id))),
                  child: PersonAvatar(person: person, size: 40),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    circle.inviteCode,
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: circle.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice invito copiato')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textSecondary),
                tooltip: 'Copia codice invito',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
