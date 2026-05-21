import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/ride_card.dart';

class CanceledRideDetailsScreen extends StatelessWidget {
  const CanceledRideDetailsScreen({
    super.key,
    required this.ride,
    this.fromMyRideRequests = false,
  });

  final RideModel ride;
  final bool fromMyRideRequests;

  // Keep restore action implementation for future release, but hide it in UI for now.
  static const bool _showRestoreRideAction = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canceled Ride Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              RideCard(
                ride: ride,
              ), // Reuse the RideCard widget to display ride details
              const SizedBox(height: 20),
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
              const SizedBox(height: 50),
              // Keep this action hidden for now to avoid exposing unfinished behavior.
              if (_showRestoreRideAction && !fromMyRideRequests)
                // Restore Ride button which would trigger the logic to change the ride status back to active.
                // Note: The actual restore logic is not implemented here and should be handled in the onPressed callback.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UNHColorsPalette.unhWildcatBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    // Placeholder: restore ride logic to be implemented
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Restore Ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UNHColorsPalette.freshSnow,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
