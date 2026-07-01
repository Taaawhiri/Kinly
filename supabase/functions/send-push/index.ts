// supabase/functions/send-push/index.ts
//
// Riceve un evento da un Database Webhook di Supabase (INSERT su
// sos_alerts, safe_zone_events o location_requests) e spedisce una
// notifica push reale via Firebase Cloud Messaging ai destinatari giusti.
// I token dei dispositivi vengono letti da public.device_tokens con la
// service_role key (bypassa la RLS, che qui non serve: questa funzione
// gira solo lato server).
//
// Configurazione richiesta (Supabase Dashboard → Edge Functions →
// Secrets, o `supabase secrets set`):
//   FIREBASE_SERVICE_ACCOUNT = contenuto intero del file JSON scaricato da
//     Firebase Console → Project settings → Service accounts → Generate
//     new private key. È un segreto: non va MAI committato nel repository.
//
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sono già disponibili di default
// in ogni Edge Function Supabase: non vanno impostati a mano.
//
// Poi, in Database → Webhooks, crea un hook per ciascuna tabella
// (sos_alerts, safe_zone_events, location_requests), evento INSERT, tipo
// "Supabase Edge Functions", puntato su questa funzione.

import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';
import { SignJWT, importPKCS8 } from 'npm:jose@5';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri: string;
}

interface NotificationPlan {
  recipients: string[];
  title: string;
  body: string;
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.token;
  }
  const privateKey = await importPKCS8(account.private_key, 'RS256');
  const jwt = await new SignJWT({ scope: FCM_SCOPE })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(account.client_email)
    .setAudience(account.token_uri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch(account.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!response.ok) {
    throw new Error(`Impossibile ottenere il token OAuth Firebase: ${await response.text()}`);
  }
  const data = await response.json();
  cachedAccessToken = { token: data.access_token, expiresAt: now + data.expires_in };
  return data.access_token;
}

async function sendToToken(
  account: ServiceAccount,
  accessToken: string,
  token: string,
  title: string,
  body: string,
): Promise<{ token: string; invalid: boolean }> {
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: { token, notification: { title, body }, android: { priority: 'high' } },
    }),
  });
  if (!response.ok) {
    const text = await response.text();
    // Un token scaduto/disinstallato produce sempre lo stesso errore: lo
    // segnaliamo come "invalid" per rimuoverlo e non ritentare invano ad
    // ogni evento futuro.
    if (text.includes('UNREGISTERED') || text.includes('NOT_FOUND')) {
      return { token, invalid: true };
    }
    console.error(`Invio FCM fallito per un token: ${text}`);
  }
  return { token, invalid: false };
}

async function fetchName(supabase: SupabaseClient, profileId: string): Promise<string> {
  const { data } = await supabase.from('profiles').select('name').eq('id', profileId).single();
  return data?.name ?? 'Qualcuno';
}

async function circleRecipients(supabase: SupabaseClient, circleId: string, excludeProfileId: string): Promise<string[]> {
  const { data } = await supabase.from('circle_members').select('profile_id').eq('circle_id', circleId);
  return (data ?? []).map((r: { profile_id: string }) => r.profile_id).filter((id: string) => id !== excludeProfileId);
}

/// Replica la logica della policy RLS sos_alerts_select: tutta la cerchia,
/// a meno che non siano stati configurati dei contatti di fiducia.
async function sosRecipients(supabase: SupabaseClient, profileId: string): Promise<string[]> {
  const { data: circles } = await supabase.from('circle_members').select('circle_id').eq('profile_id', profileId);
  const circleIds = (circles ?? []).map((c: { circle_id: string }) => c.circle_id);
  if (circleIds.length === 0) return [];

  const { data: members } = await supabase.from('circle_members').select('profile_id').in('circle_id', circleIds);
  const allMembers = new Set((members ?? []).map((m: { profile_id: string }) => m.profile_id));
  allMembers.delete(profileId);

  const { data: trusted } = await supabase.from('sos_trusted_contacts').select('contact_id').eq('profile_id', profileId);
  if (trusted && trusted.length > 0) {
    const trustedIds = new Set(trusted.map((t: { contact_id: string }) => t.contact_id));
    return [...allMembers].filter((id) => trustedIds.has(id));
  }
  return [...allMembers];
}

