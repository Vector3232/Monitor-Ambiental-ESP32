# ATMOS Mobile

Aplicación Flutter Material 3 del repositorio ATMOS. Consulta exclusivamente el proyecto existente `https://flxtndpcvwxmpludoehb.supabase.co`; no inserta mediciones.

## Ejecutar

Desde `mobile/`, en PowerShell:

```powershell
flutter pub get
Copy-Item config.example.json config.local.json
# Edita config.local.json y sustituye el marcador por tu clave sb_publishable_...
flutter run -d chrome --dart-define-from-file=config.local.json
```

`config.local.json` está ignorado por Git. También puedes usar `--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...`. Nunca uses secret keys, service_role, DEVICE_TOKEN ni contraseñas Wi-Fi. Una publishable key queda incluida en el cliente compilado por diseño; el acceso depende de RLS. Sin clave válida, la interfaz muestra instrucciones y no consulta ni inventa mediciones.

Para Android, una vez instalado el SDK y conectado un dispositivo:

```powershell
flutter devices
flutter run -d ID_DEL_DISPOSITIVO --dart-define-from-file=config.local.json
```

## Funciones y comportamiento

- Inicio: última lectura del dispositivo seleccionado, temperatura, humedad, origen real/simulado, hora local y actualización manual.
- El dispositivo tiene datos recientes si su última lectura tiene entre 0 y 60 segundos de antigüedad. El estado de consulta a Supabase se presenta por separado. Si falla una consulta se conservan los datos previos con un aviso.
- Historial: filtros de 1 hora, 24 horas y 7 días; consulta por dispositivo; páginas de 200 registros. Gráficas independientes en °C y %, ordenadas por fecha y con distancias proporcionales al tiempo. Toca un punto para ver hora y valor. No se agregan ni fabrican mediciones.
- Cada actualización recarga los 200 registros más recientes del período; `Cargar 200 anteriores` amplía temporalmente la vista. Las gráficas y alertas de historial abarcan los registros cargados, no la totalidad de la base de datos.
- Alertas: límites mínimo y máximo validados, persistencia local y avisos para la última lectura y el historial cargado. Los límites son inclusivos. No hay push ni ejecución en segundo plano.
- Ajustes: identificador del ESP32 (inicialmente `esp32-01`), sincronización, origen, umbrales y versión 1.0.0+1. Cambia el identificador por el que realmente envía tu ESP32. Preferencias por instalación/navegador, sin sincronización entre dispositivos.
- Actualización cada 15 segundos en primer plano; pausa al ocultar la aplicación y refresca al regresar. Se evita solapar consultas y se cancela el temporizador al liberar recursos. Fechas conservadas en UTC y mostradas en la zona local del dispositivo.

## Arquitectura

- `lib/main.dart`: configuración pública y arranque.
- `lib/app/atmos_app.dart`: tema ATMOS y navegación.
- `lib/core/monitor_controller.dart`: estado, ciclo de vida, consultas y preferencias.
- `lib/models/`: lectura tipada y umbrales.
- `lib/services/`: consultas Supabase de solo lectura y almacenamiento local.
- `lib/features/`: dashboard, history, alerts y settings.
- `lib/widgets/atmos_widgets.dart`: tarjetas, fechas y registros compartidos.
- `test/widget_test.dart`: validación del modelo, frescura, umbrales, concurrencia y vistas responsive.

## Contrato de datos y seguridad

Se consulta `public.lecturas_ambientales` con `id`, `dispositivo_id`, `temperatura`, `humedad`, `simulada`, `creado_en`. Estos nombres coinciden con la especificación actual y las consultas del panel web. El archivo histórico `supabase/schema.sql` todavía usa `dispositivo` y `creada_en`: **no lo vuelvas a ejecutar para configurar la app**. No se modificaron tablas, políticas ni funciones. Si el despliegue no tiene las columnas actuales, confirma el esquema antes de plantear una migración.

Prototipo universitario con lectura pública mediante RLS y sin autenticación de usuarios. Las mediciones no son privadas. La app no añade permisos de escritura. Las etiquetas de simulación proceden del campo `simulada`.

Dependencias: `supabase_flutter` fijado a 2.18.3; `fl_chart` y `shared_preferences` resueltos en `pubspec.lock`. Se conserva `material_ui` del proyecto existente, utilizado por Flutter 3.50.

## Validación

```powershell
dart format lib test
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=config.local.json
```

