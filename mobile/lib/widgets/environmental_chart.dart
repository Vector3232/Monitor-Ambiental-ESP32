import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../models/lectura_ambiental.dart';
import 'atmos_widgets.dart';

/// X representa segundos transcurridos; cada magnitud conserva su propia escala.
class EnvironmentalChart extends StatelessWidget {
  const EnvironmentalChart({
    super.key,
    required this.rows,
    this.temperature = true,
    this.compact = false,
  });
  final List<LecturaAmbiental> rows;
  final bool temperature, compact;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final sorted = [...rows]..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    final origin = sorted.first.creadoEn.millisecondsSinceEpoch;
    final unit = temperature ? '°C' : '%';
    final color = temperature ? mint : blue;
    final spots = sorted
        .map(
          (r) => FlSpot(
            (r.creadoEn.millisecondsSinceEpoch - origin) / 1000,
            temperature ? r.temperatura : r.humedad,
          ),
        )
        .toList();
    final low = spots.map((s) => s.y).reduce(math.min);
    final high = spots.map((s) => s.y).reduce(math.max);
    final padding = math.max(1.0, (high - low) * 0.25);
    return Semantics(
      label:
          '${temperature ? "Temperatura" : "Humedad"}: ${sorted.length} mediciones. De ${localDate(sorted.first.creadoEn)} a ${localDate(sorted.last.creadoEn)}. Mínimo ${low.toStringAsFixed(1)}, máximo ${high.toStringAsFixed(1)} $unit. Valores detallados en el historial.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 120 : 192,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.last.x == 0 ? 1 : spots.last.x,
                minY: temperature ? low - padding : 0,
                maxY: temperature ? high + padding : 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: outline.withValues(alpha: 0.7),
                    strokeWidth: 1,
                    dashArray: [4, 6],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) {
                        if (temperature && (v == meta.min || v == meta.max)) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          v.toStringAsFixed(0),
                          style: const TextStyle(color: muted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (items) => items
                        .map(
                          (s) => LineTooltipItem(
                            '${localDate(DateTime.fromMillisecondsSinceEpoch(origin + (s.x * 1000).round(), isUtc: true))}\n${s.y.toStringAsFixed(1)} $unit',
                            const TextStyle(color: ink, fontSize: 11),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 2.5,
                    isCurved: false,
                    dotData: FlDotData(show: sorted.length == 1),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.16),
                          color.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  localTime(sorted.first.creadoEn),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  localTime(sorted.last.creadoEn),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              '${localDate(sorted.first.creadoEn)} → ${localDate(sorted.last.creadoEn)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
