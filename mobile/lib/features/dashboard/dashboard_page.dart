import 'package:material_ui/material_ui.dart';

import '../../core/monitor_controller.dart';
import '../../widgets/atmos_widgets.dart';
import '../../widgets/environmental_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage(this.controller, {super.key});
  final MonitorController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller, r = c.latest;
    final warning = r != null && c.thresholds.outside(r.temperatura, r.humedad);
    final recent = ([
      ...c.rows,
    ]..sort((a, b) => b.creadoEn.compareTo(a.creadoEn))).take(24).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi ambiente',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(c.device, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: c.busy ? null : () => c.refresh(),
              tooltip: 'Actualizar mediciones',
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StatusPill(
          r == null
              ? 'Sin mediciones'
              : c.fresh
              ? 'Mediciones recientes'
              : 'Sin datos recientes',
          color: c.fresh ? mint : muted,
        ),
        const SizedBox(height: 24),
        Panel(
          accent: mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Temperatura actual',
                icon: Icons.thermostat_rounded,
              ),
              Semantics(
                label: r == null
                    ? 'Sin temperatura disponible'
                    : 'Temperatura ${r.temperatura.toStringAsFixed(1)} grados Celsius',
                child: Text(
                  r == null ? '— °C' : '${r.temperatura.toStringAsFixed(1)} °C',
                  style: const TextStyle(
                    fontSize: 64,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -3,
                    color: mint,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    r == null
                        ? 'Sin lectura'
                        : r.simulada
                        ? 'Lectura simulada'
                        : 'Lectura real',
                    color: muted,
                    icon: r?.simulada == true
                        ? Icons.science_outlined
                        : Icons.sensors,
                  ),
                  if (warning)
                    const StatusPill(
                      'Fuera de rango',
                      color: warningColor,
                      icon: Icons.warning_amber_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final cards = [
              _SmallMetric(
                title: 'Humedad relativa',
                value: r == null ? '— %' : '${r.humedad.toStringAsFixed(1)} %',
                caption: 'Última medición',
                icon: Icons.water_drop_outlined,
                color: blue,
              ),
              _SmallMetric(
                title: 'Registros',
                value: '${c.rows.length}',
                caption: 'En el historial cargado',
                icon: Icons.stacked_line_chart_rounded,
                color: mint,
              ),
            ];
            final sideBySide =
                box.maxWidth >= 280 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3;
            return sideBySide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[1]),
                    ],
                  )
                : Column(children: cards);
          },
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                'Actividad reciente',
                subtitle: recent.isEmpty
                    ? 'Temperatura · sin registros'
                    : 'Temperatura · últimas ${recent.length} lecturas cargadas',
                icon: Icons.show_chart_rounded,
              ),
              if (recent.isEmpty)
                const Text(
                  'Las mediciones aparecerán aquí cuando estén disponibles.',
                )
              else
                EnvironmentalChart(rows: recent, compact: true),
            ],
          ),
        ),
        if (warning)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'La última medición está fuera de tus límites. Revisa la sección Alertas.',
              style: TextStyle(color: warningColor),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailLine('Última medición', localDate(r?.creadoEn)),
              DetailLine('Última actualización', localDate(c.syncedAt)),
              DetailLine(
                'Sincronización',
                c.busy
                    ? 'Actualizando…'
                    : c.error != null
                    ? 'Requiere atención'
                    : c.syncedAt == null
                    ? 'Pendiente'
                    : 'Consulta correcta',
                color: c.error != null ? warningColor : mint,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });
  final String title, value, caption;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            height: 1.2,
            letterSpacing: -1,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
