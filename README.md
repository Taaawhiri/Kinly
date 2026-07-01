# Cerchia

Mockup Flutter di un'app per condividere la posizione con la famiglia, gli
amici o i colleghi. Accesso solo su invito: niente registrazione pubblica,
si entra con un codice o creando una nuova cerchia.

## Come funziona (MVP)

- **Cerchie**: gruppi di persone (Famiglia, Amici, Lavoro...), ognuno con un
  proprio codice di invito.
- **Condivisione della posizione**: ogni persona scegli una modalità —
  Automatica (sempre visibile), Su richiesta (serve un'approvazione) o
  Sospesa (modalità fantasma, invisibile).
- **Richieste**: si può chiedere la posizione a chi non la condivide in
  automatico; l'altra persona approva o rifiuta.
- **Mappa stilizzata**: nessuna chiave API o tile reali — un'illustrazione
  leggera coerente con il resto dell'app, con i pin delle persone che
  condividono con te.

Le funzioni premium (cronologia posizioni, aree sicure, avvisi di guida...)
sono solo abbozzate in anteprima nella tab Profilo: arriveranno con le
microtransazioni in una fase successiva.

## Struttura del progetto

```
lib/
  models/      Person, CircleGroup, LocationRequest, SharingMode
  data/        Dati di esempio (mock, nessun backend reale)
  state/       AppState — stato in memoria per la sessione
  theme/       Tema chiaro dell'app
  widgets/     Mappa stilizzata, pin, avatar, badge, chip
  screens/
    onboarding/  Benvenuto, crea cerchia, entra con un codice
    map/         Mappa + elenco persone (Home)
    circles/     Gestione cerchie e inviti
    people/      Dettaglio persona
    requests/    Richieste di posizione in arrivo/uscita
    profile/     Modalità di condivisione, cerchie, anteprima Cerchia+
```

## Avvio

```
flutter pub get
flutter run -d chrome   # o un device/emulatore a scelta
```

Per la demo, i codici di invito validi sono `FAM-7Q2K`, `AMI-P91X`, `LAV-3T5B`.
