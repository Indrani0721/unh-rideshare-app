import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unh_rideshare_app/utils/formatter.dart';
import 'package:unh_rideshare_app/utils/phone_validation.dart';
import 'package:unh_rideshare_app/view/otp_verification_screen.dart';
import 'package:unh_rideshare_app/view/sign_in_screen.dart';
import 'package:unh_rideshare_app/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {

  final String? prefillPhoneNumber;
  final String? unregisteredNumberMessage;

  const SignUpScreen({super.key, this.prefillPhoneNumber, this.unregisteredNumberMessage});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String phoneNumber = '';
  String name = '';
  String message = '';
  String _signUpmessage = 'Enter your name and phone number to create an account';
  bool checkPhone = true;
  bool _isSending = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.prefillPhoneNumber != null) {
      phoneNumberController.text = phoneNumberFormatter(widget.prefillPhoneNumber!);
      _signUpmessage = widget.unregisteredNumberMessage ?? _signUpmessage;
    }
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending) return;
    final enteredName = nameController.text.trim();

    if (enteredName.isEmpty) {
      setState(() {
        checkPhone = false;
        message = 'Please enter your name';
      });
      return;
    }

    final result = PhoneValidator.validate(phoneNumberController.text);

    if (!result.isValid) {
      setState(() {
        checkPhone = false;
        message = result.errorMessage ?? PhoneValidator.errorText;
      });
      return;
    }

    final String fullNumber = result.phoneWithCountryCode!;

    setState(() {
      _isSending = true;
      checkPhone = true;
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
                name: enteredName,
                phoneNumber: fullNumber,
                verificationId: verificationId,
                confirmationResult: confirmationResult,
                isSignUpFlow: true,
              ),
            ),
          );
        },
        onError: (code, msg) {
          if (!mounted) return;

          setState(() {
            _isSending = false;
            checkPhone = false;
            message = msg.isEmpty ? code : '$code: $msg';
          });
        },
      );
  }

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
                  Text(
                    'Sign Up',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    spacing: 20,
                    children: [
                      Text(
                        _signUpmessage,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person),
                          hintText: 'Enter Name',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (_) {
                          if (message.isEmpty) return;
                          setState(() {
                            message = '';
                            checkPhone = true;
                          });
                        },
                      ),
                      TextField(
                        controller: phoneNumberController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.phone),
                          hintText: 'Enter Phone Number',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        inputFormatters: [_phoneNumberFormatter()],
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (message.isEmpty) return;
                          setState(() {
                            message = '';
                            checkPhone = true;
                          });
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 0, 27, 67),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Send Code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: checkPhone
                              ? Colors.green[500]
                              : Colors.red[300],
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          );
                        },
                        child: const Text("Already have an account? Sign In"),
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
