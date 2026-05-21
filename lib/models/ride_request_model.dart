import 'package:cloud_firestore/cloud_firestore.dart';

enum RideRequestStatus { pending, accepted, declined, cancelled }

class RideRequestModel {
	const RideRequestModel({
		required this.requestId,
		required this.rideId,
		required this.driverId,
		required this.passengerId,
		required this.status,
		this.createdAt,
		this.updatedAt,
	});

	final String requestId;
	final String rideId;
	final String driverId;
	final String passengerId;
	final RideRequestStatus status;
	final Timestamp? createdAt;
	final Timestamp? updatedAt;

	static RideRequestStatus _statusFromString(String value) {
		switch (value.trim().toLowerCase()) {
			case 'accepted':
				return RideRequestStatus.accepted;
			case 'declined':
				return RideRequestStatus.declined;
			case 'cancelled':
				return RideRequestStatus.cancelled;
			case 'pending':
			default:
				return RideRequestStatus.pending;
		}
	}

	factory RideRequestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
		final data = doc.data() ?? <String, dynamic>{};
		return RideRequestModel(
			requestId: doc.id,
			rideId: (data['rideId'] as String? ?? '').trim(),
			driverId: (data['driverId'] as String? ?? '').trim(),
			passengerId: (data['passengerId'] as String? ?? '').trim(),
			status: _statusFromString((data['status'] as String? ?? 'pending')),
			createdAt: data['createdAt'] as Timestamp?,
			updatedAt: data['updatedAt'] as Timestamp?,
		);
	}
}


