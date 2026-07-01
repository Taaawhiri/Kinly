import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/state/app_state.dart';

void main() {
  test('joinCircleByCode riconosce i codici esistenti (case-insensitive) e rifiuta gli altri', () {
    expect(AppState.instance.joinCircleByCode('fam-7q2k'), isNotNull);
    expect(AppState.instance.joinCircleByCode('NON-ESISTE'), isNull);
  });

  test('creare una cerchia mi aggiunge come unico membro iniziale e genera un codice funzionante', () {
    final before = AppState.instance.circles.length;
    final circle = AppState.instance.createCircle('Vicini di casa', Icons.home_rounded, Colors.teal);

    expect(AppState.instance.circles.length, before + 1);
    expect(circle.memberIds, [AppState.instance.me.id]);
    expect(AppState.instance.joinCircleByCode(circle.inviteCode), circle);
  });

  test('sendLocationRequest non duplica richieste già in sospeso verso la stessa persona', () {
    final personId = AppState.instance.others.first.id;
    AppState.instance.sendLocationRequest(personId);
    final afterFirst = AppState.instance.requests.length;
    AppState.instance.sendLocationRequest(personId);
    final afterSecond = AppState.instance.requests.length;

    expect(afterSecond, afterFirst);
  });

  test('accettare una richiesta in uscita rende visibile la posizione della persona', () {
    final person = AppState.instance.others.firstWhere((p) => !p.isSharingWithMe);
    AppState.instance.sendLocationRequest(person.id);
    final request = AppState.instance.pendingOutgoing.firstWhere((r) => r.personId == person.id);

    AppState.instance.simulateOutgoingResponse(request.id, true);

    final updated = AppState.instance.personById(person.id)!;
    expect(updated.isSharingWithMe, true);
  });
}
