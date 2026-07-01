-- Kinly — schema Supabase (Postgres + RLS)
--
-- Da eseguire una volta sul progetto Supabase (SQL editor oppure
-- `supabase db push` se usi la CLI con le migration in questa cartella).
-- Presuppone Supabase Auth per l'accesso (email OTP): non c'è registrazione
-- pubblica nel senso tradizionale, ma chiunque può autenticarsi con la
-- propria email — l'accesso "solo su invito" riguarda le cerchie, non
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

create index if not exists circle_members_profile_idx on public.circle_members (profile_id);
create index if not exists location_requests_requester_idx on public.location_requests (requester_id);
create index if not exists location_requests_target_idx on public.location_requests (target_id);

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
-- Supabase Auth (email OTP). Il nome iniziale arriva dai metadata passati a
-- signUp/signInWithOtp (`data: {'name': ...}`), altrimenti resta 'Io'.
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

-- =========================================================================
-- Row Level Security
-- =========================================================================

alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.locations enable row level security;
alter table public.location_requests enable row level security;

-- profiles: vedo il mio profilo e quello di chi è in una mia cerchia.
create policy "profiles_select" on public.profiles
  for select using (id = auth.uid() or public.shares_circle_with(id));

create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

create policy "profiles_update_self" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- circles: vedo le cerchie di cui sono membro o che ho creato.
create policy "circles_select_member" on public.circles
  for select using (created_by = auth.uid() or id in (select public.my_circle_ids()));

create policy "circles_insert_self" on public.circles
  for insert with check (created_by = auth.uid());

-- circle_members: vedo i membri delle mie cerchie; posso aggiungermi da
-- solo (il codice invito è già stato verificato lato client tramite
-- find_circle_by_code, che è security definer).
create policy "circle_members_select" on public.circle_members
  for select using (profile_id = auth.uid() or circle_id in (select public.my_circle_ids()));

create policy "circle_members_insert_self" on public.circle_members
  for insert with check (profile_id = auth.uid());

create policy "circle_members_delete_self" on public.circle_members
  for delete using (profile_id = auth.uid());

-- locations: la mia posizione, o quella di chi la condivide con me secondo
-- la sua modalità (automatica / su richiesta approvata).
create policy "locations_select_visible" on public.locations
  for select using (public.can_view_location(profile_id));

create policy "locations_upsert_self" on public.locations
  for insert with check (profile_id = auth.uid());

create policy "locations_update_self" on public.locations
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- location_requests: vedo le richieste in cui sono coinvolto.
create policy "location_requests_select" on public.location_requests
  for select using (requester_id = auth.uid() or target_id = auth.uid());

create policy "location_requests_insert" on public.location_requests
  for insert with check (
    requester_id = auth.uid()
    and public.shares_circle_with(target_id)
    and (select sharing_mode from public.profiles where id = target_id) <> 'paused'
  );

create policy "location_requests_respond" on public.location_requests
  for update using (target_id = auth.uid()) with check (target_id = auth.uid());

-- =========================================================================
-- Realtime (idempotente: evita errori se rilanci lo script)
-- =========================================================================

do $$
declare
  t text;
begin
  foreach t in array array['profiles', 'circle_members', 'locations', 'location_requests']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
