import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unh_rideshare_app/models/user_public_info_model.dart';

class UserProfileService {
  final FirebaseFirestore _db;

  UserProfileService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Future<void> upsertUserProfile({
    required String uid,
    required String name,
    required String phoneNumber,
    String? profilePhotoUrl,
  }) async {
    final docRef = _db.collection('users').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = <String, dynamic>{
      'name': name,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (profilePhotoUrl != null) {
      data['profilePhotoUrl'] = profilePhotoUrl;
    }

    if (!snap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    tx.set(docRef, data, SetOptions(merge: true));
  });
}


  // Update only the fields that are provided (non-null)
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? profilePhotoUrl,
    bool? rideReminderEnabled,
    int? rideReminderMinutes,
  }) async {
    final docRef = _db.collection('users').doc(uid);
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) {
      data['name'] = name;
    }
    if (profilePhotoUrl != null) {
      data['profilePhotoUrl'] = profilePhotoUrl;
    }
     if (rideReminderEnabled != null) {
    data['rideReminderEnabled'] = rideReminderEnabled;
    }
    if (rideReminderMinutes != null) {
      data['rideReminderMinutes'] = rideReminderMinutes;
    }
      await docRef.set(data, SetOptions(merge: true));
    }


  // Get user name by UID
  Future<String?> getUserName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['name'] as String?;
    }
    return null;
  }

  // Get user public info by UID
  Future<UserPublicInfoModel?> getUserPublicInfo(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      return UserPublicInfoModel(
        userId: uid,
        name: data['name'] as String,
        profilePictureUrl: data['profilePhotoUrl'] as String?,
      );
    }
    return null;
  }
}
