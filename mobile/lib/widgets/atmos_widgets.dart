import 'package:material_ui/material_ui.dart';

import '../models/lectura_ambiental.dart';
import '../app/atmos_theme.dart';
export '../app/atmos_theme.dart'
    show
        mint,
        blue,
        background,
        surface,
        elevatedSurface,
        ink,
        muted,
        outline,
        warningColor;

String localDate(DateTime? date) {
  if (date == null) return 'Sin registros';
  final d = date.toLocal();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
}

String localTime(DateTime date) {
  final d = date.toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: padding,
    decoration: BoxDecoration(
      color: surface,
      gradient: accent == null
          ? null
          : LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [accent!.withValues(alpha: 0.10), surface],
            ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color:
            accent?.withValues(alpha: 0.24) ?? outline.withValues(alpha: 0.65),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.subtitle,
    this.icon,
    this.color = mint,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = mint, this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 14, color: color)
        else
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class DetailLine extends StatelessWidget {
  const DetailLine(this.label, this.value, {super.key, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LayoutBuilder(
      builder: (context, box) {
        final labelWidget = Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        );
        final valueWidget = Text(
          value,
          style: TextStyle(color: color ?? ink, fontSize: 13, height: 1.5),
        );
        if (box.maxWidth < 400 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 4), valueWidget],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 16),
            Expanded(child: valueWidget),
          ],
        );
      },
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.description, {
    super.key,
    this.icon = Icons.sensors_off_outlined,
  });
  final String title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: muted, size: 28),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(description),
      ],
    ),
  );
}

class ReadingTile extends StatelessWidget {
  const ReadingTile(this.reading, {super.key, this.alert = false});
  final LecturaAmbiental reading;
  final bool alert;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: outline)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localDate(reading.creadoEn),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: ink,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${reading.temperatura.toStringAsFixed(1)} °C',
              style: const TextStyle(color: mint, fontWeight: FontWeight.w600),
            ),
            Text(
              '${reading.humedad.toStringAsFixed(1)} %',
              style: const TextStyle(color: blue, fontWeight: FontWeight.w600),
            ),
            StatusPill(
              reading.simulada ? 'Simulada' : 'Real',
              color: reading.simulada ? muted : mint,
              icon: reading.simulada ? Icons.science_outlined : Icons.sensors,
            ),
            if (alert)
              const StatusPill(
                'Fuera de rango',
                color: warningColor,
                icon: Icons.warning_amber_rounded,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          reading.dispositivoId,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
