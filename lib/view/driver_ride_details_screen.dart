import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/view/canceled_ride_details_screen.dart';
import 'package:unh_rideshare_app/view/cancel_ride_screen.dart';
import 'package:unh_rideshare_app/widgets/manage_ride_request_widget.dart';
import 'package:unh_rideshare_app/widgets/ride_card.dart';

class DriverRideDetailsScreen extends StatelessWidget {
  const DriverRideDetailsScreen({
    super.key,
    required this.ride,
    this.fromMyRideRequests = false,
    this.fromPastRequestsList = false,
    this.requestStatus, // This is optional and only needed if fromMyRideRequests is true to determine which actions to show
  });

  final RideModel ride; // The ride details to display on this screen
  final bool
  fromMyRideRequests; // Indicates if this screen is accessed from the My Ride Requests list
  final bool fromPastRequestsList;
  final String? requestStatus;

  // Helper method to determine if the Cancel Request button should be hidden based on the request status
  bool get _hideRequestCancelButton {
    if (!fromMyRideRequests) {
      return false;
    }

    if (fromPastRequestsList) {
      return true;
    }

    if (requestStatus == null) {
      return true;
    }

    // Normalize the request status string to handle different cases and whitespace
    final normalizedStatus = requestStatus?.toLowerCase().trim();
    if (normalizedStatus == null || normalizedStatus.isEmpty) {
      return true;
    }

    return normalizedStatus == 'rejected' ||
        normalizedStatus == 'declined' ||
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'canceled';
  }

  // Helper method to check if an accepted booking is being cancelled within 12 hours of departure
  bool _isWithinTwelveHoursOfDeparture() {
    try {
      final departureDate = ride.departureDate.trim();
      final departureTime = ride.departureTime.trim();

      if (departureDate.isEmpty || departureTime.isEmpty) {
        return false;
      }

      DateTime? departureDateTime;

      final twentyFourHourMatch = RegExp(
        r'^(\d{1,2}):(\d{2})$',
      ).firstMatch(departureTime);

      if (twentyFourHourMatch != null) {
        final hour = int.parse(twentyFourHourMatch.group(1)!);
        final minute = int.parse(twentyFourHourMatch.group(2)!);
        departureDateTime = DateTime.parse(departureDate).copyWith(
          hour: hour,
          minute: minute,
        );
      } else {
        final twelveHourMatch = RegExp(
          r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
          caseSensitive: false,
        ).firstMatch(departureTime);

        if (twelveHourMatch == null) {
          return false;
        }

        var hour = int.parse(twelveHourMatch.group(1)!);
        final minute = int.parse(twelveHourMatch.group(2)!);
        final period = twelveHourMatch.group(3)!.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        departureDateTime = DateTime.parse(departureDate).copyWith(
          hour: hour,
          minute: minute,
        );
      }

      final difference = departureDateTime.difference(DateTime.now());
      return !difference.isNegative && difference.inHours < 12;
    } catch (_) {
      return false;
    }
  }

  // Helper method to show a confirmation dialog before cancelling a ride request
  Future<void> _showCancelRequestDialog(BuildContext context) async {
    final rideService = RideService();
    final normalizedStatus = requestStatus?.toLowerCase().trim();
    final isAcceptedBooking =
        normalizedStatus == RideService.requestAcceptedStatus;
    final dialogTitle = isAcceptedBooking ? 'Cancel Booking' : 'Cancel Request';
    final isLateCancellation =
        isAcceptedBooking && _isWithinTwelveHoursOfDeparture();
    final dialogContent = isLateCancellation
        ? 'This ride is within 12 hours of departure. Are you sure you want to cancel this booking?'
        : isAcceptedBooking
        ? 'Are you sure you want to cancel this booking?'
        : 'Are you sure you want to cancel this ride request?';
    final confirmLabel = isAcceptedBooking
        ? 'Yes, Cancel Booking'
        : 'Yes, Cancel Request';
    final successMessage = isAcceptedBooking
        ? 'Booking cancelled.'
        : 'Ride request cancelled.';

    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    // If the user cancels the dialog or chooses not to cancel the request, do nothing
    if (shouldCancel != true || !context.mounted) return;

    try {
      if (normalizedStatus == RideService.requestAcceptedStatus) {
        await rideService.cancelAcceptedBooking(ride.rideId);
      } else {
        await rideService.cancelPendingRequest(ride.rideId);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              RideCard(
                ride: ride,
              ), // Display the ride details using the RideCard widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // Display the ride status and other relevant information in a card
                child: Card(
                  color: UNHColorsPalette.freshSnow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ride Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${ride.status}'),
                        Text(
                          'Booked Seats: ${ride.totalSeats - ride.availableSeats} / ${ride.totalSeats}',
                        ),
                        Text('Ride ID: ${ride.rideId}'),
                      ],
                    ),
                  ),
                ),
              ),

              // Show the Cancel Request button if this screen is accessed from the My Ride Requests list
              //and the request is not already rejected/declined
              if (!_hideRequestCancelButton)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // Rounded corners for the button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // On press, navigate to the Cancel a Ride screen
                    onPressed: () async {
                      if (fromMyRideRequests) {
                        await _showCancelRequestDialog(context);
                        return;
                      }

                      final cancelResult = await CancelRideScreen.open(
                        context,
                        ride: ride,
                      );
                      // If the cancellation flow did not return a confirmed cancelled ride, do nothing.
                      if (!context.mounted ||
                          cancelResult?.didCancel != true ||
                          cancelResult?.cancelledRide == null) {
                        return;
                      }
                      final cancelledRide = cancelResult!.cancelledRide!;
                      // After successfully cancelling the ride, navigate to the Canceled Ride Details screen to show the cancellation details
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CanceledRideDetailsScreen(ride: cancelledRide),
                        ),
                      );
                    },
                    child: Text(
                      // Change the button label based on whether we're coming from the My Ride Requests list and the request status
                      fromMyRideRequests
                          ? ((requestStatus?.toLowerCase().trim() ==
                                    RideService.requestAcceptedStatus)
                                ? 'Cancel Booking'
                                : 'Cancel Request')
                          : 'Cancel This Ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UNHColorsPalette.freshSnow,
                      ),
                    ),
                  ),
                ),

              fromMyRideRequests == false
                  ? Column(
                      spacing: 20,
                      children: [
                        Divider(
                          color: UNHColorsPalette.graniteGray,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        Text(
                          'Ride Requests',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: UNHColorsPalette.graniteGray,
                          ),
                        ),
                        // Show the ManageRideRequestWidget to allow the driver to manage incoming ride requests for this ride
                        ManageRideRequestWidget(
                          rideId: ride.rideId,
                          rideAvailableSeats: ride.availableSeats,
                        ),
                        SizedBox(height: 30), // Widget to manage ride requests
                      ],
                    )
                  : SizedBox.shrink(), // If not from My Ride Requests, don't show the ride requests section
              // Widget to manage ride requests
            ],
          ),
        ),
      ),
    );
  }
}
