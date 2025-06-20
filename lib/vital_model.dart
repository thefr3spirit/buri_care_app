// vital_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';


class VitalReading {
  final double value;
  final DateTime timestamp;

  VitalReading({
    required this.value,
    required this.timestamp,
  });

  // Factory constructor to create a VitalReading from Firestore data
  factory VitalReading.fromFirestore(Map<String, dynamic> data) {
    return VitalReading(
      value: data['value'] as double,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() => 'VitalReading(value: $value, timestamp: $timestamp)';
}

