import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/services/user_profile_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/utils/formatter.dart';
import 'package:unh_rideshare_app/view/ride_details_screen.dart';
import 'package:unh_rideshare_app/widgets/ride_direction_widget.dart';

class RideItemWidget extends StatelessWidget {
  const RideItemWidget({super.key, required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final vehiclePhotoUrl = ride.vehicle?.vehiclePhotoUrl;
    return Card(
      color: UNHColorsPalette.freshSnow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to ride details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsScreen(ride: ride),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route details
            ride.routeDetails == 'Manchester to Durham'
                ? RouteDirectionWidget(
                    direction: RouteDirection.manchesterToDurham,
                  )
                : RouteDirectionWidget(
                    direction: RouteDirection.durhamToManchester,
                  ),
            // Departure time and date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 10,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (vehiclePhotoUrl != null && vehiclePhotoUrl.isNotEmpty)
                        ? Image.network(
                            vehiclePhotoUrl,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.directions_car,
                              size: 80,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.grey,
                          ),
                  ),
                  SizedBox(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRIVER:',
                          style: TextStyle(fontSize: 7, color: Colors.grey),
                        ),
                        FutureBuilder<String?>(
                          future: UserProfileService().getUserName(
                            ride.driverId,
                          ),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'Loading...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        Text(
                          'AVAILABLE SEATS:',
                          style: TextStyle(fontSize: 7, color: Colors.grey),
                        ),
                        Text(
                          '${ride.availableSeats}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ride.departureDate,
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            timeFormatter(
                              DateFormat("HH:mm").parse(ride.departureTime),
                            ),
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
