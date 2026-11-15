# Monitor ambiental ESP32 + Supabase

## Contenido
- `supabase/schema.sql`: tabla, índice y política RLS de lectura pública.
- `supabase/functions/registrar-lectura/index.ts`: función HTTP para insertar lecturas con token del dispositivo.
- `arduino/monitor_ambiental/monitor_ambiental.ino`: código ESP32. Empieza en modo simulado sin sensor.
- `web/`: dashboard HTML/CSS/JS sin dependencias. Empieza en modo demo.

## 1. Proyecto nuevo de Supabase
En https://supabase.com/dashboard crea un proyecto distinto a VetTrack, por ejemplo `Monitor-Ambiental-ESP32`. Si Supabase muestra un coste, revísalo antes de continuar.

## 2. Base de datos
Abre SQL Editor > New query y ejecuta el contenido de `supabase/schema.sql`.
La tabla `lecturas_ambientales` tendrá RLS, lectura pública de mediciones y escritura bloqueada para visitantes.
Esto es una demostración con datos no sensibles. No almacenes información privada aquí.

## 3. Edge Function
En Supabase crea la Edge Function `registrar-lectura` y usa `supabase/functions/registrar-lectura/index.ts`.
Configura estos secretos en Edge Functions > Secrets:
- `DEVICE_TOKEN`: inventa un token largo, aleatorio y privado (32 bytes o más, preferiblemente generado por gestor de contraseñas).
- `SUPABASE_SECRET_KEY`: clave secreta `sb_secret_...` del proyecto. Nunca ponerla en el ESP32 ni en el sitio web.
`SUPABASE_URL` está disponible automáticamente en el entorno de Supabase.

**Importante**: configura la función con **Verify JWT = OFF** porque el ESP32 se autentica con `x-device-token` validado por el código de la función. Este endpoint sigue protegido por el token compartido, no está abierto a escritura anónima. No uses la clave publishable como token de dispositivo. No publiques `DEVICE_TOKEN` ni el sketch configurado.

## 4. Arduino IDE
Abre `arduino/monitor_ambiental/monitor_ambiental.ino`. Cambia `WIFI_NOMBRE`, `WIFI_CLAVE`, `FUNCION_URL` y `DEVICE_TOKEN`. Elige tu placa ESP32 y puerto COM y sube el código. Abre Monitor Serie a 115200 baudios.
El programa manda datos simulados cada 15 segundos. La opción `MODO_PRUEBA_TLS=true` desactiva la validación del certificado HTTPS, **solo apropiada para prototipos controlados**. Antes de desplegar realmente, configurar CA con `setCACert()` y dejar de usar `setInsecure()`.
Para pasar al DHT11, conecta con USB desconectado: pata 1 del DHT11 -> 3V3; pata 2 -> GPIO4; pata 3 sin conectar; pata 4 -> GND; resistencia 4.7-10k entre patas 1 y 2. Instala `DHT sensor library` y `Adafruit Unified Sensor`, luego cambia `USAR_DHT11` a 1.

## 5. Web
En VS Code abre `web/` y sirve con Live Server, o desde una terminal ejecuta `python -m http.server 5500 --directory web` desde la raíz del proyecto, luego abre http://localhost:5500.
El panel inicia con ejemplos visuales. Presiona **Configurar Supabase** e introduce la URL de proyecto y la clave **publishable** `sb_publishable_...`. La clave publishable es pública por diseño y solo tiene permiso de lectura RLS. La configuración se guarda solo por la sesión del navegador.

## 6. Verificación
En SQL Editor:
`select * from public.lecturas_ambientales order by creada_en desc limit 10;`
En Monitor Serie deberías ver `HTTP 201` al enviar datos, una vez completados los pasos anteriores. Si recibes 401 verifica el token y configuración de función; si recibes 500 revisa secretos y logs de función.

## Seguridad
- Secret key / service-role solo en backend.
- Device token solo en ESP32 y secretos de función, nunca en dashboard web o repositorios públicos.
- RLS activo con acceso público de lectura solamente para datos no sensibles.
- El modo TLS sin verificación es temporal y no debe usarse en despliegues reales.
- Wi-Fi 2.4 GHz, compatible con ESP32 tradicional.

## 7. ATMOS Mobile (Flutter)

La aplicación móvil está en `mobile/`. Usa el proyecto Supabase existente; **no crees otro proyecto ni vuelvas a ejecutar el esquema para usar Mobile**. Consulta las [instrucciones de ATMOS Mobile](mobile/README.md) para configuración, arquitectura y limitaciones.

```powershell
cd mobile
flutter pub get
Copy-Item config.example.json config.local.json
# Sustituye el marcador en config.local.json por tu publishable key
flutter run -d chrome --dart-define-from-file=config.local.json
```

Incluye inicio, historial con gráficas independientes, alertas dentro de la interfaz y preferencias persistentes. La lectura es pública mediante RLS; no hay autenticación de usuarios ni notificaciones en segundo plano.

Nota: `supabase/schema.sql` es una referencia antigua con `dispositivo` y `creada_en`. La app móvil y las consultas actuales de la web usan `dispositivo_id` y `creado_en`. No se ha modificado el esquema desplegado.
