-- Kinly — schema Supabase (Postgres + RLS)
--
-- Da eseguire una volta sul progetto Supabase (SQL editor oppure
-- `supabase db push` se usi la CLI con le migration in questa cartella).
-- Presuppone Supabase Auth per l'accesso (email + password): chiunque può
-- creare un account — l'accesso "solo su invito" riguarda le cerchie, non
-- l'account.

create extension if not exists "pgcrypto";

-- =========================================================================
-- Tabelle
-- =========================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default 'Io',
  color text not null default '#4A63E7',
  sharing_mode text not null default 'automatic'
    check (sharing_mode in ('automatic', 'on_request', 'paused')),
  battery_percent integer not null default 100
    check (battery_percent between 0 and 100),
  created_at timestamptz not null default now()
);

-- "create table if not exists" non tocca una tabella già esistente, quindi
-- le colonne aggiunte in versioni successive di questo script vanno
-- applicate con degli "alter table" espliciti, anche loro idempotenti.
alter table public.profiles add column if not exists
  -- Vero solo con un abbonamento Kinly+ attivo. Per ora non c'è un
  -- sistema di pagamento collegato: questa colonna è pronta per quando
  -- ci sarà (es. un webhook che la aggiorna dopo un pagamento riuscito).
  -- Sostituita da premium_tier per le nuove attivazioni (vedi sotto): resta
  -- qui solo per compatibilità con account già attivati a mano.
  is_premium boolean not null default false;

alter table public.profiles add column if not exists
  -- Livello di abbonamento: 'individual' sblocca Kinly+ solo per sé;
  -- 'family' lo sblocca per sé E lo fa ereditare a chi è tra i primi 6
  -- membri (per data di ingresso) di una cerchia che ha creato — vedi
  -- is_effectively_premium più sotto. Impostato a mano da SQL Editor come
  -- is_premium, in attesa di un vero sistema di pagamento.
  premium_tier text not null default 'none'
    check (premium_tier in ('none', 'individual', 'family'));

alter table public.profiles add column if not exists
  -- Data di nascita (opzionale, la sceglie l'utente): usata solo per
  -- mostrare un'iconcina di compleanno ai membri della cerchia nel giorno
  -- giusto, nessun'altra elaborazione o notifica push.
  birthday date;

alter table public.profiles add column if not exists
  -- Stato personalizzato del momento (es. emoji 🎉 + testo "con gli amici"):
  -- scompare da solo a fine giornata locale grazie a status_expires_at, non
  -- richiede una notifica per essere tolto.
  status_emoji text;

alter table public.profiles add column if not exists
  status_text text;

alter table public.profiles add column if not exists
  status_expires_at timestamptz;

alter table public.profiles add column if not exists
  -- Link personale di pagamento (es. Satispay, PayPal.me), usato solo per
  -- aprire un pagamento diretto dalla funzione "Spese di gruppo": Kinly non
  -- gestisce mai soldi né si integra con alcun provider di pagamento.
  payment_link text;

-- Chi aveva già is_premium=true (attivato a mano prima del piano Family)
-- diventa 'individual': non perde il proprio abbonamento con l'aggiunta dei
-- livelli.
update public.profiles set premium_tier = 'individual' where is_premium = true and premium_tier = 'none';

alter table public.profiles add column if not exists
  -- Soglia di velocità (km/h) oltre la quale si registra un avviso di
  -- guida (Kinly+): null = avvisi disattivati. La imposta chi guida, su
  -- di sé; a vederne gli avvisi sono i membri premium della sua cerchia.
  speed_alert_kmh integer check (speed_alert_kmh between 20 and 300);

-- "fuzzy" (posizione approssimativa) si aggiunge ai valori validi di
-- sharing_mode: il vincolo va ricreato perché non si può alterare in place.
alter table public.profiles drop constraint if exists profiles_sharing_mode_check;
alter table public.profiles add constraint profiles_sharing_mode_check
  check (sharing_mode in ('automatic', 'on_request', 'paused', 'fuzzy'));

-- Orario di reperibilità (in UTC): fuori da questa finestra, chi guarda non
-- vede la posizione indipendentemente dalla modalità di condivisione. Se
-- entrambi i valori sono null (default) non c'è nessuna limitazione oraria.
-- Nota: gestisce solo finestre nello stesso giorno (inizio < fine).
alter table public.profiles add column if not exists auto_ghost_start time;
alter table public.profiles add column if not exists auto_ghost_end time;

-- Avatar scelto tra un set predefinito (stile Netflix): null = mostra le
-- iniziali colorate come prima, il valore è una chiave interpretata dal
-- client (vedi lib/utils/avatar_catalog.dart), non un'immagine caricata.
alter table public.profiles add column if not exists avatar_key text;

-- Amministratore dell'assistenza: può vedere e rispondere a tutti i
-- messaggi di supporto, non solo ai propri (vedi support_messages più
-- sotto). Non è tra le colonne concesse in scrittura a "authenticated" più
-- in basso, quindi va impostato a mano da SQL Editor, come is_premium.
alter table public.profiles add column if not exists is_admin boolean not null default false;

create table if not exists public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon_key text not null default 'groups',
  color text not null default '#4A63E7',
  invite_code text not null unique,
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.circle_members (
  circle_id uuid not null references public.circles (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (circle_id, profile_id)
);

create table if not exists public.locations (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  address text,
  updated_at timestamptz not null default now()
);

alter table public.locations add column if not exists speed_kmh double precision;

create table if not exists public.location_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  target_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> target_id)
);

