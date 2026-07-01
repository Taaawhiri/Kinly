# Kinly

App Flutter per condividere la posizione con la famiglia, gli amici o i
colleghi, con backend reale su **Supabase** (Postgres + Auth + Realtime).
Accesso solo su invito: niente registrazione pubblica alle cerchie, si entra
con un codice o creandone una nuova — l'account invece si crea con la
semplice email (nessuna password, login via codice OTP).

## Come funziona

- **Account**: login passwordless via email (Supabase Auth, OTP a 6 cifre).
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
- **Mappa stilizzata**: nessuna chiave di mappe reali — le coordinate GPS
  vengono proiettate su un'illustrazione leggera coerente con il resto
  dell'app.

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
   abilitato con "Email OTP" (di default lo è).
4. Recupera **Project URL** e **anon/public key** da
   **Project Settings → API**.

## Avviare l'app

Le credenziali Supabase vanno passate a build/run time, non vanno mai
committate nel repository:

```
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<il-tuo-progetto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<la-tua-anon-key>
```

Per evitare di riscrivere i flag ogni volta, puoi salvarli in un file (non
tracciato da git) e usare `--dart-define-from-file`:

```json
// supabase-local.json (aggiungilo al tuo .gitignore locale)
{
  "SUPABASE_URL": "https://<il-tuo-progetto>.supabase.co",
  "SUPABASE_ANON_KEY": "<la-tua-anon-key>"
}
```

```
flutter run --dart-define-from-file=supabase-local.json
```

Per la build APK su CI (`.github/workflows/build-apk.yml`), imposta i
secret di repository `SUPABASE_URL` e `SUPABASE_ANON_KEY` su GitHub.

## Struttura del progetto

```
supabase/
  schema.sql   Tabelle, funzioni, trigger e policy RLS (da eseguire una volta)

lib/
  models/      Person, CircleGroup, LocationRequest, SharingMode
  services/    Client Supabase, autenticazione, repository dati, tracciamento posizione
  utils/       Conversioni icona/colore <-> valori salvati su Supabase
  state/       AppState — carica i dati da Supabase e resta in ascolto in tempo reale
  theme/       Tema chiaro dell'app
  widgets/     Mappa stilizzata, pin, avatar, badge, chip
  screens/
    auth/        Accesso con email + codice OTP
    onboarding/  Crea cerchia, entra con un codice
    map/         Mappa + elenco persone (Home)
    circles/     Gestione cerchie e inviti
    people/      Dettaglio persona
    requests/    Richieste di posizione in arrivo/uscita
    profile/     Modalità di condivisione, cerchie, anteprima Kinly+
```
