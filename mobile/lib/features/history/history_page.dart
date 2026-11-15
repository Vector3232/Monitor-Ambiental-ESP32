import 'package:material_ui/material_ui.dart';

import '../../core/monitor_controller.dart';
import '../../widgets/atmos_widgets.dart';
import '../../widgets/environmental_chart.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage(this.controller, {super.key});
  final MonitorController controller;
  @override
  Widget build(BuildContext context) {
    final sorted = [...controller.rows]
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial ambiental',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Explora cómo cambia tu ambiente.'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hours in [1, 24, 168])
              ChoiceChip(
                label: Text(
                  hours == 1
                      ? '1 hora'
                      : hours == 24
                      ? '24 horas'
                      : '7 días',
                ),
                showCheckmark: false,
                selected: controller.period.inHours == hours,
                onSelected: controller.busy
                    ? null
                    : (_) => controller.setPeriod(Duration(hours: hours)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${controller.device} · ${sorted.length} registros',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        if (sorted.isEmpty)
          const EmptyState(
            'Sin mediciones en este período',
            'Prueba otro período o actualiza cuando el dispositivo haya enviado nuevas lecturas.',
            icon: Icons.query_stats_rounded,
          )
        else ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Temperatura',
                  subtitle: 'Grados Celsius · °C',
                  icon: Icons.thermostat_rounded,
                ),
                EnvironmentalChart(rows: sorted),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Humedad relativa',
                  subtitle: 'Porcentaje · %',
                  icon: Icons.water_drop_outlined,
                  color: blue,
                ),
                EnvironmentalChart(rows: sorted, temperature: false),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Mediciones',
                  subtitle: 'Más recientes primero · hora local',
                  icon: Icons.format_list_bulleted_rounded,
                ),
                for (final r in [...sorted].reversed) ReadingTile(r),
              ],
            ),
          ),
        ],
        if (controller.more)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: controller.busy
                  ? null
                  : () => controller.refresh(loadMore: true),
              icon: const Icon(Icons.expand_more),
              label: const Text('Cargar 200 anteriores'),
            ),
          ),
        Text(
          'Las gráficas muestran los registros cargados. Cada actualización recupera los 200 más recientes del período.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
