import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:unh_rideshare_app/models/car_model.dart';

class RideModel {
  final String rideId;
  final String driverId;
  final String vehicleId;
  final String departureDate; // YYYY-MM-DD
  final String departureTime; // HH:mm
  final int totalSeats;
  final int availableSeats;
  final String routeDetails;
  final String status;
  final Timestamp? createdTime;
  final String cancelReason;
  final Timestamp? cancelledAt;
  final List<String> enrolledUserIds;

  final CarModel? vehicle;

  RideModel({
    required this.rideId,
    required this.driverId,
    required this.vehicleId,
    required this.departureDate,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.routeDetails,
    required this.status,
    required this.createdTime,
    this.vehicle,
    this.cancelReason = '',
    this.cancelledAt,
    this.enrolledUserIds = const [],
  });

  RideModel copyWith({
    CarModel? vehicle,
    List<String>? enrolledUserIds,
    String? status, 
    String? cancelReason,
    Timestamp? cancelledAt,
  }) {
    return RideModel(
      rideId: rideId,
      driverId: driverId,
      vehicleId: vehicleId,
      departureDate: departureDate,
      departureTime: departureTime,
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      routeDetails: routeDetails,
      status: status ?? this.status, 
      createdTime: createdTime,
      vehicle: vehicle ?? this.vehicle,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      enrolledUserIds: enrolledUserIds ?? this.enrolledUserIds,
    );
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  factory RideModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Ride doc ${doc.id} has no data');

    final total = _asInt(data['totalSeats']);
    final avail = _asInt(data['availableSeats']);

    return RideModel(
      rideId: doc.id,
      driverId: _asString(data['driverId']),
      vehicleId: _asString(data['vehicleId']),
      departureDate: _asString(data['departureDate']),
      departureTime: _asString(data['departureTime']),
      totalSeats: total,
      availableSeats: avail.clamp(0, total),
      routeDetails: _asString(data['routeDetails']),
      status: _asString(data['status']),
      createdTime: data['createdTime'] as Timestamp?,
      vehicle: null,
      cancelReason: _asString(data['cancelReason']),
      cancelledAt: data['cancelledAt'] as Timestamp?,
      enrolledUserIds: List<String>.from(data['enrolledUserIds'] ?? const []),
    );
  }
}
