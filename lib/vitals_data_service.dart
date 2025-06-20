import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'vital_model.dart';

class VitalsDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
  
  // Get real-time (last minute) data for heart rate
  Stream<List<VitalReading>> getRealTimeHeartRate() {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('minHeartRate')
        .where('timestamp', isGreaterThanOrEqualTo: oneMinuteAgo)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VitalReading.fromFirestore(doc.data());
          }).toList();
        });
  }
  
  // Get real-time (last minute) data for temperature
  Stream<List<VitalReading>> getRealTimeTemperature() {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('minTemperature')
        .where('timestamp', isGreaterThanOrEqualTo: oneMinuteAgo)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VitalReading.fromFirestore(doc.data());
          }).toList();
        });
  }
  
  // Get real-time (last minute) data for SpO2
  Stream<List<VitalReading>> getRealTimeSpo2() {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('minSpo2')
        .where('timestamp', isGreaterThanOrEqualTo: oneMinuteAgo)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return VitalReading.fromFirestore(doc.data());
          }).toList();
        });
  }
  
  // Get last hour data for heart rate with backfill
  Future<List<VitalReading>> getLastHourHeartRate() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('minHeartRate')
        .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary
    return _backfillTimeGaps(readings, oneHourAgo, now, Duration(minutes: 1));
  }
  
  // Get last hour data for temperature with backfill
  Future<List<VitalReading>> getLastHourTemperature() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('minTemperature')
        .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary
    return _backfillTimeGaps(readings, oneHourAgo, now, Duration(minutes: 1));
  }
  
  // Get last hour data for SpO2 with backfill
  Future<List<VitalReading>> getLastHourSpo2() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('minSpo2')
        .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary
    return _backfillTimeGaps(readings, oneHourAgo, now, Duration(minutes: 1));
  }
  
  // Get last day data for heart rate with backfill
  Future<List<VitalReading>> getLastDayHeartRate() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('hourHeartRate')
        .where('timestamp', isGreaterThanOrEqualTo: oneDayAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary
    return _backfillTimeGaps(readings, oneDayAgo, now, Duration(hours: 1));
  }
  
  // Get last day data for temperature with backfill
  Future<List<VitalReading>> getLastDayTemperature() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('hourTemperature')
        .where('timestamp', isGreaterThanOrEqualTo: oneDayAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary
    return _backfillTimeGaps(readings, oneDayAgo, now, Duration(hours: 1));
  }
  
  // Get last day data for SpO2 with backfill
  Future<List<VitalReading>> getLastDaySpo2() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('hourSpo2')
        .where('timestamp', isGreaterThanOrEqualTo: oneDayAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary
    return _backfillTimeGaps(readings, oneDayAgo, now, Duration(hours: 1));
  }
  
  // Get last month data for heart rate with backfill
  Future<List<VitalReading>> getLastMonthHeartRate() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    // Get today's average heart rate for fallback value
    final todayValue = await _getTodayAverageValue('hourHeartRate');
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dayHeartRate')
        .where('timestamp', isGreaterThanOrEqualTo: oneMonthAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary with today's value as fallback
    return _backfillTimeGaps(readings, oneMonthAgo, now, Duration(days: 1), fallbackValue: todayValue);
  }
  
  // Get last month data for temperature with backfill
  Future<List<VitalReading>> getLastMonthTemperature() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    // Get today's average temperature for fallback value
    final todayValue = await _getTodayAverageValue('hourTemperature');
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dayTemperature')
        .where('timestamp', isGreaterThanOrEqualTo: oneMonthAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary with today's value as fallback
    return _backfillTimeGaps(readings, oneMonthAgo, now, Duration(days: 1), fallbackValue: todayValue);
  }
  
  // Get last month data for SpO2 with backfill
  Future<List<VitalReading>> getLastMonthSpo2() async {
    final userId = _getUserId();
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    // Get today's average SpO2 for fallback value
    final todayValue = await _getTodayAverageValue('hourSpo2');
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daySpo2')
        .where('timestamp', isGreaterThanOrEqualTo: oneMonthAgo)
        .orderBy('timestamp')
        .get();
    
    final readings = snapshot.docs.map((doc) {
      return VitalReading.fromFirestore(doc.data());
    }).toList();
    
    // Backfill if necessary with today's value as fallback
    return _backfillTimeGaps(readings, oneMonthAgo, now, Duration(days: 1), fallbackValue: todayValue);
  }
  
  // Helper method to get today's average value for a vital
  Future<double> _getTodayAverageValue(String collection) async {
    final userId = _getUserId();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .where('timestamp', isGreaterThanOrEqualTo: todayStart)
        .get();
    
    if (snapshot.docs.isEmpty) {
      // Default fallback values based on common vital ranges
      if (collection.contains('HeartRate')) {
        return 70.0; // Default average heart rate
      } else if (collection.contains('Temperature')) {
        return 37.0; // Default normal body temperature in Celsius
      } else if (collection.contains('Spo2')) {
        return 97.0; // Default normal SpO2
      }
      return 0.0;
    }
    
    double sum = 0;
    for (var doc in snapshot.docs) {
      sum += doc.data()['value'] as double;
    }
    return sum / snapshot.docs.length;
  }
  
  // Backfill time gaps in readings
  List<VitalReading> _backfillTimeGaps(
    List<VitalReading> readings, 
    DateTime startTime, 
    DateTime endTime, 
    Duration interval,
    {double? fallbackValue}
  ) {
    if (readings.isEmpty) {
      // If no readings and we have a fallback value, use it
      final valueToUse = fallbackValue ?? 0.0;
      return _generateTimeSlots(startTime, endTime, interval)
          .map((time) => VitalReading(value: valueToUse, timestamp: time))
          .toList();
    }
    
    // Sort readings by timestamp
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Generate all expected time slots
    final timeSlots = _generateTimeSlots(startTime, endTime, interval);
    
    // Create a map to easily lookup readings by timestamp
    final readingsMap = <String, VitalReading>{};
    for (final reading in readings) {
      // Round timestamp to nearest interval
      final roundedTime = _roundToNearestInterval(reading.timestamp, interval);
      final key = roundedTime.toIso8601String();
      readingsMap[key] = reading;
    }
    
    // Create final list with backfilled values
    final result = <VitalReading>[];
    
    // Calculate a reasonable fallback value based on available readings
    // If a specific fallback value was provided, use that
    double effectiveFallbackValue;
    if (fallbackValue != null) {
      effectiveFallbackValue = fallbackValue;
    } else if (readings.isNotEmpty) {
      // Otherwise, use average of existing readings as fallback
      double sum = 0;
      for (final reading in readings) {
        sum += reading.value;
      }
      effectiveFallbackValue = sum / readings.length;
    } else {
      effectiveFallbackValue = 0.0;
    }
    
    // Fill in all slots
    for (final slot in timeSlots) {
      final key = slot.toIso8601String();
      if (readingsMap.containsKey(key)) {
        // Use the actual reading
        result.add(readingsMap[key]!);
      } else {
        // Use the fallback value
        result.add(VitalReading(value: effectiveFallbackValue, timestamp: slot));
      }
    }
    
    return result;
  }
  
  // Generate time slots between start and end times with given interval
  List<DateTime> _generateTimeSlots(DateTime startTime, DateTime endTime, Duration interval) {
    final slots = <DateTime>[];
    
    // Round start time to nearest interval
    DateTime current = _roundToNearestInterval(startTime, interval);
    
    while (current.isBefore(endTime) || current.isAtSameMomentAs(endTime)) {
      slots.add(current);
      current = current.add(interval);
    }
    
    return slots;
  }
  
  // Round timestamp to nearest interval
  DateTime _roundToNearestInterval(DateTime time, Duration interval) {
    final milliseconds = interval.inMilliseconds;
    final epochMs = time.millisecondsSinceEpoch;
    final roundedEpochMs = (epochMs ~/ milliseconds) * milliseconds;
    return DateTime.fromMillisecondsSinceEpoch(roundedEpochMs);
  }
}