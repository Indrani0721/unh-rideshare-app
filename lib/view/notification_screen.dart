import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'dart:async';
import 'package:unh_rideshare_app/view/driver_ride_details_screen.dart';
import 'package:unh_rideshare_app/view/canceled_ride_details_screen.dart';
import 'package:unh_rideshare_app/widgets/my_ride_requests_bottom_sheet.dart';
import 'package:unh_rideshare_app/view/ride_details_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final RideService _rideService = RideService();
  Timer? _timeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _timeRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timeRefreshTimer?.cancel();
    super.dispose();
  }

  String _formatTimeLabel(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final createdAt = timestamp.toDate();
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';

    return '${diff.inDays}d ago';
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final type = (data['type'] ?? '').toString();
    final rideId = (data[RideService.requestRideIdField] ?? '').toString();
    if (type == 'ride_reminder') {
      final reminderRideId = (data['rideId'] ?? '').toString();

      if (reminderRideId.isEmpty) {
        _showNotificationMessage('Ride details are not available.');
        return;
      }

      try {
        final ride = await _rideService.getRideById(reminderRideId);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (ride.status == RideService.cancelledStatus) {
                return CanceledRideDetailsScreen(ride: ride);
              }

              if (ride.driverId == _rideService.getCurrentUserId()) {
                return DriverRideDetailsScreen(ride: ride);
              }

              return RideDetailsScreen(ride: ride);
            },
          ),
        );
      } catch (_) {
        if (!mounted) return;
        _showNotificationMessage('Unable to open this ride right now.');
      }

      return;
    }
    if (type == RideService.rideRequestAcceptedType) {
      showMyRideRequestsBottomSheet(
        context: context,
        initialRequestFilter: RideService.requestAcceptedStatus,
        showFilterControls: false,
        includeAcceptedRequests: true,
        excludePastAcceptedAndPending: true,
        title: 'Upcoming Ride',
      );
      return;
    }

    if (type == RideService.rideRequestDeclinedType ||
        type == RideService.rideCancelledType) {
      showMyRideRequestsBottomSheet(
        context: context,
        excludePastAcceptedAndPending: true,
      );
      return;
    }

    if (type == RideService.rideRequestCreatedType ||
        type == RideService.rideBookingCancelledType) {
      if (rideId.isEmpty) {
        _showNotificationMessage('Ride details are not available.');
        return;
      }

      try {
        final ride = await _rideService.getRideById(rideId);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (ride.status == RideService.cancelledStatus) {
                return CanceledRideDetailsScreen(ride: ride);
              }

              return DriverRideDetailsScreen(ride: ride);
            },
          ),
        );
      } catch (_) {
        if (!mounted) return;
        _showNotificationMessage('Unable to open this ride right now.');
      }

      return;
    }

    _showNotificationMessage(
      (data['message'] ?? 'No notification details available.').toString(),
    );
  }

  void _showNotificationMessage(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification Details'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      // Body of the screen to display notifications or a placeholder message
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _rideService.getNotificationsForCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No notifications yet'));
            }
            final docs = snapshot.data!.docs;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final title = (data['title'] ?? 'Notification').toString();
                final message = (data['message'] ?? '').toString();
                final isRead = (data['isRead'] as bool?) ?? false;
                final createdAt = data['createdAt'] as Timestamp?;
                final timeLabel = _formatTimeLabel(createdAt);

                // Each notification is displayed in a card with an icon, title, message, and time label
                return Card(
                  color: UNHColorsPalette.freshSnow,
                  child: ListTile(
                    leading: Icon(
                      // Icon changes based on whether the notification has been read or not
                      isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: isRead
                          ? UNHColorsPalette.graniteGray
                          : UNHColorsPalette.unhWildcatBlue,
                    ),
                    // Display the notification title,
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      timeLabel,
                      style: TextStyle(color: UNHColorsPalette.graniteGray),
                    ),
                    // Handle tap on the notification to show a popup with detailed information
                    onTap: () async {
                      // Show a dialog with the notification details when tapped
                      showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Notification Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Title: $title'),
                                const SizedBox(height: 8),
                                Text('Message: $message'),
                                const SizedBox(height: 8),
                                if (data['cancelReason'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Reason: ${data['cancelReason']}'),
                                ],
                                const SizedBox(height: 8),
                                Text('Time: $timeLabel'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleNotificationTap(data);
                                },
                                child: const Text('View Details'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
