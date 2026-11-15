class AlertThresholds {
  const AlertThresholds({
    this.minTemp = 15,
    this.maxTemp = 30,
    this.minHumidity = 30,
    this.maxHumidity = 70,
  });
  final double minTemp, maxTemp, minHumidity, maxHumidity;
  bool get valid =>
      [minTemp, maxTemp, minHumidity, maxHumidity].every((v) => v.isFinite) &&
      minTemp < maxTemp &&
      minHumidity < maxHumidity &&
      minHumidity >= 0 &&
      maxHumidity <= 100;
  bool outside(double temp, double humidity) =>
      temp < minTemp ||
      temp > maxTemp ||
      humidity < minHumidity ||
      humidity > maxHumidity;
  Map<String, dynamic> toJson() => {
    'minTemp': minTemp,
    'maxTemp': maxTemp,
    'minHumidity': minHumidity,
    'maxHumidity': maxHumidity,
  };
  factory AlertThresholds.fromJson(Map<String, dynamic> json) =>
      AlertThresholds(
        minTemp: (json['minTemp'] as num).toDouble(),
        maxTemp: (json['maxTemp'] as num).toDouble(),
        minHumidity: (json['minHumidity'] as num).toDouble(),
        maxHumidity: (json['maxHumidity'] as num).toDouble(),
      );
}
