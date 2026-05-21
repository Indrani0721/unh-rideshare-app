import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/services/user_profile_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;

  const RideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: UNHColorsPalette.freshSnow,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 80,
                child: (ride.vehicle?.vehiclePhotoUrl != null &&
                        ride.vehicle!.vehiclePhotoUrl!.isNotEmpty)
                    ? Image.network(
                        ride.vehicle!.vehiclePhotoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.directions_car, size: 50);
                        },
                      )
                    : const Icon(Icons.directions_car, size: 50),
              ),
              Divider(height: 30),
              // Route
              Text(
                ride.routeDetails,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Departure time
              Text(
                ride.departureTime,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              // Departure date
              Text(
                ride.departureDate,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              // Available seats
              Divider(height: 30),
              Text(
                '${ride.availableSeats} Seats Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Divider(height: 30),
              // Driver and car details
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: UNHColorsPalette.unhWildcatBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Driver:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Spacer(),
                  FutureBuilder<String?>(
                    future: UserProfileService().getUserName(ride.driverId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading...');
                      } else if (snapshot.hasError) {
                        return Text('Error');
                      } else {
                        return Text(snapshot.data ?? 'Unknown');
                      }
                    },
                  ),
                ],
              ),
              /*
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: UNHColorsPalette.unhWildcatBlue,
                  ),
                  const SizedBox(width: 4),
                  Text('Phone:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Spacer(),
                  Text(ride.driverId),
                ],
              ),
              */
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 16,
                    color: UNHColorsPalette.unhWildcatBlue,
                  ),
                  const SizedBox(width: 4),
                  Text('Car:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Spacer(),
                  Text(
                    ride.vehicle != null
                        ? '${ride.vehicle!.color} - ${ride.vehicle!.make} ${ride.vehicle!.model}'
                        : 'Selected vehicle',
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: UNHColorsPalette.unhWildcatBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'License Plate:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Spacer(),
                  Text(ride.vehicle != null ? ride.vehicle!.licensePlate : '-'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
