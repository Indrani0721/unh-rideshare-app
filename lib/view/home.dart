import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/view/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get userName {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.displayName ?? "User" : "User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 244, 236),
      // app bar with title and logout button
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 27, 67),

        // UNH logo on the left side of the app bar
        leading: Padding(
          padding: const EdgeInsets.all(3.5),
          child: Image.asset('assets/images/UNH_RideShare.png'),
        ),

        // home page title.
        title: const Text(
          'Home Page',
          style: TextStyle(
            color: Color.fromARGB(255, 245, 244, 236),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          // logout button
          IconButton(
            icon: const Icon(Icons.logout),
            style: IconButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 245, 244, 236),
            ),
            onPressed: () async {
              //  logout to welcome screen
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      // body with welcome message and user name, and app logo above the welcome message
      body: Center(
        child: Column(
          spacing: 50,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/UNH_RideShare.png', height: 150),
            const SizedBox(height: 20),

            // welcome message with user name
            Text(
              'Home Screen - Welcome, $userName!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 27, 67),
              ),
            ),

            // button to navigate to dashboard screen
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 0, 27, 67),
                foregroundColor: Color.fromARGB(255, 245, 244, 236),
              ),
              onPressed: () {
                // Navigate to dashboard screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(),
                  ),
                );
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
