import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/view/sign_in_screen.dart';
import 'package:unh_rideshare_app/view/sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  // build the welcome screen with UNH logo, title, and buttons
  Widget build(BuildContext context) {
    // responsive spacing based on screen height to prevent overflow on smaller devices
    final screenHeight = MediaQuery.of(context).size.height;

    final topSpacing = screenHeight < 700 ? 20.0 : 40.0; // space above the logo
    // space between sections (logo, title, buttons)
    final sectionSpacing = screenHeight < 700 ? 24.0 : 40.0;
    final contentSpacing = screenHeight < 700 ? 20.0 : 30.0;
    final buttonMaxWidth = 360.0;

    return Scaffold(
      // background color
      backgroundColor: Color.fromARGB(255, 245, 244, 236),
      body: SafeArea(
        // make the welcome screen scrollable to prevent overflow on smaller devices
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Center(
              child: Column(
                spacing: sectionSpacing, // space between logo and text
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: topSpacing),

                  // add UNH logo here
                  SizedBox(
                    height: screenHeight < 700 ? 120 : 150,
                    child: Image.asset(
                      'assets/images/UNH_RideShare.png',
                      fit: BoxFit.fitHeight,
                    ),
                  ),

                  SizedBox(
                    height: sectionSpacing,
                  ), // space between logo and text

                  Column(
                    spacing: contentSpacing, // space between text and buttons
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // page title
                      const Text(
                        'Welcome To\nUNH RideShare App!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 27, 67),
                          height: 1.25,
                        ),
                      ),

                      SizedBox(
                        height: sectionSpacing,
                      ), // space between title and buttons

                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // login button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      0,
                                      27,
                                      67,
                                    ),
                                    foregroundColor: const Color.fromARGB(
                                      255,
                                      245,
                                      244,
                                      236,
                                    ),

                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Navigate to login screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignInScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // sign up button
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 0, 27, 67),
                                      width: 3,
                                    ),
                                    foregroundColor: const Color.fromARGB(
                                      255,
                                      0,
                                      27,
                                      67,
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Navigate to sign up screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      //const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
