import 'package:material_ui/material_ui.dart';

import '../../core/monitor_controller.dart';
import '../../widgets/atmos_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage(this.controller, {super.key});
  final MonitorController controller;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController device;
  final form = GlobalKey<FormState>();
  bool saving = false;
  @override
  void initState() {
    super.initState();
    device = TextEditingController(text: widget.controller.device);
  }

  @override
  void dispose() {
    device.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, t = c.thresholds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Tu dispositivo y tus preferencias.'),
        const SizedBox(height: 24),
        Panel(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Dispositivo',
                  subtitle: 'Usa el identificador que envía tu ESP32.',
                  icon: Icons.memory_rounded,
                ),
                TextFormField(
                  controller: device,
                  maxLength: 64,
                  decoration: const InputDecoration(
                    labelText: 'Identificador del ESP32',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Escribe un identificador'
                      : null,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: saving || c.busy
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          setState(() => saving = true);
                          final ok = await c.saveSettings(
                            device.text,
                            c.thresholds,
                          );
                          if (!context.mounted) return;
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Dispositivo guardado'
                                    : 'No se pudo guardar el dispositivo',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Guardar dispositivo'),
                ),
              ],
            ),
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Fuente de datos',
                subtitle: 'ESP32 → Supabase → ATMOS',
                icon: Icons.cloud_outlined,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    c.busy
                        ? 'Consultando'
                        : c.error != null
                        ? 'Revisar conexión'
                        : c.syncedAt != null
                        ? 'Sincronizado'
                        : 'Pendiente',
                    color: c.error != null ? warningColor : mint,
                  ),
                  StatusPill(
                    c.latest == null
                        ? 'Sin lectura'
                        : c.latest!.simulada
                        ? 'Datos simulados'
                        : 'Datos reales',
                    color: muted,
                    icon: c.latest?.simulada == true
                        ? Icons.science_outlined
                        : Icons.sensors,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DetailLine('Última consulta', localDate(c.syncedAt)),
              DetailLine(
                'Estado del dispositivo',
                c.fresh ? 'Datos recientes' : 'Sin datos recientes',
              ),
              const DetailLine(
                'Actualización automática',
                'Cada 15 segundos en primer plano',
              ),
              const DetailLine(
                'Lectura reciente',
                'Hasta 60 segundos de antigüedad',
              ),
              if (c.error != null) ...[
                const Divider(),
                Text(
                  c.error!,
                  style: const TextStyle(
                    color: warningColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Límites configurados',
                subtitle: 'Edita los valores en Alertas.',
                icon: Icons.tune_rounded,
              ),
              DetailLine(
                'Temperatura',
                '${t.minTemp} a ${t.maxTemp} °C',
                color: mint,
              ),
              DetailLine(
                'Humedad relativa',
                '${t.minHumidity} a ${t.maxHumidity} %',
                color: blue,
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading('Acerca de ATMOS', icon: Icons.air_rounded),
              const DetailLine('Versión', '1.0.0+1'),
              const Text(
                'Monitoreo ambiental con ESP32 y Supabase. Prototipo universitario.',
              ),
              const Divider(),
              Text(
                'ACCESO A LAS MEDICIONES',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: muted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lectura pública mediante RLS, sin autenticación de usuarios. Las mediciones simuladas siempre se identifican.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Las preferencias se guardan únicamente en este dispositivo o navegador. Las alertas funcionan dentro de la aplicación.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
