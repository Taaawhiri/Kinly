# Kinly

App Flutter per condividere la posizione con la famiglia, gli amici o i
colleghi, con backend reale su **Supabase** (Postgres + Auth + Realtime).
Accesso solo su invito: niente registrazione pubblica alle cerchie, si entra
con un codice o creandone una nuova — l'account invece si crea liberamente
con email e password.

## Come funziona

- **Account**: creazione account e login con email e password (Supabase Auth).
- **Cerchie**: gruppi di persone (Famiglia, Amici, Lavoro...), ognuno con un
  proprio codice di invito univoco, salvate su Postgres.
- **Condivisione della posizione**: ogni persona sceglie una modalità —
  Automatica (sempre visibile ai membri delle sue cerchie), Su richiesta
  (serve un'approvazione) o Sospesa (modalità fantasma, invisibile). La
  visibilità è applicata dal database tramite Row Level Security, non
  simulata lato client.
- **Posizione reale**: la posizione del dispositivo (via `geolocator`),
  l'indirizzo (geocodifica nativa via `geocoding`, senza chiavi API) e il
  livello di batteria (`battery_plus`) vengono caricati su Supabase e
  aggiornati in tempo reale con Supabase Realtime.
- **Richieste**: si può chiedere la posizione a chi non la condivide in
  automatico; l'altra persona approva o rifiuta dal proprio dispositivo.
- **Mappa vera**: strade e geografia reali via [MapLibre](https://maplibre.org)
  con i dati di [OpenFreeMap](https://openfreemap.org) (OpenStreetMap) —
  nessuna chiave API, nessun limite d'uso. Lo stile
  (`assets/map/kinly_style.json`) è una versione ricolorata dello stile
  "Positron" con la palette morbida di Kinly. Le persone sono marcatori
  disegnati con lo stesso stile degli avatar dell'app.

Le funzioni premium (cronologia posizioni, aree sicure, avvisi di guida...)
sono solo abbozzate in anteprima nella tab Profilo: arriveranno con le
microtransazioni in una fase successiva.

## Configurare Supabase

1. Crea un progetto su [supabase.com](https://supabase.com).
2. Nel SQL Editor del progetto, esegui il contenuto di
   [`supabase/schema.sql`](supabase/schema.sql): crea le tabelle
   (`profiles`, `circles`, `circle_members`, `locations`,
   `location_requests`), le funzioni di supporto, i trigger e tutte le
   policy di Row Level Security.
3. In **Authentication → Providers**, verifica che il provider **Email** sia
   abilitato. Per evitare che l'app dipenda dall'invio di email (il servizio
   SMTP integrato di Supabase ha limiti molto bassi, pensati solo per i
   test), disabilita **Confirm email** così l'account è attivo subito dopo
   la registrazione; riabilitalo quando avrai configurato un SMTP tuo.
4. Recupera **Project URL** e **anon/public key** da
   **Project Settings → API**.

## Avviare l'app

Il progetto Supabase di sviluppo (`tteqhmlcsgduuzlcqbrt`) è già configurato
come default in `lib/services/supabase_client.dart`, quindi basta:

```
flutter pub get
flutter run -d chrome
```

La `anon key` incorporata è pensata per stare nel client (le regole RLS in
`supabase/schema.sql` decidono cosa può fare); non è invece mai da usare la
`service_role key`, quella sì segreta.

Per puntare a un altro progetto (es. uno di staging separato), sovrascrivi i
default con `--dart-define`:

```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<altro-progetto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<altra-anon-key>
```

oppure salva i valori in un file non tracciato da git e usa
`--dart-define-from-file=supabase-local.json`.

Per la build APK su CI (`.github/workflows/build-apk.yml`) puoi lasciare
vuoti i secret `SUPABASE_URL`/`SUPABASE_ANON_KEY` (userà i default) oppure
impostarli su GitHub per puntare a un altro progetto.

## Struttura del progetto

```
supabase/
  schema.sql   Tabelle, funzioni, trigger e policy RLS (da eseguire una volta)

assets/
  map/kinly_style.json   Stile MapLibre personalizzato (basato su OpenFreeMap Positron)

lib/
  models/      Person, CircleGroup, LocationRequest, SharingMode
  services/    Client Supabase, autenticazione, repository dati, tracciamento posizione
  utils/       Conversioni icona/colore <-> valori salvati su Supabase
  state/       AppState — carica i dati da Supabase e resta in ascolto in tempo reale
  theme/       Tema chiaro dell'app
  widgets/     Mappa (KinlyMap), avatar, badge, chip
  screens/
    auth/        Accesso con email e password
    onboarding/  Crea cerchia, entra con un codice
    map/         Mappa + elenco persone (Home)
    circles/     Gestione cerchie e inviti
    people/      Dettaglio persona
    requests/    Richieste di posizione in arrivo/uscita
    profile/     Modalità di condivisione, cerchie, anteprima Kinly+
```
