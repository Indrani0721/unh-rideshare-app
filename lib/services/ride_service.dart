import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_model.dart';
import '../models/ride_request_model.dart';
import '../models/ride_filter_model.dart';
import '../models/car_model.dart';

class RideService {
  RideService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String ridesCollection = 'rides';
  static const String usersCollection = 'users';
  static const String vehiclesSubcollection = 'vehicles';
  static const String requestsSubcollection = 'requests';

  static const String driverIdField = 'driverId';
  static const String userNameField = 'name';
  static const String userProfilePhotoUrlField = 'profilePhotoUrl';
  static const String vehicleIdField = 'vehicleId';
  static const String departureDateField = 'departureDate';
  static const String departureTimeField = 'departureTime';
  static const String totalSeatsField = 'totalSeats';
  static const String availableSeatsField = 'availableSeats';
  static const String routeDetailsField = 'routeDetails';
  static const String statusField = 'status';
  static const String createdTimeField = 'createdTime';
  static const String cancelReasonField = 'cancelReason';
  static const String cancelledAtField = 'cancelledAt';
  static const String activeStatus = 'active';
  static const String cancelledStatus = 'cancelled';
  static const String enrolledUserIdsField = 'enrolledUserIds';
  static const String notificationsSubcollection = 'notifications';
  static const String rideCancelledType = 'ride_cancelled';
  static const String rideRequestCreatedType = 'ride_request_created';
  static const String rideRequestAcceptedType = 'ride_request_accepted';
  static const String rideRequestDeclinedType = 'ride_request_declined';
  static const String rideBookingCancelledType = 'ride_booking_cancelled';

  static const String requestRideIdField = 'rideId';
  static const String requestDriverIdField = 'driverId';
  static const String requestPassengerIdField = 'passengerId';
  static const String requestStatusField = 'status';
  static const String requestCreatedAtField = 'createdAt';
  static const String requestUpdatedAtField = 'updatedAt';
  static const String requestedRideIdsField = 'requestedRideIds';

  static const String requestPendingStatus = 'pending';
  static const String requestAcceptedStatus = 'accepted';
  static const String requestDeclinedStatus = 'declined';
  static const String requestCancelledStatus = 'cancelled';

  static const String vehicleIsCompleteField = 'isComplete';

