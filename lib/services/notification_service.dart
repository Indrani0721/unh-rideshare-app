import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/view/ride_details_screen.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for foreground notification alerts.',
    importance: Importance.high,
  );

  bool _foregroundListenerRegistered = false;
  bool _localNotificationsInitialized = false;

  Future<void> initialize() async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _saveTokenForCurrentUser();
    _listenForTokenRefresh();
    _registerForegroundHandler();
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: RideService().getRideById(payload),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data is RideModel) {
                    return RideDetailsScreen(ride: snapshot.data as RideModel);
                  } else {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                },
              ),
            ),
          );
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _localNotificationsInitialized = true;
  }
// Add a global navigator key for navigation from notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  void registerOnMessageOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      final rideId = message.data['rideId'];
      if (rideId != null && rideId.isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => FutureBuilder(
              future: RideService().getRideById(rideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return RideDetailsScreen(ride: snapshot.data!);
                } else {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
              },
            ),
          ),
        );
      }
    });
  }

  Future<void> _saveTokenForCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    final token = await _messaging.getToken();

    if (uid != null && token != null) {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return;

      await _db.collection('users').doc(currentUid).set({
        'fcmToken': newToken,
      }, SetOptions(merge: true));
    });
  }

  void _registerForegroundHandler() {
    if (_foregroundListenerRegistered) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Notification',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for foreground notification alerts.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data['rideId'],
      );
    });

    _foregroundListenerRegistered = true;
  }
}
