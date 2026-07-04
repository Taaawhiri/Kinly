import '../l10n/app_localizations.dart';
import '../models/person.dart';

/// "{ore}h {minuti}min" oppure solo minuti se sotto l'ora: mai un orario
/// esatto di fine, solo una durata relativa (vedi Person.dndRemaining).
String _durationLabel(AppLocalizations l10n, Duration remaining) {
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  return hours > 0 ? l10n.dndRemainingHoursMinutes(hours, minutes) : l10n.dndRemainingMinutesOnly(minutes);
}

/// Etichetta in prima persona ("Attivo — ancora per 2h 40min"), per la
/// propria card in Profilo e nel foglio di attivazione.
String dndStatusLabel(AppLocalizations l10n, Person person) {
  if (person.dndManual) return l10n.dndActiveManual;
  final remaining = person.dndRemaining;
  if (remaining == null) return l10n.dndActiveManual;
  return l10n.dndActiveWithRemaining(_durationLabel(l10n, remaining));
}

/// Stessa informazione in terza persona ("Non disturbare — ancora per..."),
/// per la scheda di un'altra persona.
String personDndLabel(AppLocalizations l10n, Person person) {
  if (person.dndManual) return l10n.personDetailDndActiveManual;
  final remaining = person.dndRemaining;
  if (remaining == null) return l10n.personDetailDndActiveManual;
  return l10n.personDetailDndActiveWithRemaining(_durationLabel(l10n, remaining));
}
