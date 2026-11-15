class LecturaAmbiental {
  const LecturaAmbiental({
    required this.id,
    required this.dispositivoId,
    required this.temperatura,
    required this.humedad,
    required this.simulada,
    required this.creadoEn,
  });
  final int id;
  final String dispositivoId;
  final double temperatura, humedad;
  final bool simulada;
  final DateTime creadoEn;
  factory LecturaAmbiental.fromJson(Map<String, dynamic> json) {
    double number(String field) {
      final value = double.tryParse('${json[field]}');
      if (value == null || !value.isFinite) {
        throw FormatException('Medición inválida: $field');
      }
      return value;
    }

    final device = json['dispositivo_id'];
    if (device is! String || device.isEmpty || json['simulada'] is! bool) {
      throw const FormatException('Lectura incompleta');
    }
    return LecturaAmbiental(
      id: int.parse('${json['id']}'),
      dispositivoId: device,
      temperatura: number('temperatura'),
      humedad: number('humedad'),
      simulada: json['simulada'] as bool,
      creadoEn: DateTime.parse(json['creado_en'] as String).toUtc(),
    );
  }
  bool isFresh(DateTime now) {
    final age = now.toUtc().difference(creadoEn);
    return !age.isNegative && age <= const Duration(seconds: 60);
  }
}
