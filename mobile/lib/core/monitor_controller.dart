import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../services/preferences_store.dart';

import '../models/alert_thresholds.dart';
import '../models/lectura_ambiental.dart';
import '../services/readings_service.dart';

class MonitorController extends ChangeNotifier with WidgetsBindingObserver {
  MonitorController(this.service, this.preferences, {this.startupError});
  final ReadingsService? service;
  final PreferencesStore preferences;
  final String? startupError;
  String device = 'esp32-01';
  AlertThresholds thresholds = const AlertThresholds();
  LecturaAmbiental? latest;
  List<LecturaAmbiental> rows = [];
  Duration period = const Duration(hours: 24);
  bool busy = false, more = false, _disposed = false, _started = false;
  String? error, preferenceError;
  DateTime? syncedAt;
  Timer? _timer;
  bool get fresh => latest?.isFresh(DateTime.now()) ?? false;
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      device = await preferences.getString('device') ?? device;
      final saved = await preferences.getString('thresholds');
      if (saved != null) {
        final parsed = AlertThresholds.fromJson(
          jsonDecode(saved) as Map<String, dynamic>,
        );
        if (parsed.valid) thresholds = parsed;
      }
    } catch (_) {
      preferenceError = 'No se pudieron recuperar las preferencias locales.';
    }
    if (_disposed) return;
    _resume();
    await refresh();
  }

  void _resume() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) {
      _resume();
      refresh();
    }
  }

  Future<void> refresh({bool loadMore = false}) async {
    if (busy || _disposed) return;
    if (service == null) {
      error = startupError;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await service!.latest(device);
      final history = await service!.history(
        device,
        period,
        loadMore ? rows.length : 0,
      );
      if (_disposed) return;
      latest = result.isEmpty ? null : result.first;
      rows = loadMore
          ? [...rows, ...history]
                .fold<Map<int, LecturaAmbiental>>(
                  {},
                  (map, r) => map..[r.id] = r,
                )
                .values
                .toList()
          : history;
      more = history.length == 200;
      syncedAt = DateTime.now();
    } catch (_) {
      error = 'No se pudieron consultar las lecturas. Revisa tu conexión, la clave pública y el acceso a la tabla. Los datos anteriores pueden estar desactualizados.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> setPeriod(Duration value) async {
    if (busy) return;
    period = value;
    rows = [];
    more = false;
    await refresh();
  }

  Future<bool> saveSettings(String value, AlertThresholds limits) async {
    if (busy ||
        value.trim().isEmpty ||
        value.trim().length > 64 ||
        !limits.valid) {
      return false;
    }
    try {
      await preferences.setString('device', value.trim());
      await preferences.setString('thresholds', jsonEncode(limits.toJson()));
    } catch (_) {
      preferenceError = 'No se pudieron guardar las preferencias.';
      notifyListeners();
      return false;
    }
    if (_disposed) return false;
    if (device != value.trim()) {
      latest = null;
      rows = [];
      syncedAt = null;
    }
    device = value.trim();
    thresholds = limits;
    preferenceError = null;
    notifyListeners();
    await refresh();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
