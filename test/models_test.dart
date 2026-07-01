import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/models/circle_group.dart';
import 'package:kinly/models/location_request.dart';
import 'package:kinly/models/sharing_mode.dart';
import 'package:kinly/utils/circle_icons.dart';
import 'package:kinly/utils/color_hex.dart';

/// Test sulla logica pura di mappatura tra le righe di Supabase e i modelli
/// dell'app: non toccano la rete, quindi girano ovunque senza un progetto
/// Supabase configurato.
void main() {
  group('CircleGroup.fromRow', () {
    test('converte icon_key e color dal formato del database', () {
      final circle = CircleGroup.fromRow(
        {'id': 'c1', 'name': 'Famiglia', 'icon_key': 'favorite', 'color': '#E8608A', 'invite_code': 'FAM-7Q2K', 'created_by': 'me'},
        memberIds: const ['me', 'mamma'],
      );

      expect(circle.icon, Icons.favorite_rounded);
      expect(circle.color, const Color(0xFFE8608A));
      expect(circle.memberIds, ['me', 'mamma']);
    });

    test('usa dei valori di default se icon_key o color mancano', () {
      final circle = CircleGroup.fromRow(
        {'id': 'c1', 'name': 'Amici', 'invite_code': 'AMI-P91X', 'created_by': 'me'},
        memberIds: const [],
      );

      expect(circle.icon, Icons.groups_rounded);
      expect(circle.color, const Color(0xFF4A63E7));
    });
  });

  group('LocationRequest.fromRow', () {
    test('è "outgoing" quando sono io il richiedente', () {
      final request = LocationRequest.fromRow(
        {
          'id': 'r1',
          'requester_id': 'me',
          'target_id': 'sofia',
          'status': 'pending',
          'created_at': '2026-01-01T10:00:00Z',
        },
        myId: 'me',
      );

      expect(request.direction, RequestDirection.outgoing);
      expect(request.personId, 'sofia');
      expect(request.status, RequestStatus.pending);
    });

    test('è "incoming" quando sono il destinatario', () {
      final request = LocationRequest.fromRow(
        {
          'id': 'r2',
          'requester_id': 'sofia',
          'target_id': 'me',
          'status': 'accepted',
          'created_at': '2026-01-01T10:00:00Z',
        },
        myId: 'me',
      );

      expect(request.direction, RequestDirection.incoming);
      expect(request.personId, 'sofia');
      expect(request.status, RequestStatus.accepted);
    });
  });

  group('SharingMode <-> valore database', () {
    test('round-trip per ogni modalità', () {
      for (final mode in SharingMode.values) {
        expect(SharingModeData.fromDb(mode.dbValue), mode);
      }
    });
  });

  group('ColorHex', () {
    test('round-trip esadecimale', () {
      const color = Color(0xFF4A63E7);
      expect(ColorHex.fromHex(color.toHex()), color);
    });
  });

  group('CircleIcons', () {
    test('round-trip chiave <-> icona', () {
      for (final key in CircleIcons.choices) {
        expect(CircleIcons.keyFor(CircleIcons.iconFor(key)), key);
      }
    });
  });
}
