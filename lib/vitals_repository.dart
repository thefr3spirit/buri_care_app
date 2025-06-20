//type: application/vnd.ant.code
//language: dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vitals_generator.dart';

class VitalsRepository {
  // Singleton pattern
  static final VitalsRepository _instance = VitalsRepository._internal();
  factory VitalsRepository() => _instance;
  VitalsRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VitalsGenerator _vitalsGenerator = VitalsGenerator();
  
  // Get the current user's ID or return null if not logged in
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Ensure we have a valid user ID for operations
  String _getUserId() {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('No authenticated user found. Please log in again.');
    }
    return uid;
  }
  
  // Data caches
  final List<double> _heartRateCache = [];
  final List<double> _temperatureCache = [];
  final List<double> _spo2Cache = [];
  
  // Last hour identifier to track when the hour changes
  String _currentHourId = '';
  
  // Stream controllers for real-time data
  final _heartRateController = StreamController<double>.broadcast();
  final _temperatureController = StreamController<double>.broadcast();
  final _spo2Controller = StreamController<double>.broadcast();
  
  // Getters for streams
  Stream<double> get heartRateStream => _heartRateController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<double> get spo2Stream => _spo2Controller.stream;
  
  // Timers
  Timer? _minuteTimer;
  Timer? _midnightTimer;
  
  // Initialize the repository
  void initialize() {
    // Setup subscriptions to generator streams
    _vitalsGenerator.heartRateStream.listen((value) {
      _heartRateCache.add(value);
      _heartRateController.add(value);
    });
    
    _vitalsGenerator.temperatureStream.listen((value) {
      _temperatureCache.add(value);
      _temperatureController.add(value);
    });
    
    _vitalsGenerator.spo2Stream.listen((value) {
      _spo2Cache.add(value);
      _spo2Controller.add(value);
    });
    
    // Start generating data
    _vitalsGenerator.startGenerating();
    
    // Set the current hour ID
    _currentHourId = _getHourIdentifier(DateTime.now());
    
    // Setup timers for data processing
    _setupTimers();
  }
  
  // Set up timers for processing data at different intervals
  void _setupTimers() {
    // Process data every minute
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _processMinuteData();
    });
    
    // Setup a timer for midnight processing
    _setupMidnightTimer();
  }
  
  // Setup a timer that triggers at midnight
  void _setupMidnightTimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);
    
    _midnightTimer = Timer(timeUntilMidnight, () {
      _processDayData();
      
      // Setup the next midnight timer
      _setupMidnightTimer();
    });
  }
  
  // Get hour identifier (YYYY-MM-DD-HH format)
  String _getHourIdentifier(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}-${dateTime.hour.toString().padLeft(2, '0')}';
  }
  
  // Get day identifier (YYYY-MM-DD format)
  String _getDayIdentifier(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
  
  // Process and store minute data
  void _processMinuteData() {
    if (_heartRateCache.isEmpty || _temperatureCache.isEmpty || _spo2Cache.isEmpty) {
      return;
    }
    
    // Check if user is logged in before proceeding
    try {
      // This will throw if no user is logged in
      final userId = _getUserId();
      
      final now = DateTime.now();
      
      // Calculate minute averages
      final avgHeartRate = _calculateAverage(_heartRateCache);
      final avgTemperature = _calculateAverage(_temperatureCache);
      final avgSpo2 = _calculateAverage(_spo2Cache);
      
      // Store minute data in Firestore
      _storeMinuteData(avgHeartRate, avgTemperature, avgSpo2);
      
      // Check if hour has changed
      final currentHourId = _getHourIdentifier(now);
      if (currentHourId != _currentHourId) {
        _currentHourId = currentHourId;
      }
      
      // Update hourly aggregates with the latest minute data
      _updateHourlyData();
      
      // Clear caches for next minute
      _heartRateCache.clear();
      _temperatureCache.clear();
      _spo2Cache.clear();
    } catch (e) {
      print('Error processing minute data: $e');
      // Don't clear caches if storing failed, so we can try again
    }
  }
  
  // Update hourly data based on minute data
  Future<void> _updateHourlyData() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    
    // Get all minute data for the current hour
    final heartRateSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('minHeartRate')
        .where('timestamp', isGreaterThanOrEqualTo: hourStart)
        .where('timestamp', isLessThanOrEqualTo: now)
        .get();
    
    final temperatureSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('minTemperature')
        .where('timestamp', isGreaterThanOrEqualTo: hourStart)
        .where('timestamp', isLessThanOrEqualTo: now)
        .get();
    
    final spo2Snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('minSpo2')
        .where('timestamp', isGreaterThanOrEqualTo: hourStart)
        .where('timestamp', isLessThanOrEqualTo: now)
        .get();
    
    // Calculate averages if we have data
    if (heartRateSnapshot.docs.isNotEmpty) {
      final List<double> heartRates = heartRateSnapshot.docs
          .map((doc) => doc.data()['value'] as double)
          .toList();
      final avgHeartRate = _calculateAverage(heartRates);
      
      // Store updated hour heart rate
      await _storeHourData('hourHeartRate', hourStart, avgHeartRate);
    }
    
    if (temperatureSnapshot.docs.isNotEmpty) {
      final List<double> temperatures = temperatureSnapshot.docs
          .map((doc) => doc.data()['value'] as double)
          .toList();
      final avgTemperature = _calculateAverage(temperatures);
      
      // Store updated hour temperature
      await _storeHourData('hourTemperature', hourStart, avgTemperature);
    }
    
    if (spo2Snapshot.docs.isNotEmpty) {
      final List<double> spo2s = spo2Snapshot.docs
          .map((doc) => doc.data()['value'] as double)
          .toList();
      final avgSpo2 = _calculateAverage(spo2s);
      
      // Store updated hour SpO2
      await _storeHourData('hourSpo2', hourStart, avgSpo2);
    }
  }
  
  // Process and store daily data at midnight
  void _processDayData() async {
    try {
      // Check if user is logged in
      _getUserId();
      
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      
      // Calculate and store the daily aggregates
      await _updateDailyData(yesterday);
    } catch (e) {
      print('Error processing day data: $e');
    }
  }
  
  // Update daily data based on hourly data
  Future<void> _updateDailyData(DateTime day) async {
    final userId = _getUserId();
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
    
    // Get all hourly data for the specified day
    final heartRateSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('hourHeartRate')
        .where('timestamp', isGreaterThanOrEqualTo: dayStart)
        .where('timestamp', isLessThanOrEqualTo: dayEnd)
        .get();
    
    final temperatureSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('hourTemperature')
        .where('timestamp', isGreaterThanOrEqualTo: dayStart)
        .where('timestamp', isLessThanOrEqualTo: dayEnd)
        .get();
    
    final spo2Snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('hourSpo2')
        .where('timestamp', isGreaterThanOrEqualTo: dayStart)
        .where('timestamp', isLessThanOrEqualTo: dayEnd)
        .get();
    
    // Calculate averages if we have data
    if (heartRateSnapshot.docs.isNotEmpty) {
      final List<double> heartRates = heartRateSnapshot.docs
          .map((doc) => doc.data()['value'] as double)
          .toList();
      final avgHeartRate = _calculateAverage(heartRates);
      
      // Store day heart rate
      await _storeDayData('dayHeartRate', dayStart, avgHeartRate);
    }
    
    if (temperatureSnapshot.docs.isNotEmpty) {
      final List<double> temperatures = temperatureSnapshot.docs
          .map((doc) => doc.data()['value'] as double)
          .toList();
      final avgTemperature = _calculateAverage(temperatures);
      
      // Store day temperature
      await _storeDayData('dayTemperature', dayStart, avgTemperature);
    }
    
    if (spo2Snapshot.docs.isNotEmpty) {
      final List<double> spo2s = spo2Snapshot.docs
          .map((doc) => doc.data()['value'] as double)
          .toList();
      final avgSpo2 = _calculateAverage(spo2s);
      
      // Store day SpO2
      await _storeDayData('daySpo2', dayStart, avgSpo2);
    }
  }
  
  // Helper method to calculate average
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  // Store minute data in Firestore
  Future<void> _storeMinuteData(double heartRate, double temperature, double spo2) async {
    final userId = _getUserId();
    final timestamp = DateTime.now();
    final minuteId = timestamp.toIso8601String();
    
    // Store heart rate
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('minHeartRate')
        .doc(minuteId)
        .set({
          'value': heartRate,
          'timestamp': timestamp,
        });
    
    // Store temperature
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('minTemperature')
        .doc(minuteId)
        .set({
          'value': temperature,
          'timestamp': timestamp,
        });
    
    // Store SpO2
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('minSpo2')
        .doc(minuteId)
        .set({
          'value': spo2,
          'timestamp': timestamp,
        });
  }
  
  // Store hour data in Firestore
  Future<void> _storeHourData(String collection, DateTime timestamp, double value) async {
    final userId = _getUserId();
    final hourId = timestamp.toIso8601String();
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(hourId)
        .set({
          'value': value,
          'timestamp': timestamp,
        });
  }
  
  // Store day data in Firestore
  Future<void> _storeDayData(String collection, DateTime timestamp, double value) async {
    final userId = _getUserId();
    final dayId = timestamp.toIso8601String();
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(dayId)
        .set({
          'value': value,
          'timestamp': timestamp,
        });
  }
  
  // Dispose resources
  void dispose() {
    _minuteTimer?.cancel();
    _midnightTimer?.cancel();
    _heartRateController.close();
    _temperatureController.close();
    _spo2Controller.close();
    _vitalsGenerator.dispose();
  }
}