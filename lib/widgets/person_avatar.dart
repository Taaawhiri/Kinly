import 'package:flutter/material.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_catalog.dart';
import '../utils/generative_avatar.dart';

/// Avatar circolare con iniziali e, opzionalmente, un puntino di stato
/// (verde = condivide ora, grigio = no). Il puntino fa un piccolo "battito"
/// quando arriva un aggiornamento di posizione, per far sentire l'app viva
/// invece di un pallino statico che non si sa se è ancora collegato.
class PersonAvatar extends StatefulWidget {
  const PersonAvatar({super.key, required this.person, this.size = 44, this.showStatusDot = true});

  final Person person;
  final double size;
  final bool showStatusDot;

  @override
  State<PersonAvatar> createState() => _PersonAvatarState();
}

class _PersonAvatarState extends State<PersonAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didUpdateWidget(covariant PersonAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isActive = widget.person.isMe || widget.person.isSharingWithMe;
    if (isActive && widget.person.lastUpdate != oldWidget.person.lastUpdate) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final size = widget.size;
    final isActive = person.isMe || person.isSharingWithMe;
    final canSeeLocation = person.isMe || person.isSharingWithMe;
    final activity = person.activityStatus;
    final showActivityBadge = canSeeLocation && activity != ActivityStatus.stationary;
    final showLowBattery = canSeeLocation && person.isBatteryLow;
    final avatar = AvatarCatalog.find(person.avatarKey);
    final generativeSeed = GenerativeAvatar.isGenerativeKey(person.avatarKey) ? GenerativeAvatar.seedFromKey(person.avatarKey!) : null;
    final photoUrl = person.photoUrl;
    final glowColor = generativeSeed != null
        ? GenerativeAvatar.accentColor(generativeSeed)
        : (avatar != null ? avatar.colors.last : person.color);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: (photoUrl == null && generativeSeed == null && avatar != null)
                  ? LinearGradient(colors: avatar.colors, begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: (photoUrl == null && generativeSeed == null && avatar == null) ? person.color : null,
              border: Border.all(color: Colors.white, width: size * 0.06),
              boxShadow: [BoxShadow(color: glowColor.withOpacity(0.35), blurRadius: size * 0.22, offset: Offset(0, size * 0.06))],
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => avatar != null
                        ? Text(avatar.emoji, style: TextStyle(fontSize: size * 0.5))
                        : Text(person.initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
                  )
                : (generativeSeed != null
                    ? GenerativeAvatarPreview(seed: generativeSeed, size: size)
                    : (avatar != null
                        ? Text(avatar.emoji, style: TextStyle(fontSize: size * 0.5))
                        : Text(
                            person.initials,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36),
                          ))),
          ),
          if (widget.showStatusDot)
            Positioned(
              right: -size * 0.02,
              bottom: -size * 0.02,
              child: SizedBox(
                width: size * 0.32,
                height: size * 0.32,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (isActive)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          if (_pulseController.status == AnimationStatus.dismissed) return const SizedBox.shrink();
                          final t = _pulseController.value;
                          return Opacity(
                            opacity: (1 - t) * 0.55,
                            child: Transform.scale(
                              scale: 1 + t * 1.6,
                              child: Container(
                                width: size * 0.32,
                                height: size * 0.32,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGreen),
                              ),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: size * 0.32,
                      height: size * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.5),
                        border: Border.all(color: Colors.white, width: size * 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showActivityBadge)
            Positioned(
              left: -size * 0.04,
              bottom: -size * 0.02,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  border: Border.all(color: Colors.white, width: size * 0.05),
                ),
                alignment: Alignment.center,
                child: Icon(activity.icon, size: size * 0.2, color: Colors.white),
              ),
            ),
          if (canSeeLocation && (person.isBirthdayToday || person.hasActiveStatus))
            Positioned(
              left: -size * 0.04,
              top: -size * 0.04,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                alignment: Alignment.center,
                child: Text(
                  person.isBirthdayToday ? '🎂' : person.statusEmoji!,
                  style: TextStyle(fontSize: size * 0.22),
                ),
              ),
            ),
          if (showLowBattery)
            Positioned(
              right: -size * 0.04,
              top: -size * 0.04,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentCoral,
                  border: Border.all(color: Colors.white, width: size * 0.05),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.battery_alert_rounded, size: size * 0.18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
