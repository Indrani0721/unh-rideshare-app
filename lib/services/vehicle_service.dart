import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/car_model.dart';

class VehicleService {
  VehicleService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String usersCollection = 'users';
  static const String vehiclesSubcollection = 'vehicles';

  static const String makeField = 'make';
  static const String modelField = 'model';
  static const String yearField = 'year';
  static const String colorField = 'color';
  static const String licensePlateField = 'licensePlate';
  static const String vehiclePhotoUrlField = 'vehiclePhotoUrl';
  static const String licensePlatePhotoUrlField = 'licensePlatePhotoUrl';
  static const String isCompleteField = 'isComplete';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';

  void _requireNonEmpty({
    required String make,
    required String model,
    required String year,
    required String color,
    required String licensePlate,
  }) {
    if (make.trim().isEmpty) throw Exception('Make is required.');
    if (model.trim().isEmpty) throw Exception('Model is required.');
    if (year.trim().isEmpty) throw Exception('Year is required.');
    if (color.trim().isEmpty) throw Exception('Color is required.');
    if (licensePlate.trim().isEmpty) throw Exception('License plate is required.');
  }

  String get _currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }
    return user.uid;
  }

  String get currentUid => _currentUid;

  DocumentReference<Map<String, dynamic>> _userDocRef([String? uid]) {
    final resolvedUid = uid ?? _currentUid;
    return _db.collection(usersCollection).doc(resolvedUid);
  }

  CollectionReference<Map<String, dynamic>> _vehiclesCollectionRef([String? uid]) {
    return _userDocRef(uid).collection(vehiclesSubcollection);
  }

  DocumentReference<Map<String, dynamic>> vehicleDocRef({
    required String vehicleId,
    String? uid,
  }) {
    return _vehiclesCollectionRef(uid).doc(vehicleId);
  }

  DocumentReference<Map<String, dynamic>> createVehicleDocRef({String? uid}) {
    return _vehiclesCollectionRef(uid).doc();
  }

  bool computeIsComplete({
    required String make,
    required String model,
    required String year,
    required String color,
    required String licensePlate,
  }) {
    return make.trim().isNotEmpty &&
        model.trim().isNotEmpty &&
        year.trim().isNotEmpty &&
        color.trim().isNotEmpty &&
        licensePlate.trim().isNotEmpty;
  }

  Map<String, dynamic> buildVehiclePayload({
    required String make,
    required String model,
    required String year,
    required String color,
    required String licensePlate,
    String? vehiclePhotoUrl,
    String? licensePlatePhotoUrl,
  }) {
    final trimmedMake = make.trim();
    final trimmedModel = model.trim();
    final trimmedYear = year.trim();
    final trimmedColor = color.trim();
    final trimmedLicensePlate = licensePlate.trim();

    return {
      makeField: trimmedMake,
      modelField: trimmedModel,
      yearField: trimmedYear,
      colorField: trimmedColor,
      licensePlateField: trimmedLicensePlate,
      vehiclePhotoUrlField: vehiclePhotoUrl,
      licensePlatePhotoUrlField: licensePlatePhotoUrl,
      isCompleteField: computeIsComplete(
        make: trimmedMake,
        model: trimmedModel,
        year: trimmedYear,
        color: trimmedColor,
        licensePlate: trimmedLicensePlate,
      ),
    };
  }

  Future<String> createVehicle({
    required String make,
    required String model,
    required String year,
    required String color,
    required String licensePlate,
    String? vehiclePhotoUrl,
    String? licensePlatePhotoUrl,
    String? vehicleId,
  }) async {
    _requireNonEmpty(
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: licensePlate,
    );
    final payload = buildVehiclePayload(
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: licensePlate,
      vehiclePhotoUrl: vehiclePhotoUrl,
      licensePlatePhotoUrl: licensePlatePhotoUrl,
    );

    final newVehicleRef =
        vehicleId == null
            ? createVehicleDocRef()
            : vehicleDocRef(vehicleId: vehicleId);

    try {
      await newVehicleRef.set({
        ...payload,
        createdAtField: FieldValue.serverTimestamp(),
        updatedAtField: FieldValue.serverTimestamp(),
      });

      return newVehicleRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to create vehicle: ${e.code}');
    } catch (_) {
      throw Exception('Failed to create vehicle.');
    }
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String make,
    required String model,
    required String year,
    required String color,
    required String licensePlate,
    String? vehiclePhotoUrl,
    String? licensePlatePhotoUrl,
  }) async {
    _requireNonEmpty(
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: licensePlate,
    );
    final payload = buildVehiclePayload(
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: licensePlate,
      vehiclePhotoUrl: vehiclePhotoUrl,
      licensePlatePhotoUrl: licensePlatePhotoUrl,
    );

    try {
      await vehicleDocRef(vehicleId: vehicleId).set(
        {
          ...payload,
          updatedAtField: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw Exception('Failed to update vehicle: ${e.code}');
    } catch (_) {
      throw Exception('Failed to update vehicle.');
    }
  }

  Future<List<CarModel>> getVehiclesForCurrentUser() async {
    try {
      final snapshot = await _vehiclesCollectionRef()
          .orderBy(updatedAtField, descending: true)
          .get();

      return snapshot.docs.map(CarModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch vehicles: ${e.code}');
    } catch (_) {
      throw Exception('Failed to fetch vehicles.');
    }
  }

  Future<CarModel?> getVehicleById({required String vehicleId}) async {
    try {
      final snapshot = await vehicleDocRef(vehicleId: vehicleId).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return CarModel.fromDoc(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch vehicle: ${e.code}');
    } catch (_) {
      throw Exception('Failed to fetch vehicle.');
    }
  }

  Future<CarModel> requireVehicleById({required String vehicleId}) async {
    final car = await getVehicleById(vehicleId: vehicleId);
    if (car == null) {
      throw Exception('Vehicle not found.');
    }
    return car;
  }

  Future<void> deleteVehicle({required String vehicleId}) async {
    try {
      await vehicleDocRef(vehicleId: vehicleId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete vehicle: ${e.code}');
    } catch (_) {
      throw Exception('Failed to delete vehicle.');
    }
  }

  Future<bool> hasActiveFutureRidesUsingVehicle({
    required String vehicleId,
  }) async {
    try {
      final now = DateTime.now();

      final snap = await _db
          .collection('rides')
          .where('driverId', isEqualTo: _currentUid)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();

        final departureDate = (data['departureDate'] as String?)?.trim();
        final departureTime = (data['departureTime'] as String?)?.trim();

        if (departureDate == null ||
            departureDate.isEmpty ||
            departureTime == null ||
            departureTime.isEmpty) {
          continue;
        }

        final rideDateTime = DateTime.tryParse(
          '${departureDate}T$departureTime:00',
        );

        if (rideDateTime != null && rideDateTime.isAfter(now)) {
          return true;
        }
      }

      return false;
    } on FirebaseException catch (e) {
      throw Exception('Failed to validate vehicle deletion: ${e.code}');
    } catch (_) {
      throw Exception('Failed to validate vehicle deletion.');
    }
  }

  Future<void> deleteVehicleSafely({required String vehicleId}) async {
    final hasBlockingRides = await hasActiveFutureRidesUsingVehicle(
      vehicleId: vehicleId,
    );

    if (hasBlockingRides) {
      throw Exception(
        'This vehicle is assigned to one or more upcoming active rides. '
        'Cancel those rides before deleting the vehicle.',
      );
    }

    await deleteVehicle(vehicleId: vehicleId);
  }

  Future<bool> isAnyVehicleCompleteForCurrentUser() async {
    try {
      final snap = await _vehiclesCollectionRef()
          .where(isCompleteField, isEqualTo: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw Exception('Failed to validate vehicle completeness: ${e.code}');
    } catch (_) {
      throw Exception('Failed to validate vehicle completeness.');
    }
  }

  Future<bool> isVehicleComplete({required String vehicleId}) async {
    final car = await getVehicleById(vehicleId: vehicleId);
    return car?.isComplete ?? false;
  }

  Future<String?> findAnyCompleteVehicleIdForCurrentUser() async {
    try {
      final snap = await _vehiclesCollectionRef()
          .where(isCompleteField, isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return snap.docs.first.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to resolve complete vehicle: ${e.code}');
    } catch (_) {
      throw Exception('Failed to resolve complete vehicle.');
    }
  }
}
