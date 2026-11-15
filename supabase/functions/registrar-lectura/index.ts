// Supabase Edge Function: POST /functions/v1/registrar-lectura
// Secrets requeridos: DEVICE_TOKEN, SUPABASE_SECRET_KEY
// SUPABASE_URL está disponible por defecto en Supabase Edge Functions.
import { createClient } from 'npm:@supabase/supabase-js@2.76.1';

const dbUrl = Deno.env.get('SUPABASE_URL') ?? '';
const dbSecret = Deno.env.get('SUPABASE_SECRET_KEY') ?? '';
const deviceToken = Deno.env.get('DEVICE_TOKEN') ?? '';

const supabase = createClient(dbUrl || 'https://invalid.supabase.co', dbSecret || 'missing', {
  auth: { persistSession: false, autoRefreshToken: false },
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json({ error: 'Solo POST' }, 405);
  if (!deviceToken || !dbUrl || !dbSecret) return json({ error: 'Servidor sin configurar' }, 503);
  if (req.headers.get('x-device-token') !== deviceToken) return json({ error: 'No autorizado' }, 401);

  let body: Record<string, unknown>;
  try {
    const raw = await req.text();
    if (raw.length > 2048) return json({ error: 'Solicitud demasiado grande' }, 413);
    body = JSON.parse(raw);
    if (!body || Array.isArray(body) || typeof body !== 'object') throw Error('Invalid JSON');
  } catch { return json({ error: 'JSON inválido' }, 400); }

  const temperatura = body.temperatura;
  const humedad = body.humedad;
  const dispositivo = body.dispositivo;
  const simulada = body.simulada;
  if (typeof temperatura !== 'number' || !Number.isFinite(temperatura) || temperatura < -40 || temperatura > 80 ||
      typeof humedad !== 'number' || !Number.isFinite(humedad) || humedad < 0 || humedad > 100 ||
      typeof dispositivo !== 'string' || !/^[a-zA-Z0-9_-]{1,64}$/.test(dispositivo) ||
      typeof simulada !== 'boolean') {
    return json({ error: 'Campos inválidos: dispositivo, temperatura, humedad, simulada' }, 400);
  }

  const { error } = await supabase.from('lecturas_ambientales').insert({
    dispositivo, temperatura, humedad, simulada,
  });
  if (error) {
    console.error('Error al insertar:', error.message);
    return json({ error: 'No se pudo guardar la lectura' }, 500);
  }
  return json({ ok: true }, 201);
});
