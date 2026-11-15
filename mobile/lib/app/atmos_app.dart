import 'package:material_ui/material_ui.dart';

import '../core/monitor_controller.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/history/history_page.dart';
import '../features/alerts/alerts_page.dart';
import '../features/settings/settings_page.dart';
import '../widgets/atmos_widgets.dart';
import 'atmos_theme.dart' show atmosTheme;

class AtmosApp extends StatefulWidget {
  const AtmosApp({super.key, required this.controller});
  final MonitorController controller;
  @override
  State<AtmosApp> createState() => _AtmosAppState();
}

class _AtmosAppState extends State<AtmosApp> {
  int selected = 0;
  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ATMOS Mobile',
    debugShowCheckedModeBanner: false,
    theme: atmosTheme(),
    home: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final pages = [
          DashboardPage(c),
          HistoryPage(c),
          AlertsPage(c),
          SettingsPage(c),
        ];
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 24,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mint.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mint.withValues(alpha: 0.16)),
                  ),
                  child: const Icon(Icons.air_rounded, color: mint, size: 24),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ATMOS',
                        style: TextStyle(
                          fontSize: 18,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        'Monitor ambiental IoT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => selected = 3),
                tooltip: 'Abrir ajustes',
                icon: const Icon(Icons.tune_rounded, color: muted),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                SizedBox(
                  height: 2,
                  child: c.busy
                      ? const LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: background,
                          semanticsLabel: 'Actualizando mediciones',
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: ListView(
                        key: const PageStorageKey('atmos-scroll'),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                        children: [
                          if (c.error != null && selected != 3)
                            _Notice(
                              'No se pudieron actualizar los datos',
                              'Revisa la conexión y la fuente de datos en Ajustes. Las lecturas anteriores pueden estar desactualizadas.',
                              onSettings: () => setState(() => selected = 3),
                            ),
                          if (c.preferenceError != null)
                            _Notice('Preferencias locales', c.preferenceError!),
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            child: KeyedSubtree(
                              key: ValueKey(selected),
                              child: pages[selected],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: outline)),
            ),
            child: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_rounded),
                  label: 'Historial',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_none_rounded),
                  selectedIcon: Icon(Icons.notifications_rounded),
                  label: 'Alertas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.title, this.message, {this.onSettings});
  final String title, message;
  final VoidCallback? onSettings;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: warningColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(message, style: Theme.of(context).textTheme.bodySmall),
        if (onSettings != null)
          TextButton(
            onPressed: onSettings,
            child: const Text('Revisar configuración'),
          ),
      ],
    ),
  );
}
