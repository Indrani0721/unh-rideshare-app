import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unh_rideshare_app/utils/phone_validation.dart';
import 'package:unh_rideshare_app/view/otp_verification_screen.dart';
import 'package:unh_rideshare_app/view/sign_up_screen.dart';
import 'package:unh_rideshare_app/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController phoneNumberController = TextEditingController();
  String phoneNumber = '';
  String message = '';
  bool checkPhone = true;
  bool _isSending = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending) return;
    final result =
        PhoneValidator.validate(phoneNumberController.text);

    if (!result.isValid) {
      setState(() {
        checkPhone = false;
        message =
            result.errorMessage ?? PhoneValidator.errorText;
      });
      return;
    }

    final String fullNumber = result.phoneWithCountryCode!;

    setState(() {
      _isSending = true;
      checkPhone = true;
      message = 'Sending code to $fullNumber...';
    });
    try {
      setState(() {
        message = 'Sending code to $fullNumber...';
      });

      await _authService.sendOtp(
        phoneNumberE164: fullNumber,
        onCodeSent: (verificationId, {confirmationResult}) {
          if (!mounted) return;

          setState(() {
            _isSending = false;
            checkPhone = true;
            message = 'Code sent to $fullNumber';
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: fullNumber,
                verificationId: verificationId,
                confirmationResult: confirmationResult,
                isSignUpFlow: false,
              ),
            ),
          );
      },
      onError: (code, msg) {
        if (!mounted) return;

        setState(() {
          _isSending = false;
          checkPhone = false;
          message = msg.isNotEmpty ? '$code: $msg' : code;
        });
      },
    );
  } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        checkPhone = false;
        message = 'Error sending code: $e';
      });
    }
  }

  // Formats phone number input as (###) ###-####
  TextInputFormatter _phoneNumberFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
      String formatted = '';
      for (int i = 0; i < digitsOnly.length && i < 10; i++) {
        if (i == 3) formatted = '($formatted) ';
        if (i == 6) {
          formatted = '$formatted-${digitsOnly[i]}';
        } else {
          formatted = '$formatted${digitsOnly[i]}';
        }
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 80,
          children: [
            // Logo
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
                  // Sign In Text
                  Text(
                    'Sign In',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Enter your phone number to receive a verification code',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Column(
                    spacing: 20,
                    children: [
                      // Phone Number Text Field
                      TextField(
                        controller: phoneNumberController,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.phone),
                          hintText: 'Enter Phone Number',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        inputFormatters: [_phoneNumberFormatter()],
                        keyboardType: TextInputType.phone,
                      ),
                      // Send Code Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendCode,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromARGB(255, 0, 27, 67),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Send Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Place for error message
                      Text(
                        message,
                        style: TextStyle(
                          color: checkPhone ? Colors.green[500] : Colors.red[300],
                        ),
                      ),
                    ],
                  ),
                  // Placeholder for "Don't have an account? Sign Up" text
                  TextButton(
                    onPressed: () {
                      // Navigate to the sign-up screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                    },
                    child: Text("Don't have an account? Sign Up"),
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