  String get _currentUid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    return user.uid;
  }
  String getCurrentUserId() {
  return _currentUid;
  }

  CollectionReference<Map<String, dynamic>> _ridesCollectionRef() {
    return _db.collection(ridesCollection);
  }

  CollectionReference<Map<String, dynamic>> _vehiclesCollectionRef(String uid) {
    return _db
        .collection(usersCollection)
        .doc(uid)
        .collection(vehiclesSubcollection);
  }

  CollectionReference<Map<String, dynamic>> _rideRequestsCollectionRef(
    String rideId,
  ) {
    return _ridesCollectionRef().doc(rideId).collection(requestsSubcollection);
  }

  CollectionReference<Map<String, dynamic>> _userRequestsCollectionRef(
    String uid,
  ) {
    return _db
        .collection(usersCollection)
        .doc(uid)
        .collection(requestsSubcollection);
  }


  DocumentReference<Map<String, dynamic>> _requestDocRef({
    required String rideId,
    required String requestId,
  }) {
    return _rideRequestsCollectionRef(rideId).doc(requestId);
  }

  DocumentReference<Map<String, dynamic>> _userRequestDocRef({
    required String passengerId,
    required String rideId,
  }) {
    return _userRequestsCollectionRef(passengerId).doc(rideId);
  }

  Future<String> submitRideRequest(String rideId) async {
    final uid = _currentUid;
    final rideRef = _ridesCollectionRef().doc(rideId);
    final requestRef = _rideRequestsCollectionRef(rideId).doc(uid);
    final userRequestRef = _userRequestsCollectionRef(uid).doc(rideId);
    String driverId = '';
    String routeDetails = '';
    String departureDate = '';
    String departureTime = '';

    await _db.runTransaction((transaction) async {
      final rideSnap = await transaction.get(rideRef);
      if (!rideSnap.exists) throw Exception('Ride not found.');
      final rideData = rideSnap.data() ?? <String, dynamic>{};
      driverId = (rideData[driverIdField] as String? ?? '').trim();
      routeDetails = (rideData[routeDetailsField] as String? ?? '').trim();
      departureDate = (rideData[departureDateField] as String? ?? '').trim();
      departureTime = (rideData[departureTimeField] as String? ?? '').trim();
      if ((rideData[driverIdField] as String? ?? '') == uid) throw Exception('Driver cannot request their own ride.');
      if ((rideData[statusField] as String? ?? '') != activeStatus) throw Exception('Ride is not active.');
      if (((rideData[availableSeatsField] as num?)?.toInt() ?? 0) <= 0) throw Exception('No seats available.');
      final existing = await transaction.get(requestRef);
      if (existing.exists && (existing.data()?[requestStatusField] as String? ?? '') == requestPendingStatus) throw Exception('Pending request already exists.');
      transaction.set(requestRef, {requestRideIdField: rideId, requestDriverIdField: rideData[driverIdField] ?? '', requestPassengerIdField: uid, requestStatusField: requestPendingStatus, requestCreatedAtField: FieldValue.serverTimestamp(), requestUpdatedAtField: FieldValue.serverTimestamp()});
    });

    // Mirror sync is best-effort and should not block request creation.
    try {
      await userRequestRef.set({
        requestRideIdField: rideId,
        requestDriverIdField: driverId,
        requestPassengerIdField: uid,
        requestStatusField: requestPendingStatus,
        requestCreatedAtField: FieldValue.serverTimestamp(),
        requestUpdatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    // Maintain a passenger-owned index of requested ride IDs so passenger list
    // retrieval can avoid blocked collection queries.
    try {
      await _db.collection(usersCollection).doc(uid).set({
        requestedRideIdsField: FieldValue.arrayUnion([rideId]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    if (driverId.isNotEmpty) {
      await _notificationsCollectionRef(driverId).add({
        'type': rideRequestCreatedType,
        'rideId': rideId,
        'title': 'New Ride Request',
        'message': 'A passenger requested a seat for $routeDetails on $departureDate at $departureTime.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        requestPassengerIdField: uid,
      });
    }

    return requestRef.id;
  }

  Future<List<RideRequestModel>> getRideRequestsForCurrentUser() async {
    final uid = _currentUid;
    List<RideRequestModel> mirrored = const <RideRequestModel>[];
    List<RideRequestModel> legacy = const <RideRequestModel>[];

    try {
      final snapshot = await _userRequestsCollectionRef(uid)
          .orderBy(requestCreatedAtField, descending: true)
          .get();
      mirrored = snapshot.docs.map(RideRequestModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        throw Exception('Failed to fetch passenger ride requests: ${e.code}');
      }
    }

    try {
      final legacySnapshot = await _db
          .collectionGroup(requestsSubcollection)
          .where(requestPassengerIdField, isEqualTo: uid)
          .orderBy(requestCreatedAtField, descending: true)
          .get();
      legacy = legacySnapshot.docs.map(RideRequestModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        throw Exception('Failed to fetch passenger ride requests: ${e.code}');
      }
    }

    final directByRideId = await _getRideRequestsForPassengerByRideIds(uid);

    final mergedByRideId = <String, RideRequestModel>{};

    for (final request in legacy) {
      if (request.rideId.isEmpty) continue;
      mergedByRideId[request.rideId] = request;
    }

    for (final request in directByRideId) {
      if (request.rideId.isEmpty) continue;
      mergedByRideId[request.rideId] = request;
    }

    for (final request in mirrored) {
      if (request.rideId.isEmpty) continue;
      final existing = mergedByRideId[request.rideId];
      if (existing == null) {
        mergedByRideId[request.rideId] = request;
        continue;
      }

      final existingUpdated =
          existing.updatedAt?.millisecondsSinceEpoch ??
          existing.createdAt?.millisecondsSinceEpoch ??
          0;
      final incomingUpdated =
          request.updatedAt?.millisecondsSinceEpoch ??
          request.createdAt?.millisecondsSinceEpoch ??
          0;

      if (incomingUpdated >= existingUpdated) {
        mergedByRideId[request.rideId] = request;
      }
    }

    final merged = mergedByRideId.values.toList()
      ..sort((a, b) {
        final aTs =
            a.updatedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final bTs =
            b.updatedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return bTs.compareTo(aTs);
      });

    if (merged.isNotEmpty) {
      return merged;
    }

    // Final fallback: scan rides and read direct request docs for this
    // passenger. This avoids relying on blocked collection queries.
    return _getRideRequestsForPassengerByScanningRides(uid);
  }

  Future<List<RideRequestModel>> _getRideRequestsForPassengerByRideIds(
    String passengerId,
  ) async {
    try {
      final userSnap = await _db.collection(usersCollection).doc(passengerId).get();
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final rideIds = List<String>.from(
        userData[requestedRideIdsField] ?? const <String>[],
      ).where((id) => id.trim().isNotEmpty).toSet();

      if (rideIds.isEmpty) {
        return const <RideRequestModel>[];
      }

      final requestSnaps = await Future.wait(
        rideIds.map((rideId) => _rideRequestsCollectionRef(rideId).doc(passengerId).get()),
      );

      final requests = requestSnaps
          .where((snap) => snap.exists && snap.data() != null)
          .map(RideRequestModel.fromDoc)
          .toList();

      requests.sort((a, b) {
        final aTs =
            a.updatedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final bTs =
            b.updatedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return bTs.compareTo(aTs);
      });

      return requests;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const <RideRequestModel>[];
      }
      throw Exception('Failed to fetch passenger ride requests: ${e.code}');
    }
  }

  Future<List<RideRequestModel>> _getRideRequestsForPassengerByScanningRides(
    String passengerId,
  ) async {
    try {
      final ridesSnapshot = await _ridesCollectionRef().get();
      if (ridesSnapshot.docs.isEmpty) {
        return const <RideRequestModel>[];
      }

      final requestSnaps = await Future.wait(
        ridesSnapshot.docs.map(
          (rideDoc) => _rideRequestsCollectionRef(rideDoc.id)
              .doc(passengerId)
              .get(),
        ),
      );

      final requests = requestSnaps
          .where((snap) => snap.exists && snap.data() != null)
          .map(RideRequestModel.fromDoc)
          .toList();

      requests.sort((a, b) {
        final aTs =
            a.updatedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final bTs =
            b.updatedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return bTs.compareTo(aTs);
      });

      return requests;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const <RideRequestModel>[];
      }
      throw Exception('Failed to fetch passenger ride requests: ${e.code}');
    }
  }

  Future<List<Map<String, dynamic>>> getRideRequestsForCurrentUserWithRideDetails() async {
    try {
      final requests = await getRideRequestsForCurrentUser();
      if (requests.isEmpty) return const <Map<String, dynamic>>[];

      final rideIds = requests
          .map((request) => request.rideId)
          .where((rideId) => rideId.isNotEmpty)
          .toSet();

      final rideSnaps = await Future.wait(
        rideIds.map((rideId) => _ridesCollectionRef().doc(rideId).get()),
      );

      final rideDataById = <String, Map<String, dynamic>>{};
      for (final snap in rideSnaps) {
        final data = snap.data();
        if (snap.exists && data != null) {
          rideDataById[snap.id] = data;
        }
      }

      return requests.map((request) {
        final rideData = rideDataById[request.rideId] ?? const <String, dynamic>{};

        return {
          'requestId': request.requestId,
          requestRideIdField: request.rideId,
          requestDriverIdField: request.driverId,
          requestPassengerIdField: request.passengerId,
          requestStatusField: request.status.name,
          'rideStatus': (rideData[statusField] as String? ?? '').trim(),
          requestCreatedAtField: request.createdAt,
          requestUpdatedAtField: request.updatedAt,
          vehicleIdField: (rideData[vehicleIdField] as String? ?? '').trim(),
          routeDetailsField: (rideData[routeDetailsField] as String? ?? '').trim(),
          departureDateField: (rideData[departureDateField] as String? ?? '').trim(),
          departureTimeField: (rideData[departureTimeField] as String? ?? '').trim(),
          totalSeatsField: (rideData[totalSeatsField] as num?)?.toInt() ?? 0,
          availableSeatsField: (rideData[availableSeatsField] as num?)?.toInt() ?? 0,
          createdTimeField: rideData[createdTimeField] as Timestamp?,
          cancelReasonField: (rideData[cancelReasonField] as String? ?? '').trim(),
          cancelledAtField: rideData[cancelledAtField] as Timestamp?,
          enrolledUserIdsField: List<String>.from(
            rideData[enrolledUserIdsField] ?? const <String>[],
          ),
        };
      }).toList();
    } on FirebaseException catch (e) {
      // If the current user is not permitted to read ride requests (e.g. dev/test
      // environments or security rules), return an empty list instead of
      // propagating the permission error to the UI. This keeps the UI stable
      // while still surfacing other errors.
      if (e.code == 'permission-denied') {
        return const <Map<String, dynamic>>[];
      }
      throw Exception('Failed to fetch passenger ride requests: ${e.code}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String?> getRideRequestStatusForPassenger({
    required String rideId,
    required String passengerId,
  }) async {
    final normalizedRideId = rideId.trim();
    final normalizedPassengerId = passengerId.trim();

    if (normalizedRideId.isEmpty) {
      throw ArgumentError('Ride ID is required.');
    }
    if (normalizedPassengerId.isEmpty) {
      throw ArgumentError('Passenger ID is required.');
    }

    final requestSnap = await _rideRequestsCollectionRef(
      normalizedRideId,
    ).doc(normalizedPassengerId).get();

    if (!requestSnap.exists) {
      return null;
    }

    try {
      await _db.collection(usersCollection).doc(normalizedPassengerId).set({
        requestedRideIdsField: FieldValue.arrayUnion([normalizedRideId]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    return RideRequestModel.fromDoc(requestSnap).status.name;
  }

  Future<String?> getCurrentUserRideRequestStatus(String rideId) async {
    return getRideRequestStatusForPassenger(
      rideId: rideId,
      passengerId: _currentUid,
    );
  }

  Future<void> cancelPendingRequest(String rideId) async {
    final uid = _currentUid;
    final requestRef = _rideRequestsCollectionRef(rideId).doc(uid);
    final userRequestRef = _userRequestDocRef(passengerId: uid, rideId: rideId);
    final userRef = _db.collection(usersCollection).doc(uid);

    await _db.runTransaction((transaction) async {
      final requestSnap = await transaction.get(requestRef);
      if (!requestSnap.exists) throw Exception('Ride request not found.');

      final data = requestSnap.data() ?? <String, dynamic>{};
      if ((data[requestPassengerIdField] as String? ?? '') != uid) {
        throw Exception('You can only cancel your own request.');
      }
      if ((data[requestStatusField] as String? ?? '') != requestPendingStatus) {
        throw Exception('Only pending requests can be cancelled.');
      }

      transaction.delete(requestRef); 
      transaction.delete(userRequestRef);
      transaction.update(userRef, { requestedRideIdsField: FieldValue.arrayRemove([rideId]),
      });
    });
  }

  Future<void> cancelAcceptedBooking(String rideId) async {
    final uid = _currentUid;
    final rideRef = _ridesCollectionRef().doc(rideId);
    final requestRef = _rideRequestsCollectionRef(rideId).doc(uid);
    final userRequestRef = _userRequestDocRef(passengerId: uid, rideId: rideId);

    String driverId = '';
    String departureDate = '';
    String departureTime = '';
    String routeDetails = '';

    await _db.runTransaction((transaction) async {
      final rideSnap = await transaction.get(rideRef);
      if (!rideSnap.exists) {
        throw Exception('Ride not found.');
      }

      final rideData = rideSnap.data();
      if (rideData == null) {
        throw Exception('Ride data not found.');
      }

      final requestSnap = await transaction.get(requestRef);
      if (!requestSnap.exists) {
        throw Exception('Ride request not found.');
      }

      final request = RideRequestModel.fromDoc(requestSnap);

      if (request.rideId != rideId) {
        throw Exception('Ride request does not belong to this ride.');
      }

      if (request.passengerId != uid) {
        throw Exception('You can only cancel your own booking.');
      }

      if (request.status != RideRequestStatus.accepted) {
        throw Exception('Only accepted bookings can be cancelled.');
      }

      final availableSeats =
          (rideData[availableSeatsField] as num?)?.toInt() ?? 0;
      final totalSeats = (rideData[totalSeatsField] as num?)?.toInt() ?? 0;
      final enrolledUserIds = List<String>.from(
        rideData[enrolledUserIdsField] ?? const <String>[],
      );

      if (!enrolledUserIds.contains(uid)) {
        throw Exception('Passenger is not enrolled in this ride.');
      }

      enrolledUserIds.remove(uid);
      final restoredAvailableSeats =
          availableSeats < totalSeats ? availableSeats + 1 : totalSeats;

      driverId = request.driverId;
      departureDate = (rideData[departureDateField] as String? ?? '').trim();
      departureTime = (rideData[departureTimeField] as String? ?? '').trim();
      routeDetails = (rideData[routeDetailsField] as String? ?? '').trim();

      transaction.update(requestRef, {
        requestStatusField: requestCancelledStatus,
        requestUpdatedAtField: FieldValue.serverTimestamp(),
      });

      transaction.update(rideRef, {
        enrolledUserIdsField: enrolledUserIds,
        availableSeatsField: restoredAvailableSeats,
      });
    });

    try {
      await userRequestRef.set({
        requestRideIdField: rideId,
        requestDriverIdField: driverId,
        requestPassengerIdField: uid,
        requestStatusField: requestCancelledStatus,
        requestUpdatedAtField: FieldValue.serverTimestamp(),
        departureDateField: departureDate,
        departureTimeField: departureTime,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    if (driverId.isNotEmpty) {
      final passengerDetails = await _getPassengerDetailsById(uid);
      final passengerName = passengerDetails['passengerName'] ?? '';
      final formattedName = passengerName.isNotEmpty
          ? passengerName[0].toUpperCase() + passengerName.substring(1)
          : 'A passenger';

      await _notificationsCollectionRef(driverId).add({
        'type': rideBookingCancelledType,
        'rideId': rideId,
        'title': 'Booking Cancelled',
        'message':
            '$formattedName cancelled their booking for $routeDetails on $departureDate at $departureTime.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        requestPassengerIdField: uid,
        driverIdField: driverId,
        departureDateField: departureDate,
        departureTimeField: departureTime,
      });
    }
  }

  Future<Map<String, String>> _getPassengerDetailsById(String uid) async {
    final userSnap = await _db.collection(usersCollection).doc(uid).get();
    final data = userSnap.data();

    if (!userSnap.exists || data == null) {
      return {
        'passengerName': '',
        'passengerPhotoUrl': '',
      };
    }

    final name = data[userNameField];
    final profilePhotoUrl = data[userProfilePhotoUrlField];

    return {
      'passengerName': name is String ? name.trim() : '',
      'passengerPhotoUrl': profilePhotoUrl is String ? profilePhotoUrl.trim() : '',
    };
  }

  Future<void> _validateDriverOwnsRide({
    required String rideId,
    required String driverId,
  }) async {
    final rideSnap = await _ridesCollectionRef().doc(rideId).get();

    if (!rideSnap.exists) {
      throw Exception('Ride not found.');
    }

    final rideData = rideSnap.data();
    if (rideData == null) {
      throw Exception('Ride data not found.');
    }

    if (rideData[driverIdField] != driverId) {
      throw Exception('Only the driver can view ride requests for this ride.');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getRideSnapshot(String rideId) async {
    final rideSnap = await _ridesCollectionRef().doc(rideId).get();

    if (!rideSnap.exists) {
      throw Exception('Ride not found.');
    }

    final rideData = rideSnap.data();
    if (rideData == null) {
      throw Exception('Ride data not found.');
    }

    return rideSnap;
  }

  Future<RideModel> getRideById(String rideId) async {
    final rideSnap = await _getRideSnapshot(rideId);
    return RideModel.fromDoc(rideSnap);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getRequestSnapshot({
    required String rideId,
    required String requestId,
  }) async {
    final requestSnap = await _requestDocRef(
      rideId: rideId,
      requestId: requestId,
    ).get();

    if (!requestSnap.exists) {
      throw Exception('Ride request not found.');
    }

    final requestData = requestSnap.data();
    if (requestData == null) {
      throw Exception('Ride request data not found.');
    }

    return requestSnap;
  }

  Future<RideRequestModel> _validateAndGetPendingRideRequest({
    required String rideId,
    required String requestId,
    required String driverId,
  }) async {
    final rideSnap = await _getRideSnapshot(rideId);
    final rideData = rideSnap.data()!;

    if (rideData[driverIdField] != driverId) {
      throw Exception('Only the driver can manage ride requests for this ride.');
    }

    final requestSnap = await _getRequestSnapshot(
      rideId: rideId,
      requestId: requestId,
    );

    final request = RideRequestModel.fromDoc(requestSnap);

    if (request.rideId != rideId) {
      throw Exception('Ride request does not belong to this ride.');
    }

    if (request.driverId != driverId) {
      throw Exception('Ride request does not belong to the current driver.');
    }

    if (request.status != RideRequestStatus.pending) {
      throw Exception('Only pending ride requests can be updated.');
    }

    return request;
  }

  String? validateRideInput({
    required DateTime departureDate,
    required DateTime departureTime,
    required int totalSeats,
  }) {
    if (totalSeats < 1 || totalSeats > 4) {
      return 'Seats must be between 1 and 4.';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(departureDate.year, departureDate.month, departureDate.day);

    if (selectedDate.isBefore(today)) {
      return 'Ride date cannot be in the past.';
    }

    if (selectedDate.isAtSameMomentAs(today)) {
      final selectedDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        departureTime.hour,
        departureTime.minute,
      );

      if (!selectedDateTime.isAfter(now)) {
        return 'Ride time must be in the future.';
      }
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _getRideDepartureDateTime(RideModel ride) {
    final dateParts = ride.departureDate.split('-');
    final timeParts = ride.departureTime.split(':');

    if (dateParts.length != 3 || timeParts.length != 2) {
      throw FormatException('Invalid ride date or time format.');
    }

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  DayOfWeek _getDayOfWeekFromDateTime(DateTime dateTime) {
    switch (dateTime.weekday) {
      case DateTime.monday:
        return DayOfWeek.monday;
      case DateTime.tuesday:
        return DayOfWeek.tuesday;
      case DateTime.wednesday:
        return DayOfWeek.wednesday;
      case DateTime.thursday:
        return DayOfWeek.thursday;
      case DateTime.friday:
        return DayOfWeek.friday;
      case DateTime.saturday:
        return DayOfWeek.saturday;
      case DateTime.sunday:
        return DayOfWeek.sunday;
      default:
        throw StateError('Invalid weekday value.');
    }
  }

  String _getTimeOfDayBucket(DateTime dateTime) {
    final hour = dateTime.hour;

    if (hour >= 00 && hour < 12) {
      return 'Morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    }
    return 'Evening';
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  Future<String> createRideFromModel({
    required RideModel ride,
    required DateTime departureDate,
    required DateTime departureTime,
    String? vehicleId,
  }) async {
    return createRide(
      departureDate: departureDate,
      departureTime: departureTime,
      totalSeats: ride.totalSeats,
      routeDetails: ride.routeDetails,
      vehicleId: vehicleId ?? ride.vehicleId,
    );
  }

  Future<String> _resolveAndValidateVehicleId({String? vehicleId}) async {
    final uid = _currentUid;
    final vehiclesRef = _vehiclesCollectionRef(uid);

    if (vehicleId != null && vehicleId.trim().isNotEmpty) {
      final snap = await vehiclesRef.doc(vehicleId.trim()).get();
      if (!snap.exists) {
        throw Exception('Vehicle details must be completed before posting a ride.');
      }
      final data = snap.data();
      final isComplete = (data?[vehicleIsCompleteField] as bool?) ?? false;
      if (!isComplete) {
        throw Exception('Vehicle details must be completed before posting a ride.');
      }
      return snap.id;
    }

    final completeQuery = await vehiclesRef
        .where(vehicleIsCompleteField, isEqualTo: true)
        .limit(1)
        .get();

    if (completeQuery.docs.isEmpty) {
      throw Exception('Vehicle details must be completed before posting a ride.');
    }

    return completeQuery.docs.first.id;
  }

  Map<String, dynamic> _buildRidePayload({
    required String driverId,
    required String vehicleId,
    required String departureDate,
    required String departureTime,
    required int totalSeats,
    required String routeDetails,
    required String status,
  }) {
    return {
      driverIdField: driverId,
      vehicleIdField: vehicleId,
      departureDateField: departureDate,
      departureTimeField: departureTime,
      totalSeatsField: totalSeats,
      availableSeatsField: totalSeats,
      routeDetailsField: routeDetails,
      statusField: status,
      createdTimeField: FieldValue.serverTimestamp(),
      enrolledUserIdsField: <String>[],
    };
  }
    Future<String> createRide({
    required DateTime departureDate,
    required DateTime departureTime,
    required int totalSeats,
    required String routeDetails,
    String status = activeStatus,
    String? vehicleId,
  }) async {
    final error = validateRideInput(
      departureDate: departureDate,
      departureTime: departureTime,
      totalSeats: totalSeats,
    );
    if (error != null) throw ArgumentError(error);

    final driverId = _currentUid;

    try {
      final resolvedVehicleId =
          await _resolveAndValidateVehicleId(vehicleId: vehicleId);

      final payload = _buildRidePayload(
        driverId: driverId,
        vehicleId: resolvedVehicleId,
        departureDate: _formatDate(departureDate),
        departureTime: _formatTime(departureTime),
        totalSeats: totalSeats,
        routeDetails: routeDetails.trim(),
        status: status.trim(),
      );

      final newRideRef = _ridesCollectionRef().doc();
      await newRideRef.set(payload);
      return newRideRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to create ride: ${e.code}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  Future<List<RideModel>> getRidesForCurrentUser() async {
    final driverId = _currentUid;

    try {
      final snapshot = await _ridesCollectionRef()
          .where(driverIdField, isEqualTo: driverId)
          .orderBy(departureDateField, descending: false)
          .orderBy(departureTimeField, descending: false)
          .get();

      return snapshot.docs.map(RideModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const <RideModel>[];
      }
      throw Exception('Failed to fetch rides: ${e.code}');
    } catch (_) {
      throw Exception('Failed to fetch rides.');
    }
  }

  Future<List<RideRequestModel>> getRequestsForRide(String rideId) async {
    final uid = _currentUid;

    try {
      await _validateDriverOwnsRide(rideId: rideId, driverId: uid);

      final snapshot = await _rideRequestsCollectionRef(rideId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(RideRequestModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch ride requests: ${e.code}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getRequestsForRideWithPassengerDetails(
    String rideId,
  ) async {
    final requests = await getRequestsForRide(rideId);

    final enrichedRequests = await Future.wait(
      requests.map((request) async {
        final passengerDetails = await _getPassengerDetailsById(request.passengerId);

        return {
          'requestId': request.requestId,
          'rideId': request.rideId,
          'driverId': request.driverId,
          'passengerId': request.passengerId,
          'passengerName': passengerDetails['passengerName'] ?? '',
          'passengerPhotoUrl': passengerDetails['passengerPhotoUrl'] ?? '',
          'status': request.status.name,
          'createdAt': request.createdAt,
          'updatedAt': request.updatedAt,
        };
      }),
    );

    return enrichedRequests;
  }

  Future<int> getPendingRequestCountForRide(String rideId) async {
    final uid = _currentUid;

    try {
      await _validateDriverOwnsRide(rideId: rideId, driverId: uid);

      final snapshot = await _rideRequestsCollectionRef(rideId)
          .where(requestStatusField, isEqualTo: RideRequestStatus.pending.name)
          .get();

      return snapshot.docs.length;
    } on FirebaseException catch (e) {
      throw Exception('Failed to count pending ride requests: ${e.code}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  Future<void> declineRideRequest({
    required String rideId,
    required String requestId,
  }) async {
    final driverId = _currentUid;

    try {
      final request = await _validateAndGetPendingRideRequest(
        rideId: rideId,
        requestId: requestId,
        driverId: driverId,
      );
      final rideSnap = await _getRideSnapshot(rideId);
      final rideData = rideSnap.data()!;
      final routeDetails = (rideData[routeDetailsField] as String? ?? '').trim();
      final departureDate =
          (rideData[departureDateField] as String? ?? '').trim();
      final departureTime =
          (rideData[departureTimeField] as String? ?? '').trim();
      await _requestDocRef(
        rideId: rideId,
        requestId: requestId,
      ).update({
        requestStatusField: RideRequestStatus.declined.name,
        requestUpdatedAtField: FieldValue.serverTimestamp(),
      });
      try {
        await _userRequestDocRef(
          passengerId: request.passengerId,
          rideId: rideId,
        ).set({
          requestRideIdField: rideId,
          requestDriverIdField: driverId,
          requestPassengerIdField: request.passengerId,
          requestStatusField: RideRequestStatus.declined.name,
          requestUpdatedAtField: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
      await _createRideRequestStatusNotification(
      passengerId: request.passengerId,
      rideId: rideId,
      type: rideRequestDeclinedType,
      title: 'Ride Request Declined',
      message:
          'Your ride request for $routeDetails on $departureDate at $departureTime was declined.',
      driverId: driverId,
      routeDetails: routeDetails,
      departureDate: departureDate,
      departureTime: departureTime,
    );
    } on FirebaseException catch (e) {
      throw Exception('Failed to decline ride request: ${e.code}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> acceptRideRequest({
    required String rideId,
    required String requestId,
  }) async {
    final driverId = _currentUid;
    final rideRef = _ridesCollectionRef().doc(rideId);
    final requestRef = _requestDocRef(
      rideId: rideId,
      requestId: requestId,
    );

    String errorMessage = '';
    String passengerId = '';
    String routeDetails = '';
    String departureDate = '';
    String departureTime = '';
    try {
      await _db.runTransaction((transaction) async {
        final rideSnap = await transaction.get(rideRef);
        if (!rideSnap.exists) {
          errorMessage = 'Ride not found.';
          throw Exception(errorMessage);
        }

        final rideData = rideSnap.data();
        if (rideData == null) {
          errorMessage = 'Ride data not found.';
          throw Exception(errorMessage);
        }

        if (rideData[driverIdField] != driverId) {
          errorMessage = 'Only the driver can manage ride requests for this ride.';
          throw Exception(errorMessage);
        }
        routeDetails = (rideData[routeDetailsField] as String? ?? '').trim();
        departureDate = (rideData[departureDateField] as String? ?? '').trim();
        departureTime = (rideData[departureTimeField] as String? ?? '').trim();
        final requestSnap = await transaction.get(requestRef);
        if (!requestSnap.exists) {
          errorMessage = 'Ride request not found.';
          throw Exception(errorMessage);
        }

        final requestData = requestSnap.data();
        if (requestData == null) {
          errorMessage = 'Ride request data not found.';
          throw Exception(errorMessage);
        }

        final request = RideRequestModel.fromDoc(requestSnap);

        if (request.rideId != rideId) {
          errorMessage = 'Ride request does not belong to this ride.';
          throw Exception(errorMessage);
        }

        if (request.driverId != driverId) {
          errorMessage = 'Ride request does not belong to the current driver.';
          throw Exception(errorMessage);
        }

        if (request.status != RideRequestStatus.pending) {
          errorMessage = 'Only pending ride requests can be updated.';
          throw Exception(errorMessage);
        }

        final availableSeats = (rideData[availableSeatsField] as num?)?.toInt() ?? 0;
        if (availableSeats <= 0) {
          errorMessage = 'No seats available to accept this request.';
          throw Exception(errorMessage);
        }

        final enrolledUserIds = List<String>.from(
          rideData[enrolledUserIdsField] ?? const [],
        );

        if (enrolledUserIds.contains(request.passengerId)) {
          errorMessage = 'Passenger is already enrolled in this ride.';
          throw Exception(errorMessage);
        }
         passengerId = request.passengerId;
        enrolledUserIds.add(request.passengerId);

        transaction.update(requestRef, {
          requestStatusField: RideRequestStatus.accepted.name,
          requestUpdatedAtField: FieldValue.serverTimestamp(),
        });

        transaction.update(rideRef, {
          enrolledUserIdsField: enrolledUserIds,
          availableSeatsField: availableSeats - 1,
        });
      });

      try {
        await _userRequestDocRef(
          passengerId: passengerId,
          rideId: rideId,
        ).set({
          requestRideIdField: rideId,
          requestDriverIdField: driverId,
          requestPassengerIdField: passengerId,
          requestStatusField: RideRequestStatus.accepted.name,
          requestUpdatedAtField: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }

      await _createRideRequestStatusNotification(
      passengerId: passengerId,
      rideId: rideId,
      type: rideRequestAcceptedType,
      title: 'Ride Request Accepted',
      message:
          'Your ride request for $routeDetails on $departureDate at $departureTime was accepted.',
      driverId: driverId,
      routeDetails: routeDetails,
      departureDate: departureDate,
      departureTime: departureTime,
    );
    } on FirebaseException catch (e) {
      throw Exception('Failed to accept ride request: ${e.code}');
    } catch (e) {
      throw errorMessage.isNotEmpty ? errorMessage : e.toString();
    }
  }

  Future<List<RideModel>> getRidesForCurrentUserWithVehicles() async {
    final rides = await getRidesForCurrentUser();
    if (rides.isEmpty) return rides;

    final uid = _currentUid;
    final vehiclesRef = _vehiclesCollectionRef(uid);

    final vehicleIds =
        rides.map((r) => r.vehicleId).where((id) => id.isNotEmpty).toSet();

    final vehicleSnaps = await Future.wait(
      vehicleIds.map((id) => vehiclesRef.doc(id).get()),
    );

    final Map<String, CarModel> vehicleById = {};

    for (final snap in vehicleSnaps) {
      if (snap.exists) {
        vehicleById[snap.id] = CarModel.fromDoc(snap);
      }
    }

    return rides
        .map((r) => r.copyWith(vehicle: vehicleById[r.vehicleId]))
        .toList();
  }

  Future<List<RideModel>> getCancelledRidesForCurrentUserWithVehicles() async {
    final uid = _currentUid;

    try {
      final snapshot = await _ridesCollectionRef()
          .where(driverIdField, isEqualTo: uid)
          .where(statusField, isEqualTo: cancelledStatus)
          .orderBy(cancelledAtField, descending: true)
          .get();

      final rides = snapshot.docs.map(RideModel.fromDoc).toList();
      if (rides.isEmpty) return rides;

      final vehiclesRef = _vehiclesCollectionRef(uid);

      final vehicleIds =
          rides.map((r) => r.vehicleId).where((id) => id.isNotEmpty).toSet();

      final vehicleSnaps = await Future.wait(
        vehicleIds.map((id) => vehiclesRef.doc(id).get()),
      );

      final Map<String, CarModel> vehicleById = {};

      for (final snap in vehicleSnaps) {
        if (snap.exists) {
          vehicleById[snap.id] = CarModel.fromDoc(snap);
        }
      }

      return rides
          .map((r) => r.copyWith(vehicle: vehicleById[r.vehicleId]))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch cancelled rides: ${e.code}');
    } catch (_) {
      throw Exception('Failed to fetch cancelled rides.');
    }
  }

  Future<List<RideModel>> getAvailableRides({
    DateTime? startDate,
    DateTime? endDate,
    Set<DayOfWeek>? selectedDaysOfWeek,
    Set<String>? selectedTimesOfDay,
  }) async {
    final uid = _currentUid;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedStartDate =
        startDate == null ? null : DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate =
        endDate == null ? null : DateTime(endDate.year, endDate.month, endDate.day);
    final formattedStartDate =
        normalizedStartDate == null ? null : _formatDate(normalizedStartDate);
    final formattedEndDate =
        normalizedEndDate == null ? null : _formatDate(normalizedEndDate);
    final dayFilters = selectedDaysOfWeek ?? <DayOfWeek>{};
    final timeFilters = selectedTimesOfDay ?? <String>{};

    try {
      Query<Map<String, dynamic>> query = _ridesCollectionRef()
          .where(statusField, isEqualTo: activeStatus)
          .orderBy(departureDateField, descending: false)
          .orderBy(departureTimeField, descending: false);

      if (formattedStartDate != null) {
        query = query.where(
          departureDateField,
          isGreaterThanOrEqualTo: formattedStartDate,
        );
      }

      if (formattedEndDate != null) {
        query = query.where(
          departureDateField,
          isLessThanOrEqualTo: formattedEndDate,
        );
      }

      final snapshot = await query.get();

      final rides = snapshot.docs.map(RideModel.fromDoc).toList();

      final hasDayFilters = dayFilters.isNotEmpty;
      final hasTimeFilters = timeFilters.isNotEmpty;
      return rides.where((r) {
        if (r.driverId == uid) {
          return false;
        }
        if (r.availableSeats <= 0) {
          return false;
        }
        final rideDateTime = _getRideDepartureDateTime(r);

        if (hasDayFilters) {
          final rideDayOfWeek = _getDayOfWeekFromDateTime(rideDateTime);
          if (!dayFilters.contains(rideDayOfWeek)) {
            return false;
          }
        }
        if (hasTimeFilters) {
          final rideTimeBucket = _getTimeOfDayBucket(rideDateTime);
          if (!timeFilters.contains(rideTimeBucket)) {
            return false;
          }
        }

        final rideDate = DateTime(
          rideDateTime.year,
          rideDateTime.month,
          rideDateTime.day,
        );

        if (normalizedStartDate != null &&
          rideDate.isBefore(normalizedStartDate)) {
          return false;
        }

        if (normalizedEndDate != null && rideDate.isAfter(normalizedEndDate)) {
          return false;
        }

        if (rideDate.isBefore(today)) {
          return false;
        }

        if (rideDate.isAtSameMomentAs(today) && !rideDateTime.isAfter(now)) {
          return false;
        }

        return true;
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch available rides: ${e.code}');
    } catch (_) {
      throw Exception('Failed to fetch available rides.');
    }
  }

  Future<List<RideModel>> getAvailableRidesWithVehicles({
    DateTime? startDate,
    DateTime? endDate,
    Set<DayOfWeek>? selectedDaysOfWeek,
    Set<String>? selectedTimesOfDay,
  }) async {
    final rides = await getAvailableRides(
      startDate: startDate,
      endDate: endDate,
      selectedDaysOfWeek: selectedDaysOfWeek,
      selectedTimesOfDay: selectedTimesOfDay,
    );

    if (rides.isEmpty) return rides;

    final vehicleFetches = rides
        .where((ride) => ride.vehicleId.isNotEmpty)
        .map((ride) async {
          try {
            final snap = await _vehiclesCollectionRef(
              ride.driverId,
            ).doc(ride.vehicleId).get();

            if (!snap.exists) {
              return MapEntry(ride.rideId, null);
            }

            return MapEntry(ride.rideId, CarModel.fromDoc(snap));
          } on FirebaseException catch (e) {
            // In some environments, passengers cannot read another user's
            // vehicles subcollection due to Firestore rules. Keep the ride
            // visible and just omit vehicle details.
            if (e.code == 'permission-denied') {
              return MapEntry(ride.rideId, null);
            }
            rethrow;
          }
        });

    final fetchedVehicles = await Future.wait(vehicleFetches);

    final vehicleByRideId = <String, CarModel>{};

    for (final entry in fetchedVehicles) {
      if (entry.value != null) {
        vehicleByRideId[entry.key] = entry.value!;
      }
    }

    return rides
        .map((ride) => ride.copyWith(vehicle: vehicleByRideId[ride.rideId]))
        .toList();
  }

    Future<void> cancelRide({
      required String rideId,
      required String cancelReason,
    }) async {
      final uid = _currentUid;

      if (cancelReason.trim().isEmpty) {
        throw ArgumentError('Cancellation reason is required.');
      }

      try {
        final rideRef = _ridesCollectionRef().doc(rideId);
        final rideSnap = await rideRef.get();

        if (!rideSnap.exists) {
          throw Exception('Ride not found.');
        }

        final rideData = rideSnap.data();
        if (rideData == null) {
          throw Exception('Ride data not found.');
        }

        if (rideData[driverIdField] != uid) {
          throw Exception('Only the driver can cancel this ride.');
        }

        if (rideData[statusField] == cancelledStatus) {
          throw Exception('Ride is already cancelled.');
        }

        final ride = RideModel.fromDoc(rideSnap);

        await rideRef.update({
          statusField: cancelledStatus,
          cancelReasonField: cancelReason.trim(),
          cancelledAtField: FieldValue.serverTimestamp(),
        });

        await _createCancellationNotifications(
          userIds: ride.enrolledUserIds,
          ride: ride.copyWith(cancelReason: cancelReason.trim())
        );
      } on FirebaseException catch (e) {
        throw Exception('Failed to cancel ride: ${e.code}');
      } catch (e) {
        throw Exception(e.toString());
      }
    }

  CollectionReference<Map<String, dynamic>> _notificationsCollectionRef(String uid) {
    return _db
        .collection(usersCollection)
        .doc(uid)
        .collection(notificationsSubcollection);
  }
  Future<void> _createRideRequestStatusNotification({
  required String passengerId,
  required String rideId,
  required String type,
  required String title,
  required String message,
  String? driverId,
  String? routeDetails,
  String? departureDate,
  String? departureTime,
  }) async {
    await _notificationsCollectionRef(passengerId).add({
      'type': type,
      'rideId': rideId,
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      ...?driverId == null ? null : {driverIdField: driverId},
      ...?routeDetails == null ? null : {routeDetailsField: routeDetails},
      ...?departureDate == null ? null : {departureDateField: departureDate},
      ...?departureTime == null ? null : {departureTimeField: departureTime},
    });
  }
  Future<void> _createCancellationNotifications({
    required List<String> userIds,
    required RideModel ride,
  }) async {
    if (userIds.isEmpty) return;

    final batch = _db.batch();

    for (final userId in userIds) {
      final notificationRef = _notificationsCollectionRef(userId).doc();

      batch.set(notificationRef, {
        'type': rideCancelledType,
        'rideId': ride.rideId,
        'title': 'Ride Cancelled',
        'message':
            'Your ride on ${ride.departureDate} at ${ride.departureTime} has been cancelled.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        routeDetailsField: ride.routeDetails,
        departureDateField: ride.departureDate,
        departureTimeField: ride.departureTime,
        driverIdField: ride.driverId,
        cancelReasonField: ride.cancelReason,
      });
    }

    await batch.commit();
  }

  Future<void> enrollInRide(String rideId) async {
    final uid = _currentUid;
    final rideRef = _ridesCollectionRef().doc(rideId);

    try {
      await _db.runTransaction((transaction) async {
        final rideSnap = await transaction.get(rideRef);

        if (!rideSnap.exists) {
          throw Exception('Ride not found.');
        }

        final rideData = rideSnap.data();
        if (rideData == null) {
          throw Exception('Ride data not found.');
        }

        final driverId = rideData[driverIdField] as String? ?? '';
        final status = rideData[statusField] as String? ?? '';
        final availableSeats = (rideData[availableSeatsField] as num?)?.toInt() ?? 0;
        final enrolledUserIds = List<String>.from(
          rideData[enrolledUserIdsField] ?? const [],
        );

        if (driverId == uid) {
          throw Exception('Driver cannot enroll in their own ride.');
        }

        if (status != activeStatus) {
          throw Exception('Only active rides can be enrolled in.');
        }

        if (enrolledUserIds.contains(uid)) {
          throw Exception('You are already enrolled in this ride.');
        }

        if (availableSeats <= 0) {
          throw Exception('No seats available.');
        }

        enrolledUserIds.add(uid);

        transaction.update(rideRef, {
          enrolledUserIdsField: enrolledUserIds,
          availableSeatsField: availableSeats - 1,
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to enroll in ride: ${e.code}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsForCurrentUser() {
    final uid = _currentUid;

    return _notificationsCollectionRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

