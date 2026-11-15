import 'package:material_ui/material_ui.dart';

import '../../core/monitor_controller.dart';
import '../../models/alert_thresholds.dart';
import '../../widgets/atmos_widgets.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage(this.controller, {super.key});
  final MonitorController controller;
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final t = widget.controller.thresholds;
    fields = [
      t.minTemp,
      t.maxTemp,
      t.minHumidity,
      t.maxHumidity,
    ].map((v) => TextEditingController(text: '$v')).toList();
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final alerts = c.rows
        .where((r) => c.thresholds.outside(r.temperatura, r.humedad))
        .toList();
    final current = c.latest;
    final t = c.thresholds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Define los límites de tu ambiente. Los avisos se muestran dentro de la aplicación.',
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Límites actuales',
                icon: Icons.shield_outlined,
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
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Configurar umbrales',
                  subtitle: 'Los valores dentro de los límites se consideran normales.',
                  icon: Icons.tune_rounded,
                ),
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: fields[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: [
                          'Temperatura mínima · °C',
                          'Temperatura máxima · °C',
                          'Humedad mínima · %',
                          'Humedad máxima · %',
                        ][i],
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) {
                        final n = double.tryParse(
                          (value ?? '').replaceAll(',', '.'),
                        );
                        if (n == null || !n.isFinite) {
                          return 'Introduce un número válido';
                        }
                        if (i >= 2 && (n < 0 || n > 100)) {
                          return 'Usa un valor entre 0 y 100';
                        }
                        if (i.isOdd) {
                          final min = double.tryParse(
                            fields[i - 1].text.replaceAll(',', '.'),
                          );
                          if (min != null && n <= min) {
                            return 'El máximo debe superar al mínimo';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                FilledButton(
                  onPressed: saving || c.busy
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          setState(() => saving = true);
                          final v = fields
                              .map(
                                (f) =>
                                    double.parse(f.text.replaceAll(',', '.')),
                              )
                              .toList();
                          final ok = await c.saveSettings(
                            c.device,
                            AlertThresholds(
                              minTemp: v[0],
                              maxTemp: v[1],
                              minHumidity: v[2],
                              maxHumidity: v[3],
                            ),
                          );
                          if (!context.mounted) return;
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Umbrales guardados'
                                    : 'No se pudieron guardar los umbrales',
                              ),
                            ),
                          );
                        },
                  child: const Text('Guardar límites'),
                ),
              ],
            ),
          ),
        ),
        if (current != null &&
            c.thresholds.outside(current.temperatura, current.humedad))
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Última lectura fuera de rango',
                  icon: Icons.warning_amber_rounded,
                  color: warningColor,
                ),
                ReadingTile(current, alert: true),
              ],
            ),
          ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                '${alerts.length} avisos',
                subtitle: 'En el historial cargado',
                icon: Icons.notifications_none_rounded,
                color: alerts.isEmpty ? mint : warningColor,
              ),
              if (alerts.isEmpty)
                const Text(
                  'Sin avisos en los registros cargados. Las nuevas mediciones se evaluarán con tus límites guardados.',
                ),
              for (final r in alerts) ReadingTile(r, alert: true),
            ],
          ),
        ),
      ],
    );
  }
}
