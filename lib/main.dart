import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:unh_rideshare_app/models/car_model.dart';
import 'package:unh_rideshare_app/models/user_model.dart';
import 'package:unh_rideshare_app/view/welcome_screen.dart';
import 'package:unh_rideshare_app/main_navigation.dart';
import 'package:unh_rideshare_app/services/notification_service.dart';

import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveFcmTokenToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
    {'fcmToken': fcmToken},
    SetOptions(merge: true),
  );
}

void setupFcmTokenListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': newToken},
      SetOptions(merge: true),
    );
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint('Firebase Poject: ${Firebase.app().options.projectId}');
  debugPrint('IOS App ID: ${Firebase.app().options.appId}');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Save FCM token after login (if user is logged in)
  if (FirebaseAuth.instance.currentUser != null) {
    await saveFcmTokenToFirestore();
  }
  setupFcmTokenListener();

  // Register notification tap handler
  NotificationService().registerOnMessageOpenedAppHandler();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // This one provider handles both Auth and Firestore data
        StreamProvider<UserModel?>(
          initialData: null,
          create: (context) {
            return FirebaseAuth.instance.authStateChanges().asyncExpand((
              firebaseUser,
            ) {
              debugPrint('AUTH STATE USER: ${firebaseUser?.uid}');
              debugPrint('AUTH STATE PHONE: ${firebaseUser?.phoneNumber}');
              if (firebaseUser == null) {
                debugPrint('Auth state NULL , returning null stream');
                return Stream.value(null);
              }
              debugPrint('STARTING USER DOC STREAM FOR UID: ${firebaseUser.uid}');

              // 1. Listen to the User Document
              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser.uid)
                  .snapshots()
                  .asyncMap((userSnap) async {
                    debugPrint('READING USER DOC: ${firebaseUser.uid}');
                    debugPrint('USER DOC DATA: ${userSnap.exists}');
                    if (!userSnap.exists){
                      debugPrint('USER DOC MISSING');
                      return null;
                    }

                    final userData = userSnap.data()!;
                    List<CarModel> cars = [];

                    try{

                      // 2. MANUALLY fetch the vehicles subcollection
                      debugPrint('READING VECHILES..');
                      final vehicleSnap = await userSnap.reference
                          .collection('vehicles')
                          .get();
                      debugPrint('VEHICLES COUNT: ${vehicleSnap.docs.length}');

                      // 3. Map the subcollection docs into CarModel objects
                      cars = vehicleSnap.docs
                          .map((doc) => CarModel.fromDoc(doc))
                          .toList();
                    } catch (e) {
                      debugPrint('Failed to load vechiles: $e');
                    }

                    // 4. Return the combined UserModel
                    final userModel = UserModel(
                      userId: userSnap.id,
                      name: userData['name'] ?? '',
                      phone: userData['phoneNumber'] ?? '',
                      profilePhotoUrl: userData['profilePhotoUrl'] as String?,
                      rideReminderEnabled: userData['rideReminderEnabled'] as bool? ?? true,
                      rideReminderMinutes: userData['rideReminderMinutes'] as int? ?? 60,
                      cars: cars, // Now this list is populated!
                    );
                    debugPrint('RETURNNG USERMODEL for UID: ${userModel.userId}');
                    return userModel;
                  })
              .handleError((error) {
                debugPrint('USER STREAM ERROR: $error');
              });
        })
        .handleError((error) {
          debugPrint('AUTH STREAM ERROR: $error');
        });
  },
),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UNH RideShare',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 245, 244, 236),
          ),
        ),
        navigatorKey: NotificationService().navigatorKey,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    debugPrint('AuthGate privider user: ${user?.userId}');
    debugPrint('AuthGate firebase currentUser: ${FirebaseAuth.instance.currentUser?.uid}');

    // If the stream is null, they aren't logged in (or we are still loading)
    if (user == null) {
      return const WelcomeScreen();
    }

    return const MainNavigationScreen();
  }
}