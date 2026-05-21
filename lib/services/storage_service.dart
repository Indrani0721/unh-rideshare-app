import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const String usersFolder = 'users';
  static const String vehiclesFolder = 'vehicles';
  static const String profilePhotoFileName = 'profile_photo.jpg';
  static const String vehiclePhotoFileName = 'vehicle_photo.jpg';
  static const String licensePlatePhotoFileName = 'license_plate_photo.jpg';

  Reference _userFolderRef({
    required String uid,
  }) {
    return _storage
        .ref()
        .child(usersFolder)
        .child(uid);
  }

  Reference _vehicleFolderRef({
    required String uid,
    required String vehicleId,
  }) {
    return _storage
        .ref()
        .child(usersFolder)
        .child(uid)
        .child(vehiclesFolder)
        .child(vehicleId);
  }

  Reference profilePhotoRef({
    required String uid,
  }) {
    return _userFolderRef(uid: uid).child(profilePhotoFileName);
  }

  Reference vehiclePhotoRef({
    required String uid,
    required String vehicleId,
  }) {
    return _vehicleFolderRef(
      uid: uid,
      vehicleId: vehicleId,
    ).child(vehiclePhotoFileName);
  }

  Reference licensePlatePhotoRef({
    required String uid,
    required String vehicleId,
  }) {
    return _vehicleFolderRef(
      uid: uid,
      vehicleId: vehicleId,
    ).child(licensePlatePhotoFileName);
  }

  Future<String> _uploadPhoto({
    required Reference ref,
    required XFile file,
  }) async {
    try {
      final metadata = SettableMetadata(
        contentType: file.mimeType ?? 'image/jpeg',
      );

      // 1. Check if we are on Web
      if (kIsWeb) {
        // Read the file as bytes (Uint8List) which works in browsers
        final Uint8List fileBytes = await file.readAsBytes();
        await ref.putData(fileBytes, metadata);
      } else {
        // Use the standard File approach for iOS/Android
        final io.File fileToUpload = io.File(file.path);
        await ref.putFile(fileToUpload, metadata);
      }

      final downloadUrl = await ref.getDownloadURL();
      return '$downloadUrl&v=${DateTime.now().millisecondsSinceEpoch}';

    } on FirebaseException catch (e) {
      throw Exception('Failed to upload image: ${e.code}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile file,
  }) {
    return _uploadPhoto(
      ref: profilePhotoRef(uid: uid),
      file: file,
    );
  }

  Future<String> uploadVehiclePhoto({
    required String uid,
    required String vehicleId,
    required XFile file,
  }) {
    return _uploadPhoto(
      ref: vehiclePhotoRef(
        uid: uid,
        vehicleId: vehicleId,
      ),
      file: file,
    );
  }

  Future<String> uploadLicensePlatePhoto({
    required String uid,
    required String vehicleId,
    required XFile file,
  }) {
    return _uploadPhoto(
      ref: licensePlatePhotoRef(
        uid: uid,
        vehicleId: vehicleId,
      ),
      file: file,
    );
  }
}
