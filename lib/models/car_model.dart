import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  final String vehicleId;
  final String make;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String? vehiclePhotoUrl;
  final String? licensePlatePhotoUrl;
  final bool isComplete;
  final int seats;

  CarModel({
    required this.vehicleId,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    this.vehiclePhotoUrl,
    this.licensePlatePhotoUrl,
    required this.isComplete,
    this.seats = 0,
  });

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory CarModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Vehicle doc ${doc.id} has no data');

    return CarModel(
      vehicleId: doc.id,
      make: (data['make'] ?? '') as String,
      model: (data['model'] ?? '') as String,
      year: (data['year'] ?? '') as String,
      color: (data['color'] ?? '') as String,
      licensePlate: (data['licensePlate'] ?? '') as String,
      vehiclePhotoUrl: data['vehiclePhotoUrl'] as String?,
      licensePlatePhotoUrl: data['licensePlatePhotoUrl'] as String?,
      isComplete: (data['isComplete'] as bool?) ?? false,
      seats: _asInt(data['seats']),
    );
  }
}
