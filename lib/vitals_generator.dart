//vitals_generator.dart
import 'dart:async';
import 'dart:math';

class VitalsGenerator {
  // Singleton instance
  static final VitalsGenerator _instance = VitalsGenerator._internal();
  factory VitalsGenerator() => _instance;
  VitalsGenerator._internal();

  // Controllers for each vital sign
  final _heartRateController = StreamController<double>.broadcast();
  final _temperatureController = StreamController<double>.broadcast();
  final _spo2Controller = StreamController<double>.broadcast();

  // Stream getters
  Stream<double> get heartRateStream => _heartRateController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<double> get spo2Stream => _spo2Controller.stream;

  // Normal ranges for vitals
  final _normalHeartRateRange = (120.0, 160.0); // bpm for premature infants
  final _normalTemperatureRange = (36.5, 37.5); // °C
  final _normalSpo2Range = (90.0, 100.0); // percentage

  Timer? _timer;
  bool _isGenerating = false;

  // Start generating data
  void startGenerating() {
    if (_isGenerating) return;
    
    _isGenerating = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _generateVitals();
    });
  }

  // Stop generating data
  void stopGenerating() {
    _timer?.cancel();
    _isGenerating = false;
  }

  // Generate random vital signs within normal ranges with some variation
  void _generateVitals() {
    final random = Random();
    
    // Generate heart rate with small variations
    const baseHeartRate = 140.0; // Middle of normal range
    const heartRateVariation = 20.0; // Possible variation
    final heartRate = baseHeartRate + (random.nextDouble() * 2 - 1) * heartRateVariation;
    
    // Generate temperature with smaller variations
    const baseTemperature = 37.0; // Middle of normal range
    const temperatureVariation = 0.5; // Possible variation
    final temperature = baseTemperature + (random.nextDouble() * 2 - 1) * temperatureVariation;
    
    // Generate SpO2 with small variations, typically high
    const baseSpo2 = 95.0; // Typical value
    const spo2Variation = 5.0; // Possible variation
    final spo2 = baseSpo2 + (random.nextDouble() * 2 - 1) * spo2Variation;
    
    // Add data to streams
    _heartRateController.add(heartRate);
    _temperatureController.add(temperature);
    _spo2Controller.add(spo2);
  }

  // Dispose resources
  void dispose() {
    _timer?.cancel();
    _heartRateController.close();
    _temperatureController.close();
    _spo2Controller.close();
  }
}