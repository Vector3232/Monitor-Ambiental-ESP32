import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lectura_ambiental.dart';

abstract class ReadingsService {
  Future<List<LecturaAmbiental>> latest(String device);
  Future<List<LecturaAmbiental>> history(
    String device,
    Duration period,
    int offset,
  );
}

class SupabaseReadingsService implements ReadingsService {
  SupabaseReadingsService(this.client);
  final SupabaseClient client;
  static const columns =
      'id,dispositivo_id,temperatura,humedad,simulada,creado_en';
  @override
  Future<List<LecturaAmbiental>> latest(String device) async {
    final rows = await client
        .from('lecturas_ambientales')
        .select(columns)
        .eq('dispositivo_id', device)
        .order('creado_en', ascending: false)
        .order('id', ascending: false)
        .limit(1)
        .timeout(const Duration(seconds: 12));
    return rows.map(LecturaAmbiental.fromJson).toList();
  }

  @override
  Future<List<LecturaAmbiental>> history(
    String device,
    Duration period,
    int offset,
  ) async {
    final rows = await client
        .from('lecturas_ambientales')
        .select(columns)
        .eq('dispositivo_id', device)
        .gte(
          'creado_en',
          DateTime.now().toUtc().subtract(period).toIso8601String(),
        )
        .order('creado_en', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 199)
        .timeout(const Duration(seconds: 12));
    return rows.map(LecturaAmbiental.fromJson).toList();
  }
}