/// Testo personalizzato in base al tipo di area sicura: "casa"/"lavoro"/
/// "scuola" hanno un'emoji ed una frase dedicate, così la notifica sembra
/// scritta apposta invece di un generico "ingresso registrato".
function zoneNotificationText(
  kind: string,
  zoneName: string,
  personName: string,
  entering: boolean,
): { emoji: string; title: string; body: string } {
  switch (kind) {
    case 'home':
      return {
        emoji: '🏠',
        title: 'Casa',
        body: entering ? `${personName} è arrivato/a a casa.` : `${personName} è uscito/a da casa.`,
      };
    case 'work':
      return {
        emoji: '💼',
        title: 'Lavoro',
        body: entering ? `${personName} è arrivato/a al lavoro.` : `${personName} ha lasciato il lavoro.`,
      };
    case 'school':
      return {
        emoji: '🏫',
        title: 'Scuola',
        body: entering ? `${personName} è arrivato/a a scuola.` : `${personName} è uscito/a da scuola.`,
      };
    default:
      return {
        emoji: '📍',
        title: 'Aree sicure',
        body: entering ? `${personName} è arrivato/a in "${zoneName}".` : `${personName} è uscito/a da "${zoneName}".`,
      };
  }
}

async function buildNotification(supabase: SupabaseClient, table: string, record: any): Promise<NotificationPlan | null> {
  switch (table) {
    case 'sos_alerts': {
      const profileId = record.profile_id as string;
      const [name, recipients] = await Promise.all([fetchName(supabase, profileId), sosRecipients(supabase, profileId)]);
      return { recipients, title: '🆘 SOS attivato', body: `${name} ha attivato l'SOS: apri Kinly per vedere dove si trova.` };
    }
    case 'safe_zone_events': {
      const { data: zone } = await supabase.from('safe_zones').select('name, circle_id, kind').eq('id', record.zone_id).single();
      if (!zone) return null;
      const [name, recipients] = await Promise.all([
        fetchName(supabase, record.profile_id),
        circleRecipients(supabase, zone.circle_id, record.profile_id),
      ]);
      const entering = record.event_type === 'enter';
      const { emoji, title, body } = zoneNotificationText(zone.kind, zone.name, name, entering);
      return { recipients, title: `${emoji} ${title}`, body };
    }
    case 'location_requests': {
      return { recipients: [record.target_id], title: 'Richiesta di posizione', body: 'Qualcuno ha chiesto di vedere la tua posizione.' };
    }
    case 'circle_messages': {
      const [name, recipients] = await Promise.all([
        fetchName(supabase, record.sender_id),
        circleRecipients(supabase, record.circle_id, record.sender_id),
      ]);
      return { recipients, title: name, body: record.body };
    }
    default:
      return null;
  }
}

Deno.serve(async (req) => {
  try {
    const account: ServiceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');
    if (!account.private_key) {
      return new Response('FIREBASE_SERVICE_ACCOUNT non configurato', { status: 500 });
    }

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

    const payload = await req.json();
    const { table, type, record } = payload;
    if (type !== 'INSERT' || !record) {
      return new Response('ok', { status: 200 });
    }

    const plan = await buildNotification(supabase, table, record);
    if (!plan || plan.recipients.length === 0) return new Response('ok', { status: 200 });

    const { data: tokens } = await supabase.from('device_tokens').select('token').in('profile_id', plan.recipients);
    if (!tokens || tokens.length === 0) return new Response('ok', { status: 200 });

    const accessToken = await getAccessToken(account);
    const results = await Promise.all(
      tokens.map((row: { token: string }) => sendToToken(account, accessToken, row.token, plan.title, plan.body)),
    );

    const invalidTokens = results.filter((r) => r.invalid).map((r) => r.token);
    if (invalidTokens.length > 0) {
      await supabase.from('device_tokens').delete().in('token', invalidTokens);
    }

    return new Response('ok', { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(String(error), { status: 500 });
  }
});
