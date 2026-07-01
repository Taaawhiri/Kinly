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
  is_premium boolean not null default false;

alter table public.profiles add column if not exists
  -- Soglia di velocità (km/h) oltre la quale si registra un avviso di
  -- guida (Kinly+): null = avvisi disattivati. La imposta chi guida, su
  -- di sé; a vederne gli avvisi sono i membri premium della sua cerchia.
  speed_alert_kmh integer check (speed_alert_kmh between 20 and 300);

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

create index if not exists circle_members_profile_idx on public.circle_members (profile_id);
create index if not exists location_requests_requester_idx on public.location_requests (requester_id);
create index if not exists location_requests_target_idx on public.location_requests (target_id);
create index if not exists location_history_profile_idx on public.location_history (profile_id, recorded_at desc);
create index if not exists safe_zones_circle_idx on public.safe_zones (circle_id);
create index if not exists safe_zone_events_zone_idx on public.safe_zone_events (zone_id, occurred_at desc);
create index if not exists speed_events_profile_idx on public.speed_events (profile_id, occurred_at desc);
create index if not exists support_messages_profile_idx on public.support_messages (profile_id, created_at desc);

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
      and (
        (select sharing_mode from public.profiles where id = p_target_id) = 'automatic'
        or exists (
          select 1 from public.location_requests
          where requester_id = auth.uid()
            and target_id = p_target_id
            and status = 'accepted'
        )
      )
    );
$$;

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
  select is_premium into joining_is_premium from public.profiles where id = new.profile_id;

  if not coalesce(joining_is_premium, false) then
    select count(*) into circle_count from public.circle_members where profile_id = new.profile_id;
    if circle_count >= 2 then
      raise exception 'free_circle_limit_reached' using errcode = 'P0001';
    end if;
  end if;

  select p.is_premium into circle_owner_is_premium
    from public.circles c
    join public.profiles p on p.id = c.created_by
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
  new.is_priority := coalesce((select is_premium from public.profiles where id = new.profile_id), false);
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
    and exists (select 1 from public.profiles where id = auth.uid() and is_premium)
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
    and exists (select 1 from public.profiles where id = auth.uid() and is_premium)
  );

drop policy if exists "safe_zones_delete_own" on public.safe_zones;
create policy "safe_zones_delete_own" on public.safe_zones
  for delete using (created_by = auth.uid());

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
    and exists (select 1 from public.profiles where id = auth.uid() and is_premium)
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

-- =========================================================================
-- Realtime (idempotente: evita errori se rilanci lo script)
-- =========================================================================

do $$
declare
  t text;
begin
  foreach t in array array['profiles', 'circle_members', 'locations', 'location_requests', 'safe_zones', 'safe_zone_events', 'speed_events']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
