import 'package:cloud_firestore/cloud_firestore.dart';

class Commentary {
  final String text;
  final DateTime timestamp;
  final double? over; // Added the 'over' field

  Commentary({
    required this.text,
    required this.timestamp,
    this.over, // Initialize the optional 'over' field
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': timestamp,
      'over': over,
    };
  }

  factory Commentary.fromMap(Map<String, dynamic> map) {
    return Commentary(
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      over: map['over']?.toDouble(), // Add this field conversion
    );
  }
}