-- Storico delle posizioni (Kinly+): a differenza di `locations`, che tiene
-- solo l'ultima posizione nota, qui si accumula una riga per ogni
-- aggiornamento, per poter rivedere gli spostamenti nei giorni passati.
create table if not exists public.location_history (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  address text,
  recorded_at timestamptz not null default now()
);

-- Aree sicure (Kinly+): un luogo con un raggio, definito per una cerchia.
-- Quando qualcuno della cerchia entra o esce da un'area viene registrato
-- un evento in `safe_zone_events`.
create table if not exists public.safe_zones (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  name text not null,
  lat double precision not null,
  lng double precision not null,
  radius_meters integer not null default 150 check (radius_meters between 30 and 5000),
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Tipo di luogo: usato solo per personalizzare l'icona e il testo delle
-- notifiche push di ingresso/uscita (vedi supabase/functions/send-push).
alter table public.safe_zones add column if not exists kind text not null default 'other'
  check (kind in ('home', 'work', 'school', 'other'));

create table if not exists public.safe_zone_events (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references public.safe_zones (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  event_type text not null check (event_type in ('enter', 'exit')),
  occurred_at timestamptz not null default now()
);

-- Avvisi di guida (Kinly+): un evento ogni volta che qualcuno supera la
-- propria soglia di velocità (`profiles.speed_alert_kmh`), passando da
-- sotto a sopra soglia (non un evento per ogni aggiornamento posizione).
create table if not exists public.speed_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  speed_kmh double precision not null,
  threshold_kmh double precision not null,
  occurred_at timestamptz not null default now()
);

-- Richieste di assistenza: chi è Kinly+ ha la priorità (colonna decisa dal
-- server in base all'abbonamento al momento dell'invio, non dal client).
create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  message text not null,
  is_priority boolean not null default false,
  status text not null default 'open' check (status in ('open', 'answered', 'closed')),
  created_at timestamptz not null default now()
);

-- Risposta di un admin, mostrata a chi ha scritto (vedi Aiuto e assistenza):
-- è la forma più semplice di "messaggistica interna", un canale a senso
-- unico admin -> utente, non una chat libera tra utenti.
alter table public.support_messages add column if not exists admin_reply text;
alter table public.support_messages add column if not exists replied_at timestamptz;

