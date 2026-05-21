import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db}) : _auth = auth ?? FirebaseAuth.instance, _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? _verificationId;
  int? _resendToken;

  ConfirmationResult? _confirmationResult;

  Future<bool> isPhoneRegistered(String phoneNumberE164) async {
    final snap = await _db
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumberE164)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<void> sendOtp({
    required String phoneNumberE164,
    required void Function(String verificationId, {ConfirmationResult? confirmationResult}) onCodeSent,
    void Function()? onAutoVerified,
    void Function(String code, String message)? onError,
    bool isResend = false,
  }) async {
    try {
      // Basic sanity log (helps confirm E.164 formatting)
      debugPrint("➡️ sendOtp called. phone=$phoneNumberE164 isResend=$isResend");

      if (kIsWeb) {
        _confirmationResult = await _auth.signInWithPhoneNumber(phoneNumberE164);
        _verificationId = _confirmationResult!.verificationId;
        debugPrint("(web) codeSent: verificationId=$_verificationId");
        onCodeSent(_verificationId!, confirmationResult: _confirmationResult!);
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumberE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,

        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint("verificationCompleted (auto)");
          await _auth.signInWithCredential(credential);
          onAutoVerified?.call();
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint("verificationFailed: ${e.code} | ${e.message}");
          onError?.call(e.code, e.message ?? '');
        },

        codeSent: (String verificationId, int? resendToken) {
          debugPrint("codeSent: verificationId=$verificationId resendToken=$resendToken");
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("codeAutoRetrievaltimeout: verificationId=$verificationId");
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("sendOtp FirebaseAuthException: ${e.code} | ${e.message}");
      onError?.call(e.code, e.message ?? '');
    } catch (e) {
      debugPrint("sendOtp exception: $e");
      onError?.call('unknown', e.toString());
    }
  }

  Future<UserCredential> verifyOtp({
    required String smsCode,
    String? verificationId,
    ConfirmationResult? confirmationResult,
  }) async {
    final code = smsCode.trim();

    if (kIsWeb) {
      final result = confirmationResult;
      if (result == null) {
        throw StateError("Missing confirmation result.");
      }
      return await result.confirm(code);
    }

    final id = verificationId ?? _verificationId;
    if (id == null || id.trim().isEmpty) {
      throw StateError("Verification ID missing. Call sendOtp() first.");
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: id,
      smsCode: code,
    );

    return await _auth.signInWithCredential(credential);
  }
  void resetOtpSession() {
    _verificationId = null;
    _resendToken = null;
    _confirmationResult = null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    resetOtpSession();
  }
  Future<void> deleteCurrentUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final uid = user.uid;

    try {
      await _db.collection('users').doc(uid).delete();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again and try deleting your account.');
      }
      rethrow;
    }
  }
}