La integración real requiere una publishable key válida configurada localmente. No se incluye ninguna credencial. Android requiere `cmdline-tools`, licencias aceptadas y dispositivo o emulador; una prueba en Chrome no valida Android.

## Archivos de esta implementación

Creados: módulos `lib/app/`, `lib/core/`, `lib/models/`, `lib/services/`, `lib/features/`, `lib/widgets/` y `config.example.json`.
Modificados: `lib/main.dart`, `pubspec.yaml`, `pubspec.lock`, `test/widget_test.dart`, `android/app/src/main/AndroidManifest.xml`, `web/index.html`, `web/manifest.json`, este README y, en la raíz, `.gitignore` y `README.md`.

El panel `../web/`, el firmware, el esquema y la Edge Function se mantienen fuera del alcance de esta implementación.

Validación inicial, anterior al rediseño visual: `flutter pub get`, `dart format lib test`, `flutter analyze` sin incidencias y `flutter test` con 9 pruebas aprobadas. Se ejecutó `flutter run -d chrome` y se confirmó el arranque mediante el servicio de depuración. Las tarjetas, navegación y gráficas se verificaron en pruebas de widgets a 360 y 1000 píxeles con lecturas expresamente simuladas. No se verificó la consulta remota porque no hay publishable key configurada. Android no se ejecutó: faltan cmdline-tools y aceptación de licencias, y no hay dispositivo Android conectado.


## Rediseño visual de ATMOS Mobile

Sistema visual: fondo `#0B1220`, superficies `#152434` y `#192637`, turquesa `#73DDCB`, violeta `#A2A5FF`, texto `#F2F5FB` y texto secundario `#96A7C0`. Espaciado en múltiplos de 8, tarjetas de 24 px, navegación compacta y transiciones de 180–200 ms que respetan la preferencia de reducir animaciones.

Inicio presenta la temperatura como métrica principal, humedad y cantidad de registros en tarjetas secundarias, estado compacto y una gráfica funcional con las últimas 24 lecturas del historial cargado. No se generan datos de ejemplo en la interfaz. Historial conserva períodos, paginación y gráficas independientes con ejes temporales reales; las lecturas simuladas conservan su identificación. Alertas muestra límites actuales, validación y persistencia existentes. Ajustes concentra la fuente de datos y los detalles técnicos.

Archivos modificados durante el rediseño:

- `lib/app/atmos_app.dart`: encabezado, acceso a Ajustes, navegación, carga, errores y transición.
- `lib/widgets/atmos_widgets.dart`: tarjetas, indicadores, secciones, estados vacíos, detalle y registros.
- `lib/features/dashboard/dashboard_page.dart`: nueva jerarquía y actividad reciente.
- `lib/features/history/history_page.dart`: filtros, gráficas y registros.
- `lib/features/alerts/alerts_page.dart`: límites, formulario y avisos.
- `lib/features/settings/settings_page.dart`: dispositivo, sincronización e información técnica.
- `test/widget_test.dart`: cobertura responsive, texto ampliado, carga y guardado de umbrales.
- `README.md`: documentación del rediseño.

Archivos creados: `lib/app/atmos_theme.dart` y `lib/widgets/environmental_chart.dart`. No se agregaron dependencias. Controlador, modelos, servicios, arranque, configuración privada, firmware, ATMOS Web, esquema y Edge Function conservaron sus huellas SHA-256.

Validación del rediseño: `dart format lib test` sin cambios pendientes, `flutter analyze` sin incidencias y `flutter test` con **21 pruebas aprobadas**. Cobertura de anchos 320, 360, 390, 412, 1000 y 1200 px; texto ampliado a 1.8, identificador de 64 caracteres, lecturas simuladas de prueba, estados vacíos/carga y persistencia. Los colores de texto sobre superficies sólidas obtuvieron relaciones de contraste de al menos 6.25:1; esto no sustituye una auditoría completa con lectores de pantalla.

Se ejecutó `flutter run -d chrome --dart-define-from-file=config.local.json` en Chrome sin ventana visible para capturar y comparar las cuatro pantallas a 390 × 844 px y el Inicio a 1200 × 900 px. Se verificó una consulta REST de solo lectura con la clave pública local y se observaron mediciones consultadas en las tarjetas y gráficas. Las capturas locales están en `build/design-review/` (carpeta ignorada por Git). Android no se ejecutó en dispositivo o emulador.