-- Punto d'incontro condiviso: chiunque nella cerchia può proporne uno (non è
-- una funzione Kinly+). Gli altri membri vedono la propria distanza dal
-- punto in tempo reale; l'arrivo si registra da solo quando ci si avvicina
-- abbastanza (vedi meeting_point_arrivals), come per le aree sicure.
create table if not exists public.meeting_points (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  name text not null,
  lat double precision not null,
  lng double precision not null,
  created_by uuid not null references public.profiles (id) on delete cascade,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

-- Orario proposto per il ritrovo (opzionale): solo informativo, non aziona
-- automatismi lato server.
alter table public.meeting_points add column if not exists scheduled_at timestamptz;

create table if not exists public.meeting_point_arrivals (
  meeting_point_id uuid not null references public.meeting_points (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  arrived_at timestamptz not null default now(),
  primary key (meeting_point_id, profile_id)
);

-- SOS "Black Box": nessuna registrazione audio (solo posizione). Attivarlo
-- condivide la posizione esatta con tutte le proprie cerchie, bypassando
-- deliberatamente la modalità di condivisione normale (anche chi è in
-- pausa/fuzzy/fuori orario diventa visibile finché l'SOS è attivo) — è
-- pensato come eccezione di emergenza, non come canale di tracciamento.
create table if not exists public.sos_alerts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  status text not null default 'active' check (status in ('active', 'resolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- Contatti SOS di fiducia: se una persona ne configura almeno uno, il suo
-- SOS avvisa solo quei contatti invece di tutta la cerchia (vedi la policy
-- sos_alerts_select più sotto). Se la lista è vuota, il comportamento resta
-- quello di default: avvisa tutti quelli con cui condivide una cerchia.
-- Messaggi brevi condivisi con una cerchia: pensati per avvisi importanti
-- ("sto arrivando", "chiamami"), non per chiacchierare — il limite di
-- lunghezza è imposto apposta per scoraggiare un uso da chat vera e
-- propria (per quello l'app stessa rimanda a WhatsApp o simili).
create table if not exists public.circle_messages (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 140),
  created_at timestamptz not null default now()
);

create table if not exists public.sos_trusted_contacts (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  contact_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, contact_id),
  check (profile_id <> contact_id)
);

-- Token FCM (Firebase Cloud Messaging) per dispositivo, per l'invio di
-- notifiche push reali (SOS, aree sicure, richieste di posizione). Un
-- profilo può avere più righe (più dispositivi); l'invio effettivo lo fa
-- una Edge Function con la service_role key, non il client.
-- Richiesta di aiuto: un gradino sotto l'SOS. Motivo predefinito + nota
-- opzionale + posizione, condivisa con tutta la cerchia (a differenza
-- dell'SOS, rispetta comunque la modalità di condivisione normale: chi ha
-- messo in pausa la condivisione non manda comunque la posizione esatta
-- qui — questo canale non è pensato per bypassare la privacy, solo per
-- chiedere una mano in modo rapido e strutturato).
create table if not exists public.help_requests (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null check (reason in ('flat_tire', 'accident', 'followed', 'low_battery', 'other')),
  note text,
  lat double precision not null,
  lng double precision not null,
  status text not null default 'active' check (status in ('active', 'resolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.device_tokens (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null default 'android' check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now(),
  primary key (profile_id, token)
);

create index if not exists circle_members_profile_idx on public.circle_members (profile_id);
create index if not exists location_requests_requester_idx on public.location_requests (requester_id);
create index if not exists location_requests_target_idx on public.location_requests (target_id);
create index if not exists location_history_profile_idx on public.location_history (profile_id, recorded_at desc);
create index if not exists safe_zones_circle_idx on public.safe_zones (circle_id);
create index if not exists safe_zone_events_zone_idx on public.safe_zone_events (zone_id, occurred_at desc);
create index if not exists speed_events_profile_idx on public.speed_events (profile_id, occurred_at desc);
create index if not exists support_messages_profile_idx on public.support_messages (profile_id, created_at desc);
create index if not exists meeting_points_circle_idx on public.meeting_points (circle_id);
create index if not exists meeting_point_arrivals_point_idx on public.meeting_point_arrivals (meeting_point_id);
create index if not exists sos_alerts_profile_idx on public.sos_alerts (profile_id, created_at desc);
create index if not exists circle_messages_circle_idx on public.circle_messages (circle_id, created_at desc);
create index if not exists help_requests_circle_idx on public.help_requests (circle_id, created_at desc);

-- =========================================================================
-- Funzioni helper (security definer per evitare ricorsione nelle policy RLS)
-- =========================================================================

create or replace function public.my_circle_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select circle_id from public.circle_members where profile_id = auth.uid();
$$;

create or replace function public.shares_circle_with(other_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.circle_members mine
    join public.circle_members theirs on theirs.circle_id = mine.circle_id
    where mine.profile_id = auth.uid()
      and theirs.profile_id = other_id
  );
$$;

-- Orario di reperibilità: se impostato, fuori da questa finestra nessuno
-- vede la posizione, qualunque sia la modalità di condivisione (è un "clock
-- out" totale, pensato per il lavoro). Se non impostato, nessuna limitazione.
create or replace function public.is_within_ghost_schedule(p_target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auto_ghost_start is null
    or auto_ghost_end is null
    or (now() at time zone 'utc')::time between auto_ghost_start and auto_ghost_end
  from public.profiles
  where id = p_target_id;
$$;

create or replace function public.can_view_location(p_target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_target_id = auth.uid()
    or (
      public.shares_circle_with(p_target_id)
      and public.is_within_ghost_schedule(p_target_id)
      and (
        (select sharing_mode from public.profiles where id = p_target_id) in ('automatic', 'fuzzy')
        or exists (
          select 1 from public.location_requests
          where requester_id = auth.uid()
            and target_id = p_target_id
            and status = 'accepted'
        )
      )
    );
$$;

-- Posizioni "visibili" per una lista di persone: applica l'arrotondamento
-- per chi è in modalità fuzzy (circa 1 km di lato) prima di restituire i
-- dati, così la posizione precisa non lascia mai il database in quel caso.
create or replace function public.fetch_visible_locations(p_ids uuid[])
returns table (
  profile_id uuid,
  lat double precision,
  lng double precision,
  address text,
  speed_kmh double precision,
  updated_at timestamptz,
  is_fuzzy boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    l.profile_id,
    case when p.sharing_mode = 'fuzzy' and l.profile_id <> auth.uid()
         then round(l.lat::numeric, 2)::double precision
         else l.lat end,
    case when p.sharing_mode = 'fuzzy' and l.profile_id <> auth.uid()
         then round(l.lng::numeric, 2)::double precision
         else l.lng end,
    case when p.sharing_mode = 'fuzzy' and l.profile_id <> auth.uid()
         then null
         else l.address end,
    l.speed_kmh,
    l.updated_at,
    (p.sharing_mode = 'fuzzy' and l.profile_id <> auth.uid())
  from public.locations l
  join public.profiles p on p.id = l.profile_id
  where l.profile_id = any(p_ids)
    and public.can_view_location(l.profile_id);
$$;

-- Vero se il profilo ha un abbonamento proprio (individual o family),
-- oppure se è tra i primi 6 membri (per data di ingresso) di una cerchia
-- creata da qualcuno con piano Family: è il "paga uno, beneficiano tutti"
-- del piano Family. Il limite di 6 evita che una cerchia enorme aggiri
-- l'abbonamento individuale con un solo pagamento Family.
create or replace function public.is_effectively_premium(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    coalesce((select premium_tier from public.profiles where id = p_profile_id), 'none') <> 'none'
    or exists (
      select 1
      from (
        select cm.profile_id,
               row_number() over (partition by cm.circle_id order by cm.joined_at) as rn
        from public.circle_members cm
        join public.circles c on c.id = cm.circle_id
        join public.profiles owner on owner.id = c.created_by
        where owner.premium_tier = 'family'
      ) family_members
      where family_members.profile_id = p_profile_id and family_members.rn <= 6
    );
$$;

-- Il client legge il proprio stato Kinly+ (e quello dei membri delle
-- cerchie) da questa view invece che dalla colonna is_premium grezza, così
-- vede già il beneficio ereditato dal piano Family di chi ha creato la
-- cerchia, senza dover cambiare come leggeva prima (stesse colonne, più
-- effective_is_premium in aggiunta). security_invoker = true: applica la
-- RLS di chi interroga, non quella di chi ha creato la view.
drop view if exists public.profiles_view;
create view public.profiles_view
  with (security_invoker = true) as
select p.*, public.is_effectively_premium(p.id) as effective_is_premium
from public.profiles p;

grant select on public.profiles_view to authenticated;

-- Crea automaticamente il profilo quando un utente si registra tramite
-- Supabase Auth. Il nome iniziale arriva dai metadata passati a
-- signUp (`data: {'name': ...}`), altrimenti resta 'Io'.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', 'Io'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RPC usata dal client per trovare una cerchia dato il codice invito senza
-- dover concedere una policy di select pubblica sulla tabella `circles`.
create or replace function public.find_circle_by_code(p_code text)
returns public.circles
language sql
stable
security definer
set search_path = public
as $$
  select * from public.circles where invite_code = upper(trim(p_code));
$$;

-- Limiti del piano gratuito: chi non è premium può far parte di al
-- massimo 2 cerchie, e una cerchia può avere al massimo 6 membri a meno
-- che chi l'ha creata non sia premium (è il "piano famiglia": paga chi
-- crea la cerchia, ne beneficiano tutti i membri).
create or replace function public.enforce_circle_limits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  joining_is_premium boolean;
  circle_owner_is_premium boolean;
  circle_count integer;
  member_count integer;
begin
  joining_is_premium := public.is_effectively_premium(new.profile_id);

  if not coalesce(joining_is_premium, false) then
    select count(*) into circle_count from public.circle_members where profile_id = new.profile_id;
    if circle_count >= 2 then
      raise exception 'free_circle_limit_reached' using errcode = 'P0001';
    end if;
  end if;

  select public.is_effectively_premium(c.created_by) into circle_owner_is_premium
    from public.circles c
    where c.id = new.circle_id;

  if not coalesce(circle_owner_is_premium, false) then
    select count(*) into member_count from public.circle_members where circle_id = new.circle_id;
    if member_count >= 6 then
      raise exception 'free_member_limit_reached' using errcode = 'P0001';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_circle_limits_trigger on public.circle_members;
create trigger enforce_circle_limits_trigger
  before insert on public.circle_members
  for each row execute function public.enforce_circle_limits();

-- I messaggi cerchia sono pensati per pochi avvisi importanti, non per
-- chiacchierare: chi non è premium può mandarne al massimo 5 nelle ultime
-- 24 ore. È anche un limite reale sui costi (ogni messaggio genera una
-- notifica push via Edge Function): chi è Kinly+ non ha limiti.
create or replace function public.enforce_circle_message_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_is_premium boolean;
  recent_count integer;
begin
  sender_is_premium := public.is_effectively_premium(new.sender_id);

  if not coalesce(sender_is_premium, false) then
    select count(*) into recent_count
      from public.circle_messages
      where sender_id = new.sender_id
        and created_at > now() - interval '24 hours';
    if recent_count >= 5 then
      raise exception 'free_message_limit_reached' using errcode = 'P0001';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_circle_message_limit_trigger on public.circle_messages;
create trigger enforce_circle_message_limit_trigger
  before insert on public.circle_messages
  for each row execute function public.enforce_circle_message_limit();

-- La "priorità" di una richiesta di assistenza la decide il server in base
-- all'abbonamento di chi scrive al momento dell'invio, non un valore che
-- il client potrebbe falsificare.
create or replace function public.set_support_message_priority()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.is_priority := coalesce(public.is_effectively_premium(new.profile_id), false);
  return new;
end;
$$;

drop trigger if exists set_support_message_priority_trigger on public.support_messages;
create trigger set_support_message_priority_trigger
  before insert on public.support_messages
  for each row execute function public.set_support_message_priority();

-- =========================================================================
-- Row Level Security
-- =========================================================================

alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.locations enable row level security;
alter table public.location_requests enable row level security;
alter table public.location_history enable row level security;
alter table public.safe_zones enable row level security;
alter table public.safe_zone_events enable row level security;
alter table public.speed_events enable row level security;
alter table public.support_messages enable row level security;
alter table public.meeting_points enable row level security;
alter table public.meeting_point_arrivals enable row level security;
alter table public.sos_alerts enable row level security;
alter table public.sos_trusted_contacts enable row level security;
alter table public.device_tokens enable row level security;
alter table public.circle_messages enable row level security;
alter table public.help_requests enable row level security;

-- Ogni policy è preceduta da un "drop if exists" così l'intero script è
-- rieseguibile senza errori (es. dopo averlo modificato) anche se le
-- policy esistono già da un'esecuzione precedente.

-- profiles: vedo il mio profilo e quello di chi è in una mia cerchia.
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select using (id = auth.uid() or public.shares_circle_with(id));

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- circles: vedo le cerchie di cui sono membro o che ho creato.
drop policy if exists "circles_select_member" on public.circles;
create policy "circles_select_member" on public.circles
  for select using (created_by = auth.uid() or id in (select public.my_circle_ids()));

drop policy if exists "circles_insert_self" on public.circles;
create policy "circles_insert_self" on public.circles
  for insert with check (created_by = auth.uid());

-- circle_members: vedo i membri delle mie cerchie; posso aggiungermi da
-- solo (il codice invito è già stato verificato lato client tramite
-- find_circle_by_code, che è security definer).
drop policy if exists "circle_members_select" on public.circle_members;
create policy "circle_members_select" on public.circle_members
  for select using (profile_id = auth.uid() or circle_id in (select public.my_circle_ids()));

drop policy if exists "circle_members_insert_self" on public.circle_members;
create policy "circle_members_insert_self" on public.circle_members
  for insert with check (profile_id = auth.uid());

drop policy if exists "circle_members_delete_self" on public.circle_members;
create policy "circle_members_delete_self" on public.circle_members
  for delete using (profile_id = auth.uid());

-- locations: la mia posizione, o quella di chi la condivide con me secondo
-- la sua modalità (automatica / su richiesta approvata).
drop policy if exists "locations_select_visible" on public.locations;
create policy "locations_select_visible" on public.locations
  for select using (public.can_view_location(profile_id));

drop policy if exists "locations_upsert_self" on public.locations;
create policy "locations_upsert_self" on public.locations
  for insert with check (profile_id = auth.uid());

drop policy if exists "locations_update_self" on public.locations;
create policy "locations_update_self" on public.locations
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- location_requests: vedo le richieste in cui sono coinvolto.
drop policy if exists "location_requests_select" on public.location_requests;
create policy "location_requests_select" on public.location_requests
  for select using (requester_id = auth.uid() or target_id = auth.uid());

drop policy if exists "location_requests_insert" on public.location_requests;
create policy "location_requests_insert" on public.location_requests
  for insert with check (
    requester_id = auth.uid()
    and public.shares_circle_with(target_id)
    and (select sharing_mode from public.profiles where id = target_id) <> 'paused'
  );

drop policy if exists "location_requests_respond" on public.location_requests;
create policy "location_requests_respond" on public.location_requests
  for update using (target_id = auth.uid()) with check (target_id = auth.uid());

-- location_history (Kinly+): vedo lo storico di chi condivide con me solo
-- se IO sono premium (è una funzione di chi guarda, non di chi è guardato).
-- L'inserimento invece avviene sempre, indipendentemente dal piano, così
-- lo storico è già pronto quando qualcuno passa a Kinly+.
drop policy if exists "location_history_select" on public.location_history;
create policy "location_history_select" on public.location_history
  for select using (
    public.can_view_location(profile_id)
    and public.is_effectively_premium(auth.uid())
  );

drop policy if exists "location_history_insert_self" on public.location_history;
create policy "location_history_insert_self" on public.location_history
  for insert with check (profile_id = auth.uid());

-- safe_zones (Kinly+): visibili a chi è nella cerchia; create solo da chi
-- è premium.
drop policy if exists "safe_zones_select" on public.safe_zones;
create policy "safe_zones_select" on public.safe_zones
  for select using (circle_id in (select public.my_circle_ids()));

drop policy if exists "safe_zones_insert_premium" on public.safe_zones;
create policy "safe_zones_insert_premium" on public.safe_zones
  for insert with check (
    created_by = auth.uid()
    and circle_id in (select public.my_circle_ids())
    and public.is_effectively_premium(auth.uid())
  );

drop policy if exists "safe_zones_delete_own" on public.safe_zones;
create policy "safe_zones_delete_own" on public.safe_zones
  for delete using (created_by = auth.uid());

drop policy if exists "safe_zones_update_own" on public.safe_zones;
create policy "safe_zones_update_own" on public.safe_zones
  for update using (created_by = auth.uid()) with check (created_by = auth.uid());

-- safe_zone_events: vedo gli eventi delle aree delle mie cerchie; registro
-- solo i miei ingressi/uscite.
drop policy if exists "safe_zone_events_select" on public.safe_zone_events;
create policy "safe_zone_events_select" on public.safe_zone_events
  for select using (
    zone_id in (select id from public.safe_zones where circle_id in (select public.my_circle_ids()))
  );

drop policy if exists "safe_zone_events_insert_self" on public.safe_zone_events;
create policy "safe_zone_events_insert_self" on public.safe_zone_events
  for insert with check (profile_id = auth.uid());

-- speed_events (Kinly+): stessa regola di location_history — vedo gli
-- avvisi di chi condivide con me solo se IO sono premium; l'inserimento
-- (fatto da chi guida, su di sé) non richiede invece di essere premium.
drop policy if exists "speed_events_select" on public.speed_events;
create policy "speed_events_select" on public.speed_events
  for select using (
    public.can_view_location(profile_id)
    and public.is_effectively_premium(auth.uid())
  );

drop policy if exists "speed_events_insert_self" on public.speed_events;
create policy "speed_events_insert_self" on public.speed_events
  for insert with check (profile_id = auth.uid());

-- support_messages: ognuno vede e scrive solo i propri messaggi.
drop policy if exists "support_messages_select_own" on public.support_messages;
create policy "support_messages_select_own" on public.support_messages
  for select using (profile_id = auth.uid());

drop policy if exists "support_messages_insert_own" on public.support_messages;
create policy "support_messages_insert_own" on public.support_messages
  for insert with check (profile_id = auth.uid());

-- Un admin vede e può rispondere a tutti i messaggi, non solo ai propri.
drop policy if exists "support_messages_select_admin" on public.support_messages;
create policy "support_messages_select_admin" on public.support_messages
  for select using (exists (select 1 from public.profiles where id = auth.uid() and is_admin));

drop policy if exists "support_messages_update_admin" on public.support_messages;
create policy "support_messages_update_admin" on public.support_messages
  for update
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin))
  with check (exists (select 1 from public.profiles where id = auth.uid() and is_admin));

-- meeting_points: chiunque nella cerchia può proporne uno e vederli tutti;
-- solo chi l'ha creato può eliminarlo.
drop policy if exists "meeting_points_select" on public.meeting_points;
create policy "meeting_points_select" on public.meeting_points
  for select using (circle_id in (select public.my_circle_ids()));

drop policy if exists "meeting_points_insert" on public.meeting_points;
create policy "meeting_points_insert" on public.meeting_points
  for insert with check (created_by = auth.uid() and circle_id in (select public.my_circle_ids()));

drop policy if exists "meeting_points_delete_own" on public.meeting_points;
create policy "meeting_points_delete_own" on public.meeting_points
  for delete using (created_by = auth.uid());

-- meeting_point_arrivals: vedo gli arrivi ai punti delle mie cerchie;
-- registro solo il mio arrivo.
drop policy if exists "meeting_point_arrivals_select" on public.meeting_point_arrivals;
create policy "meeting_point_arrivals_select" on public.meeting_point_arrivals
  for select using (
    meeting_point_id in (select id from public.meeting_points where circle_id in (select public.my_circle_ids()))
  );

drop policy if exists "meeting_point_arrivals_insert_self" on public.meeting_point_arrivals;
create policy "meeting_point_arrivals_insert_self" on public.meeting_point_arrivals
  for insert with check (profile_id = auth.uid());

-- sos_alerts: visibile a chi condivide una cerchia con chi l'ha attivato,
-- indipendentemente da modalità di condivisione/orario di reperibilità —
-- è l'eccezione di emergenza, deliberata. Se chi l'ha attivato ha
-- configurato dei contatti di fiducia (sos_trusted_contacts), l'SOS avvisa
-- solo quelli invece di tutta la cerchia. Solo chi l'ha attivato può
-- risolverlo.
drop policy if exists "sos_alerts_select" on public.sos_alerts;
create policy "sos_alerts_select" on public.sos_alerts
  for select using (
    profile_id = auth.uid()
    or (
      public.shares_circle_with(profile_id)
      and (
        not exists (select 1 from public.sos_trusted_contacts where profile_id = sos_alerts.profile_id)
        or exists (
          select 1 from public.sos_trusted_contacts
          where profile_id = sos_alerts.profile_id and contact_id = auth.uid()
        )
      )
    )
  );

drop policy if exists "sos_alerts_insert_self" on public.sos_alerts;
create policy "sos_alerts_insert_self" on public.sos_alerts
  for insert with check (profile_id = auth.uid());

drop policy if exists "sos_alerts_update_self" on public.sos_alerts;
create policy "sos_alerts_update_self" on public.sos_alerts
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- sos_trusted_contacts: ognuno gestisce solo la propria lista, e può
-- aggiungere solo persone con cui condivide già una cerchia.
drop policy if exists "sos_trusted_contacts_select_own" on public.sos_trusted_contacts;
create policy "sos_trusted_contacts_select_own" on public.sos_trusted_contacts
  for select using (profile_id = auth.uid());

drop policy if exists "sos_trusted_contacts_insert_own" on public.sos_trusted_contacts;
create policy "sos_trusted_contacts_insert_own" on public.sos_trusted_contacts
  for insert with check (profile_id = auth.uid() and public.shares_circle_with(contact_id));

drop policy if exists "sos_trusted_contacts_delete_own" on public.sos_trusted_contacts;
create policy "sos_trusted_contacts_delete_own" on public.sos_trusted_contacts
  for delete using (profile_id = auth.uid());

-- circle_messages: visibili a chi è nella cerchia; ognuno scrive solo a
-- nome proprio, e solo nelle proprie cerchie.
drop policy if exists "circle_messages_select" on public.circle_messages;
create policy "circle_messages_select" on public.circle_messages
  for select using (circle_id in (select public.my_circle_ids()));

drop policy if exists "circle_messages_insert_self" on public.circle_messages;
create policy "circle_messages_insert_self" on public.circle_messages
  for insert with check (sender_id = auth.uid() and circle_id in (select public.my_circle_ids()));

drop policy if exists "circle_messages_delete_own" on public.circle_messages;
create policy "circle_messages_delete_own" on public.circle_messages
  for delete using (sender_id = auth.uid());

-- help_requests: visibili a chi è nella cerchia; ognuno crea/risolve solo
-- le proprie.
drop policy if exists "help_requests_select" on public.help_requests;
create policy "help_requests_select" on public.help_requests
  for select using (circle_id in (select public.my_circle_ids()));

drop policy if exists "help_requests_insert_self" on public.help_requests;
create policy "help_requests_insert_self" on public.help_requests
  for insert with check (profile_id = auth.uid() and circle_id in (select public.my_circle_ids()));

drop policy if exists "help_requests_update_self" on public.help_requests;
create policy "help_requests_update_self" on public.help_requests
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- device_tokens: ognuno gestisce solo i propri token. La Edge Function che
-- invia le notifiche usa la service_role key, che scavalca la RLS.
drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own" on public.device_tokens
  for select using (profile_id = auth.uid());

drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own" on public.device_tokens
  for insert with check (profile_id = auth.uid());

drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own" on public.device_tokens
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own" on public.device_tokens
  for delete using (profile_id = auth.uid());

-- =========================================================================
-- Ping contestuali e "incroci" (High five)
-- =========================================================================

-- Un tocco rapido su una persona sulla mappa, senza scrivere: un'emoji con
-- un significato preciso (caffè, traffico, high five) invece di un messaggio.
create table if not exists public.pings (
  id uuid primary key default gen_random_uuid(),
  from_id uuid not null references public.profiles (id) on delete cascade,
  to_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('coffee', 'traffic', 'high_five')),
  created_at timestamptz not null default now(),
  check (from_id <> to_id)
);

create index if not exists pings_to_idx on public.pings (to_id, created_at desc);

alter table public.pings enable row level security;

drop policy if exists "pings_select" on public.pings;
create policy "pings_select" on public.pings
  for select using (from_id = auth.uid() or to_id = auth.uid());

drop policy if exists "pings_insert" on public.pings;
create policy "pings_insert" on public.pings
  for insert with check (from_id = auth.uid() and public.shares_circle_with(to_id));

-- Un "incrocio" rilevato tra due persone della stessa cerchia che si sono
-- trovate a pochi metri l'una dall'altra con posizioni entrambe fresche:
-- l'app propone di mandarsi un High Five (riusa la tabella pings).
create table if not exists public.encounters (
  id uuid primary key default gen_random_uuid(),
  profile_a uuid not null references public.profiles (id) on delete cascade,
  profile_b uuid not null references public.profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  created_at timestamptz not null default now(),
  check (profile_a <> profile_b)
);

create index if not exists encounters_pair_idx on public.encounters (profile_a, profile_b, created_at desc);

alter table public.encounters enable row level security;

drop policy if exists "encounters_select" on public.encounters;
create policy "encounters_select" on public.encounters
  for select using (profile_a = auth.uid() or profile_b = auth.uid());

-- Ad ogni aggiornamento di posizione, guarda se un membro di una cerchia
-- condivisa si trova entro 60 metri con una posizione altrettanto fresca
-- (ultimi 5 minuti): se sì, e non si sono già incrociati nelle ultime 3 ore
-- (evita di spammare chi resta vicino per ore, es. stessa stanza), registra
-- l'incrocio. La distanza è calcolata con la formula dell'emisenoverso,
-- senza bisogno dell'estensione PostGIS.
create or replace function public.detect_encounters()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  nearby record;
  encounter_radius_meters constant double precision := 60;
begin
  for nearby in
    select l.profile_id
    from public.locations l
    where l.profile_id <> new.profile_id
      and l.updated_at > now() - interval '5 minutes'
      and public.shares_circle_with(l.profile_id)
      and (
        6371000 * acos(
          least(1, greatest(-1,
            sin(radians(new.lat)) * sin(radians(l.lat)) +
            cos(radians(new.lat)) * cos(radians(l.lat)) * cos(radians(l.lng) - radians(new.lng))
          ))
        )
      ) <= encounter_radius_meters
  loop
    if not exists (
      select 1 from public.encounters e
      where e.created_at > now() - interval '3 hours'
        and ((e.profile_a = new.profile_id and e.profile_b = nearby.profile_id)
          or (e.profile_a = nearby.profile_id and e.profile_b = new.profile_id))
    ) then
      insert into public.encounters (profile_a, profile_b, lat, lng) values (new.profile_id, nearby.profile_id, new.lat, new.lng);
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists detect_encounters_trigger on public.locations;
create trigger detect_encounters_trigger
  after insert or update of lat, lng on public.locations
  for each row execute function public.detect_encounters();

-- =========================================================================
-- "Portami qualcosa": rilevamento sosta in negozio/supermercato/bar
-- =========================================================================

-- Cache condivisa (nessun dato personale: solo categoria di un luogo per
-- una cella di ~11m) dei risultati di Nominatim, per non richiamare l'API
-- più volte per lo stesso posto e restare dentro i suoi limiti gratuiti.
create table if not exists public.poi_cache (
  cell_key text primary key,
  category text not null,
  place_name text,
  fetched_at timestamptz not null default now()
);

alter table public.poi_cache enable row level security;

drop policy if exists "poi_cache_select" on public.poi_cache;
create policy "poi_cache_select" on public.poi_cache for select using (true);

drop policy if exists "poi_cache_insert" on public.poi_cache;
create policy "poi_cache_insert" on public.poi_cache for insert with check (true);

drop policy if exists "poi_cache_update" on public.poi_cache;
create policy "poi_cache_update" on public.poi_cache for update using (true) with check (true);

-- Una sosta rilevata in un supermercato/negozio/bar: visibile alla propria
-- cerchia, così chi vuole può chiedere qualcosa al volo.
create table if not exists public.shopping_stops (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  circle_id uuid not null references public.circles (id) on delete cascade,
  category text not null,
  place_name text,
  lat double precision not null,
  lng double precision not null,
  created_at timestamptz not null default now()
);

create index if not exists shopping_stops_circle_idx on public.shopping_stops (circle_id, created_at desc);

alter table public.shopping_stops enable row level security;

drop policy if exists "shopping_stops_select" on public.shopping_stops;
create policy "shopping_stops_select" on public.shopping_stops
  for select using (circle_id in (select public.my_circle_ids()));

drop policy if exists "shopping_stops_insert_self" on public.shopping_stops;
create policy "shopping_stops_insert_self" on public.shopping_stops
  for insert with check (profile_id = auth.uid() and circle_id in (select public.my_circle_ids()));

-- Una richiesta al volo ("Latte!") verso chi è fermo in un negozio.
create table if not exists public.shopping_requests (
  id uuid primary key default gen_random_uuid(),
  stop_id uuid not null references public.shopping_stops (id) on delete cascade,
  from_id uuid not null references public.profiles (id) on delete cascade,
  note text not null,
  created_at timestamptz not null default now()
);

alter table public.shopping_requests enable row level security;

drop policy if exists "shopping_requests_select" on public.shopping_requests;
create policy "shopping_requests_select" on public.shopping_requests
  for select using (
    from_id = auth.uid()
    or exists (select 1 from public.shopping_stops s where s.id = stop_id and s.profile_id = auth.uid())
  );

drop policy if exists "shopping_requests_insert" on public.shopping_requests;
create policy "shopping_requests_insert" on public.shopping_requests
  for insert with check (
    from_id = auth.uid()
    and exists (select 1 from public.shopping_stops s where s.id = stop_id and s.circle_id in (select public.my_circle_ids()))
  );

-- =========================================================================
-- Spese di gruppo (stile Splitwise: solo un registro, nessun pagamento
-- reale — Kinly non muove soldi. "Chiedi il saldo" apre il payment_link
-- personale dell'altra persona, se l'ha impostato)
-- =========================================================================

create table if not exists public.circle_expenses (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  paid_by uuid not null references public.profiles (id) on delete cascade,
  description text not null,
  amount numeric(10, 2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

alter table public.circle_expenses enable row level security;

drop policy if exists "circle_expenses_select" on public.circle_expenses;
create policy "circle_expenses_select" on public.circle_expenses
  for select using (circle_id in (select public.my_circle_ids()));

drop policy if exists "circle_expenses_insert" on public.circle_expenses;
create policy "circle_expenses_insert" on public.circle_expenses
  for insert with check (paid_by = auth.uid() and circle_id in (select public.my_circle_ids()));

drop policy if exists "circle_expenses_delete_own" on public.circle_expenses;
create policy "circle_expenses_delete_own" on public.circle_expenses
  for delete using (paid_by = auth.uid());

create table if not exists public.expense_shares (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.circle_expenses (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  share_amount numeric(10, 2) not null check (share_amount > 0)
);

alter table public.expense_shares enable row level security;

drop policy if exists "expense_shares_select" on public.expense_shares;
create policy "expense_shares_select" on public.expense_shares
  for select using (
    exists (select 1 from public.circle_expenses e where e.id = expense_id and e.circle_id in (select public.my_circle_ids()))
  );

drop policy if exists "expense_shares_insert" on public.expense_shares;
create policy "expense_shares_insert" on public.expense_shares
  for insert with check (
    exists (select 1 from public.circle_expenses e where e.id = expense_id and e.paid_by = auth.uid())
  );

-- =========================================================================
-- Permessi a livello di colonna
-- =========================================================================

-- Le policy RLS sopra dicono "puoi aggiornare la tua riga", ma senza questo
-- non impediscono di aggiornare QUALSIASI colonna della propria riga —
-- incluso is_premium. Senza questa restrizione, chiunque potrebbe attivarsi
-- Kinly+ da solo con una singola chiamata, aggirando qualunque sistema di
-- pagamento futuro. Impostato così, is_premium è modificabile solo da SQL
-- Editor (o da un futuro processo server-side con la service_role key) — e
-- resta valido a tempo indeterminato, dato che non c'è (ancora) una data di
-- scadenza: è un "abbonamento a vita" finché non lo si disattiva a mano.
revoke update on public.profiles from authenticated;
grant update (
  name, color, sharing_mode, battery_percent, speed_alert_kmh, auto_ghost_start, auto_ghost_end, avatar_key,
  birthday, status_emoji, status_text, status_expires_at, payment_link
) on public.profiles to authenticated;

-- =========================================================================
-- Realtime (idempotente: evita errori se rilanci lo script)
-- =========================================================================

do $$
declare
  t text;
begin
  foreach t in array array['profiles', 'circle_members', 'locations', 'location_requests', 'safe_zones', 'safe_zone_events', 'speed_events', 'meeting_points', 'meeting_point_arrivals', 'sos_alerts', 'sos_trusted_contacts', 'circle_messages', 'help_requests', 'pings', 'encounters', 'shopping_stops', 'shopping_requests', 'circle_expenses', 'expense_shares']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- =========================================================================
-- Pulizia automatica della cronologia posizioni (90 giorni)
-- =========================================================================

-- Richiede l'estensione pg_cron: su Supabase si abilita da Database >
-- Extensions se questa riga dovesse fallire per permessi mancanti.
create extension if not exists pg_cron;

do $$
begin
  perform cron.unschedule('kinly_location_history_cleanup');
exception when others then
  null; -- non era ancora schedulato: va bene, si schedula sotto.
end $$;

select cron.schedule(
  'kinly_location_history_cleanup',
  '0 3 * * *',
  $$delete from public.location_history where recorded_at < now() - interval '90 days'$$
);
