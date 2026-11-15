
import { createClient } from 'npm:@supabase/supabase-js@2.76.1';

const url = Deno.env.get('SUPABASE_URL') ?? '';
const secret = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const deviceToken = Deno.env.get('DEVICE_TOKEN') ?? '';

function responder(datos: unknown, status = 200) {
  return new Response(JSON.stringify(datos), {
    status,
    headers: {
      'Content-Type': 'application/json'
    }
  });
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return responder({ error: 'Solo POST' }, 405);
  }

  if (!url || !secret || !deviceToken) {
    return responder({ error: 'Servidor sin configurar' }, 503);
  }

  if (req.headers.get('x-device-token') !== deviceToken) {
    return responder({ error: 'No autorizado' }, 401);
  }

  let datos;

  try {
    datos = await req.json();
  } catch {
    return responder({ error: 'JSON invalido' }, 400);
  }

  const { dispositivo, temperatura, humedad, simulada } = datos ?? {};

  if (
    typeof dispositivo !== 'string' ||
    !/^[a-zA-Z0-9_-]{1,64}$/.test(dispositivo) ||
    typeof temperatura !== 'number' ||
    !Number.isFinite(temperatura) ||
    temperatura < -20 || temperatura > 80 ||
    typeof humedad !== 'number' ||
    !Number.isFinite(humedad) ||
    humedad < 0 || humedad > 100 ||
    typeof simulada !== 'boolean'
  ) {
    return responder({ error: 'Datos invalidos' }, 400);
  }

  const supabase = createClient(url, secret);

  const { error } = await supabase
    .from('lecturas_ambientales')
    .insert({
      dispositivo_id: dispositivo,
      temperatura,
      humedad,
      simulada
    });

  if (error) {
    console.error(error.message);
    return responder({ error: 'Error al guardar' }, 500);
  }

  return responder({ ok: true }, 201);
});
