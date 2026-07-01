import 'package:flutter/material.dart';

/// Un avatar a tema tra cui scegliere, stile "profili" di un servizio di
/// streaming: un'emoji su uno sfondo sfumato, niente foto da caricare.
class AvatarOption {
  const AvatarOption({required this.key, required this.emoji, required this.colors});

  final String key;
  final String emoji;
  final List<Color> colors;
}

class AvatarCatalog {
  AvatarCatalog._();

  static const options = [
    AvatarOption(key: 'fox', emoji: '🦊', colors: [Color(0xFFFF9A56), Color(0xFFFF6B35)]),
    AvatarOption(key: 'cat', emoji: '🐱', colors: [Color(0xFFB388EB), Color(0xFF8C6FD1)]),
    AvatarOption(key: 'dog', emoji: '🐶', colors: [Color(0xFFFFC15E), Color(0xFFFF9F1C)]),
    AvatarOption(key: 'owl', emoji: '🦉', colors: [Color(0xFF6E7F9E), Color(0xFF4A5A79)]),
    AvatarOption(key: 'panda', emoji: '🐼', colors: [Color(0xFF8FA3BF), Color(0xFF5E7290)]),
    AvatarOption(key: 'koala', emoji: '🐨', colors: [Color(0xFF9FB4C9), Color(0xFF71879E)]),
    AvatarOption(key: 'lion', emoji: '🦁', colors: [Color(0xFFFFC857), Color(0xFFE8A73B)]),
    AvatarOption(key: 'rabbit', emoji: '🐰', colors: [Color(0xFFFF9EC4), Color(0xFFE87DA6)]),
    AvatarOption(key: 'bear', emoji: '🐻', colors: [Color(0xFFB08968), Color(0xFF8A6647)]),
    AvatarOption(key: 'penguin', emoji: '🐧', colors: [Color(0xFF5CC8D7), Color(0xFF3A9CAB)]),
  ];

  static AvatarOption? find(String? key) {
    if (key == null) return null;
    for (final option in options) {
      if (option.key == key) return option;
    }
    return null;
  }
}
