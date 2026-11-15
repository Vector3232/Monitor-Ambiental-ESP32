import 'package:material_ui/material_ui.dart';

import 'services/preferences_store.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/atmos_app.dart';
import 'core/monitor_controller.dart';
import 'services/readings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  ReadingsService? service;
  String? error;
  if (key.startsWith('sb_publishable_') && key.length > 20) {
    try {
      await Supabase.initialize(
        url: 'https://flxtndpcvwxmpludoehb.supabase.co',
        publishableKey: key,
      );
      service = SupabaseReadingsService(Supabase.instance.client);
    } catch (_) {
      error =
          'No se pudo iniciar Supabase. Revisa la configuración y reinicia.';
    }
  } else {
    error = 'Configura SUPABASE_PUBLISHABLE_KEY con --dart-define-from-file=config.local.json y reinicia.';
  }
  runApp(
    AtmosApp(
      controller: MonitorController(
        service,
        LocalPreferencesStore(),
        startupError: error,
      ),
    ),
  );
}
