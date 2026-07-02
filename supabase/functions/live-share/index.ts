// supabase/functions/live-share/index.ts
//
// API pubblica per il link "seguimi": restituisce SOLO dati in JSON (mai
// pagine HTML). Supabase riscrive sempre Content-Type: text/html in
// text/plain sul dominio condiviso *.supabase.co (limite della piattaforma,
// non aggirabile senza un piano Pro con dominio personalizzato), quindi la
// pagina vera con la mappa vive altrove: su GitHub Pages, nel file
// docs/live-share.html di questo stesso repository, che chiama questa
// funzione via fetch (per questo qui sotto c'e' il CORS).
//
// IMPORTANTE per il deploy: questa funzione deve essere pubblica (chi apre
// il link non ha un account Kinly), quindi va deployata SENZA verifica JWT:
//   supabase functions deploy live-share --no-verify-jwt
// (oppure, dal Dashboard, disattiva "Verify JWT" per questa funzione).
//
// Nessun segreto da configurare: usa SUPABASE_URL e
// SUPABASE_SERVICE_ROLE_KEY gia' presenti di default in ogni Edge Function.

import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const token = url.searchParams.get('t');
  const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };
  if (!token) {
    return new Response(JSON.stringify({ error: 'missing_token' }), { status: 400, headers: jsonHeaders });
  }

  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: link } = await supabase
    .from('live_share_links')
    .select('profile_id, expires_at')
    .eq('token', token)
    .maybeSingle();

  const expired = !link || new Date(link.expires_at) < new Date();
  if (expired) {
    return new Response(JSON.stringify({ expired: true }), { headers: jsonHeaders });
  }

  const [{ data: loc }, { data: profile }] = await Promise.all([
    supabase.from('locations').select('lat, lng, updated_at').eq('profile_id', link!.profile_id).maybeSingle(),
    supabase.from('profiles').select('name, color, avatar_key, battery_percent').eq('id', link!.profile_id).single(),
  ]);

  return new Response(
    JSON.stringify({
      expired: false,
      name: profile?.name ?? 'Qualcuno',
      color: profile?.color ?? '#4A63E7',
      avatar_key: profile?.avatar_key ?? null,
      battery_percent: profile?.battery_percent ?? null,
      lat: loc?.lat ?? null,
      lng: loc?.lng ?? null,
      updated_at: loc?.updated_at ?? null,
      expires_at: link!.expires_at,
    }),
    { headers: jsonHeaders },
  );
});
