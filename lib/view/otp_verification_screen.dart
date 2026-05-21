import 'dart:async';
import 'package:unh_rideshare_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unh_rideshare_app/services/user_profile_service.dart';
import 'package:unh_rideshare_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unh_rideshare_app/view/sign_up_screen.dart';
import 'package:unh_rideshare_app/view/sign_in_screen.dart';


class OtpVerificationScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String verificationId;
  final ConfirmationResult? confirmationResult;
  final bool isSignUpFlow;

  const OtpVerificationScreen({
    super.key,
    this.name = '',
    this.phoneNumber = '',
    this.verificationId = '',
    this.confirmationResult,
    this.isSignUpFlow = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  Timer? _resendTimer;
  Timer? _expiryTimer;

  int _resendSecondsLeft = 30;
  bool _resendEnabled = false;

  int _attempts = 0;
  bool _locked = false;
  bool _otpExpired = false;

  String _message = '';
  bool _isVerifying = false;

  final AuthService _authService = AuthService();
  late String _currentVerificationId;
  late ConfirmationResult? _currentConfirmationResult;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentConfirmationResult = widget.confirmationResult;
    _startResendCountdown();
    _startOtpExpiryTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendEnabled = false;
      _resendSecondsLeft = 30;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsLeft = 0;
          _resendEnabled = true;
        });
        return;
      }

      setState(() {
        _resendSecondsLeft -= 1;
      });
    });
  }

  void _startOtpExpiryTimer() {
    _otpExpired = false;

    _expiryTimer?.cancel();
    _expiryTimer = Timer(const Duration(minutes: 5), () {
      if (!mounted) return;
      setState(() {
        _otpExpired = true;
        _message = 'Code expired, please request a new one';
      });
    });
  }

  bool _otpHasSixDigits() {
    return _otpController.text.trim().length == 6;
  }

  void _setMessage(String msg) {
    setState(() {
      _message = msg;
    });
  }

  void _lockOut() {
    setState(() {
      _locked = true;
      _message = 'Too many attempts. Please try again later.';
    });
  }

  Future<void> _verifyOtp() async {
    if (_locked) {
      _setMessage('Too many attempts. Please try again later.');
      return;
    }

    if (_otpExpired) {
      _setMessage('Code expired, please request a new one');
      return;
    }

    if (!_otpHasSixDigits()) {
      _setMessage('Please enter the 6-digit code');
      return;
    }

    if (_currentVerificationId.trim().isEmpty) {
      _setMessage('Verification is not ready yet. Please resend code.');
      return;
    }


    setState(() {
      _isVerifying = true;
      _message = '';
    });

    try {
      final smsCode = _otpController.text.trim();

      final userCred = await _authService.verifyOtp(
        smsCode: smsCode,
        verificationId: _currentVerificationId,
        confirmationResult: _currentConfirmationResult,
      );

      final uid = userCred.user?.uid;

      if (uid == null) {
        _setMessage('Login failed. Please try again.');
        return;
      }
      if (!widget.isSignUpFlow) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (!userDoc.exists) {
          await _authService.signOut();
          _setMessage('Phone number not registered. Please sign up first.');

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SignUpScreen(
              prefillPhoneNumber: widget.phoneNumber.trim().replaceFirst('+1', ''),
              unregisteredNumberMessage: 'Phone number not registered. Please sign up first.',
            )),
          );
          return;
         }
      }
      if (widget.isSignUpFlow) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
              await _authService.signOut();
              if (!mounted) return;
              _setMessage('Number already registered. Please log in.');
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SignInScreen()),
              );
              return;
          }
      }
      if (widget.isSignUpFlow) {
        await UserProfileService().upsertUserProfile(
          uid: uid,
          name: widget.name.trim(),
          phoneNumber: widget.phoneNumber.trim(),
        );
        await userCred.user?.updateDisplayName(widget.name.trim());
        await userCred.user?.reload();
      }

      // Always save FCM token after login/signup
      await saveFcmTokenToFirestore();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        _attempts += 1;
        if (_attempts >= 3) {
          _lockOut();
        } else {
          _setMessage('Invalid code, please try again');
        }
        return;
      }
      if (e.code == 'session-expired' || e.code == 'invalid-verification-id') {
        setState(() {_otpExpired = true;});
        _setMessage('Code expired, please request a new one');
        return;
      }
      if (e.code == 'too-many-requests') {
        _lockOut();
        return;
      }

    _setMessage(e.message ?? 'Verification failed. Please try again.');
  } catch (_) {
    _setMessage('Verification failed. Please try again.');
  } finally {
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }
}

  Future<void> _resendCode() async {
    if (_locked) {
      _setMessage('Too many attempts. Please try again later.');
      return;
    }

    if (!_resendEnabled) {
      return;
    }

    setState(() {
      _message = 'New code sent';
      _otpController.clear();
      _otpExpired = false;
    });
    await _authService.sendOtp(
      phoneNumberE164: widget.phoneNumber,
      isResend: true,
      onCodeSent: (newVerificationId, {confirmationResult}) {
        if (!mounted) return;
        setState(() {
          _currentVerificationId = newVerificationId;
          _currentConfirmationResult = confirmationResult;
          _message = 'New code sent';
        });
      },
      onError: (code, msg) {
        if (!mounted) return;
        setState(() {
          _message = msg.isEmpty ? code : '$code: $msg';
        });
      },
    );
    _startResendCountdown();
    _startOtpExpiryTimer();
  }

  @override
  Widget build(BuildContext context) {
    final bool verifyEnabled =
        !_locked && !_otpExpired && _otpHasSixDigits() && !_isVerifying;
    final bool resendEnabled = !_locked && _resendEnabled && _attempts < 3;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 80,
              children: [
                SizedBox(
                  height: 150,
                  child: Image.asset(
                    'assets/images/UNH_RideShare.png',
                    fit: BoxFit.fitHeight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
                  width: 300,
                  child: Column(
                    spacing: 30,
                    children: [
                  const Text(
                    'OTP Verification',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.phoneNumber.isEmpty
                        ? 'Enter the 6-digit code'
                        : 'Enter the 6-digit code sent to ${widget.phoneNumber}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Column(
                    spacing: 20,
                    children: [
                      TextField(
                        controller: _otpController,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Enter OTP',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: verifyEnabled ? _verifyOtp : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 0, 27, 67),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: resendEnabled ? _resendCode : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(30, 18, 30, 18),
                            side: const BorderSide(color: Color.fromARGB(255, 0, 27, 67)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            resendEnabled
                                ? 'Resend Code'
                                : 'Resend Code (${_resendSecondsLeft}s)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 27, 67),
                            ),
                          ),
                        ),
                      ),
                      if (_message.isNotEmpty)
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _message == 'New code sent'
                                ? Colors.green[600]
                                : Colors.red[400],
                          ),
                        ),
                      Text(
                        'Attempts: $_attempts / 3',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
