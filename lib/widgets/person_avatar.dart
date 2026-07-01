import 'package:flutter/material.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';

/// Avatar circolare con iniziali e, opzionalmente, un puntino di stato
/// (verde = condivide ora, grigio = no).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.size = 44, this.showStatusDot = true});

  final Person person;
  final double size;
  final bool showStatusDot;

  @override
  Widget build(BuildContext context) {
    final isActive = person.isMe || person.isSharingWithMe;
    final canSeeLocation = person.isMe || person.isSharingWithMe;
    final activity = person.activityStatus;
    final showActivityBadge = canSeeLocation && activity != ActivityStatus.stationary;
    final showLowBattery = canSeeLocation && person.isBatteryLow;

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
              color: person.color,
              border: Border.all(color: Colors.white, width: size * 0.06),
              boxShadow: [BoxShadow(color: person.color.withOpacity(0.35), blurRadius: size * 0.22, offset: Offset(0, size * 0.06))],
            ),
            alignment: Alignment.center,
            child: Text(
              person.initials,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36),
            ),
          ),
          if (showStatusDot)
            Positioned(
              right: -size * 0.02,
              bottom: -size * 0.02,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.5),
                  border: Border.all(color: Colors.white, width: size * 0.05),
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
