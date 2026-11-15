import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/preferences_store.dart';
import 'package:mobile/app/atmos_app.dart';
import 'package:mobile/core/monitor_controller.dart';
import 'package:mobile/models/lectura_ambiental.dart';
import 'package:mobile/models/alert_thresholds.dart';
import 'package:mobile/services/readings_service.dart';
import 'package:mobile/features/history/history_page.dart';
import 'package:mobile/features/dashboard/dashboard_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/app/atmos_theme.dart';
import 'package:mobile/features/alerts/alerts_page.dart';
import 'package:mobile/features/settings/settings_page.dart';

Map<String, dynamic> sample() => {
  'id': 1,
  'dispositivo_id': 'esp32-01',
  'temperatura': '24.5',
  'humedad': 55,
  'simulada': true,
  'creado_en': '2026-11-14T12:00:00Z',
};

class FakeService implements ReadingsService {
  final gate = Completer<List<LecturaAmbiental>>();
  int calls = 0;
  @override
  Future<List<LecturaAmbiental>> latest(String device) {
    calls++;
    return gate.future;
  }

  @override
  Future<List<LecturaAmbiental>> history(
    String device,
    Duration period,
    int offset,
  ) async => [];
}

class MemoryPreferences implements PreferencesStore {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [320.0, 390.0, 412.0, 1200.0]) {
    testWidgets(
      'Todas las pantallas con texto grande y dispositivo largo a $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final prefs = MemoryPreferences();
        final longId = List.filled(8, 'esp32lab').join();
        await prefs.setString('device', longId);
        final c = MonitorController(null, prefs);
        c.latest = LecturaAmbiental.fromJson(
          sample()..['dispositivo_id'] = longId,
        );
        c.rows = [c.latest!];
        await tester.pumpWidget(AtmosApp(controller: c));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final tab in ['Historial', 'Alertas', 'Ajustes', 'Inicio']) {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(tab),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$tab a $width con texto grande',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'La carga conserva una indicación accesible y termina sin error',
    (tester) async {
      final service = FakeService();
      final c = MonitorController(service, MemoryPreferences());
      await tester.pumpWidget(AtmosApp(controller: c));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      service.gate.complete([]);
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Sin mediciones'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('El formulario de alertas valida y conserva el guardado local', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    final c = MonitorController(null, prefs);
    await tester.pumpWidget(
      MaterialApp(
        theme: atmosTheme(),
        home: Scaffold(body: SingleChildScrollView(child: AlertsPage(c))),
      ),
    );
    final inputs = find.byType(TextFormField);
    await tester.enterText(inputs.at(1), '10');
    await tester.ensureVisible(find.text('Guardar límites'));
    await tester.tap(find.text('Guardar límites'));
    await tester.pumpAndSettle();
    expect(find.text('El máximo debe superar al mínimo'), findsOneWidget);
    await tester.enterText(inputs.at(1), '35');
    await tester.ensureVisible(find.text('Guardar límites'));
    await tester.tap(find.text('Guardar límites'));
    await tester.pumpAndSettle();
    expect(c.thresholds.maxTemp, 35);
    expect(prefs.values['thresholds'], contains('35'));
    await tester.pumpWidget(
      MaterialApp(
        theme: atmosTheme(),
        home: Scaffold(body: SingleChildScrollView(child: SettingsPage(c))),
      ),
    );
    expect(find.text('15.0 a 35.0 °C'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
  test('Guarda y recupera preferencias locales', () async {
    final prefs = MemoryPreferences();
    final first = MonitorController(null, prefs);
    expect(
      await first.saveSettings('esp32-lab', const AlertThresholds(maxTemp: 35)),
      isTrue,
    );
    first.dispose();
    final restored = MonitorController(null, prefs);
    await restored.start();
    expect(restored.device, 'esp32-lab');
    expect(restored.thresholds.maxTemp, 35);
    restored.dispose();
  });
  for (final width in [320.0, 360.0, 390.0, 412.0, 1000.0]) {
    testWidgets('Tarjetas y gráficas con lecturas simuladas a ancho $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = MonitorController(null, MemoryPreferences());
      final a = LecturaAmbiental.fromJson(sample());
      final b = LecturaAmbiental.fromJson(
        sample()
          ..['id'] = 2
          ..['creado_en'] = '2026-11-14T12:01:00Z'
          ..['temperatura'] = 27,
      );
      c.latest = b;
      c.rows = [b, a];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: DashboardPage(c))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('27.0 °C'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HistoryPage(c))),
        ),
      );
      await tester.pumpAndSettle();
      final charts = tester
          .widgetList<LineChart>(find.byType(LineChart))
          .toList();
      expect(charts.length, 2);
      expect(charts.first.data.lineBarsData.first.spots.first.y, 24.5);
      expect(charts.first.data.lineBarsData.first.spots.last.x, 60);
      expect(charts.last.data.maxY, 100);
      expect(find.text('Simulada'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  }
  test('Decodifica numeric y UTC; rechaza datos incompletos', () {
    final r = LecturaAmbiental.fromJson(sample());
    expect(r.temperatura, 24.5);
    expect(r.simulada, isTrue);
    expect(r.creadoEn.isUtc, isTrue);
    expect(
      () => LecturaAmbiental.fromJson(sample()..['temperatura'] = null),
      throwsFormatException,
    );
    expect(
      () => LecturaAmbiental.fromJson(sample()..['simulada'] = null),
      throwsFormatException,
    );
  });
  test('Frescura depende de la medición; rechaza fechas futuras', () {
    final r = LecturaAmbiental.fromJson(sample());
    expect(r.isFresh(r.creadoEn.add(const Duration(seconds: 60))), isTrue);
    expect(r.isFresh(r.creadoEn.add(const Duration(seconds: 61))), isFalse);
    expect(r.isFresh(r.creadoEn.subtract(const Duration(seconds: 1))), isFalse);
  });
  test('Umbrales validan orden, humedad y límites inclusivos', () {
    const t = AlertThresholds();
    expect(t.valid, isTrue);
    expect(t.outside(15, 70), isFalse);
    expect(t.outside(31, 50), isTrue);
    expect(const AlertThresholds(minTemp: 40).valid, isFalse);
    expect(const AlertThresholds(maxHumidity: 101).valid, isFalse);
    expect(AlertThresholds.fromJson(t.toJson()).maxTemp, 30);
  });
  test(
    'Evita consultas simultáneas y tolera dispose durante una consulta',
    () async {
      final service = FakeService();
      final c = MonitorController(service, MemoryPreferences());
      final pending = c.refresh();
      await c.refresh();
      expect(service.calls, 1);
      c.dispose();
      service.gate.complete([]);
      await pending;
    },
  );
  for (final width in [320.0, 360.0, 390.0, 412.0, 1000.0]) {
    testWidgets('Navegación sin configuración y sin overflow a ancho $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = MonitorController(
        null,
        MemoryPreferences(),
        startupError: 'Falta configuración',
      );
      await tester.pumpWidget(AtmosApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('ATMOS'), findsOneWidget);
      for (final tab in ['Historial', 'Alertas', 'Ajustes', 'Inicio']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
