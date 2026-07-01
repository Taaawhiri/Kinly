// supabase/functions/live-share/index.ts
//
// Pagina pubblica "seguimi": chi riceve il link (anche SENZA l'app Kinly)
// apre nel browser una piccola mappa con la posizione live di chi l'ha
// condiviso, finché il link non scade. L'accesso è autorizzato solo dal
// token (lungo e casuale) contenuto nel link: la funzione lo verifica in
// public.live_share_links e legge la posizione con la service role key.
//
// IMPORTANTE per il deploy: questa funzione deve essere pubblica (chi apre
// il link non ha un account), quindi va deployata SENZA verifica JWT:
//   supabase functions deploy live-share --no-verify-jwt
// (oppure, dal Dashboard, disattiva "Verify JWT" per questa funzione).
//
// Nessun segreto da configurare: usa SUPABASE_URL e
// SUPABASE_SERVICE_ROLE_KEY già presenti di default in ogni Edge Function.

import { createClient } from 'npm:@supabase/supabase-js@2';

function htmlPage(name: string, token: string): string {
  // Leaflet via CDN + tile OpenStreetMap: nessuna chiave, coerente con la
  // scelta OpenStreetMap del resto dell'app. La pagina si aggiorna da sola
  // ogni 15 secondi richiamando questa stessa funzione in formato JSON.
  return `<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${name} · posizione live · Kinly</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<style>
  body { margin: 0; font-family: system-ui, sans-serif; }
  #map { position: fixed; inset: 0; }
  .banner {
    position: fixed; top: 12px; left: 12px; right: 12px; z-index: 1000;
    background: white; border-radius: 14px; padding: 12px 16px;
    box-shadow: 0 4px 14px rgba(0,0,0,0.15); font-size: 14px;
  }
  .banner b { color: #4A63E7; }
  .expired { color: #C0392B; font-weight: 600; }
</style>
</head>
<body>
<div class="banner" id="banner">Posizione live di <b>${name}</b> · condivisa con Kinly</div>
<div id="map"></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
  const map = L.map('map').setView([45.4642, 9.19], 13);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap'
  }).addTo(map);
  let marker = null;
  let centered = false;

  async function refresh() {
    try {
      const res = await fetch(location.pathname + '?t=${token}&format=json');
      const data = await res.json();
      if (data.expired) {
        document.getElementById('banner').innerHTML = '<span class="expired">Questo link è scaduto.</span>';
        return;
      }
      if (data.lat == null) return;
      const pos = [data.lat, data.lng];
      if (!marker) {
        marker = L.marker(pos).addTo(map);
      } else {
        marker.setLatLng(pos);
      }
      if (!centered) { map.setView(pos, 15); centered = true; }
      setTimeout(refresh, 15000);
    } catch (_) {
      setTimeout(refresh, 30000);
    }
  }
  refresh();
</script>
</body>
</html>`;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const token = url.searchParams.get('t');
  if (!token) return new Response('Link non valido.', { status: 400 });

  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: link } = await supabase
    .from('live_share_links')
    .select('profile_id, expires_at')
    .eq('token', token)
    .maybeSingle();

  const expired = !link || new Date(link.expires_at) < new Date();
  const wantsJson = url.searchParams.get('format') === 'json';

  if (wantsJson) {
    if (expired) {
      return new Response(JSON.stringify({ expired: true }), { headers: { 'Content-Type': 'application/json' } });
    }
    const { data: loc } = await supabase
      .from('locations')
      .select('lat, lng, updated_at')
      .eq('profile_id', link!.profile_id)
      .maybeSingle();
    return new Response(
      JSON.stringify({ expired: false, lat: loc?.lat ?? null, lng: loc?.lng ?? null, updated_at: loc?.updated_at ?? null }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  }

  if (expired) {
    return new Response('<html><body style="font-family:sans-serif;padding:40px;text-align:center"><h2>Questo link è scaduto.</h2></body></html>', {
      headers: { 'Content-Type': 'text/html; charset=utf-8' },
    });
  }

  const { data: profile } = await supabase.from('profiles').select('name').eq('id', link!.profile_id).single();
  return new Response(htmlPage(profile?.name ?? 'Qualcuno', token), {
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
  });
});
