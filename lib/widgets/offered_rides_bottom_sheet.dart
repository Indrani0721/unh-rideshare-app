import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/view/canceled_ride_details_screen.dart';
import 'package:unh_rideshare_app/view/driver_ride_details_screen.dart';
import 'package:unh_rideshare_app/utils/ride_departure_helper.dart';
import 'package:unh_rideshare_app/widgets/ride_status_badge_widget.dart';

// Helper function to determine if a ride is cancelled based on its status
bool _isCancelledRide(RideModel ride) {
  return ride.status == RideService.cancelledStatus ||
      ride.status.toLowerCase() == 'canceled';
}

// Helper function to determine if a ride is in the past based on its departure date and time compared to the current date and time
bool _isPastRide(RideModel ride) {
  if (_isCancelledRide(ride)) {
    return false;
  }
  return RideDepartureHelper.isPastRide(ride);
}

// Helper function to determine the badge type for an offered ride based on its status
BadgeType? _badgeForOfferedRide(RideModel ride) {
  if (_isCancelledRide(ride)) {
    return BadgeType.cancelled;
  }

  if (_isPastRide(ride)) {
    return BadgeType.pastRide;
  }
  return null;
}

// Function to show the bottom sheet with the list of offered rides for the current user
void showOfferedRidesBottomSheet({
  required BuildContext context,
  required RideService rideService,
}) {
  String selectedFilter = 'All';
  // Fetch the rides for the current user when the bottom sheet is opened
  final ridesFuture = rideService.getRidesForCurrentUserWithVehicles();

  // Show a modal bottom sheet that takes up most of the screen height
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.96,
        child: Container(
          decoration: BoxDecoration(
            color: UNHColorsPalette.freshSnow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: StatefulBuilder(
            builder: (context, setBottomSheetState) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Offered Rides',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // The rest of the bottom sheet content will go here, such as the list of offered rides and filter options
                  Expanded(
                    child: FutureBuilder<List<RideModel>>(
                      future: ridesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Error loading rides: ${snapshot.error}',
                              ),
                            ),
                          );
                        }
                        // Filter the rides based on the selected filter (All, Active, Cancelled, Past Rides)
                        final rides = snapshot.data ?? [];
                        final filteredRides = switch (selectedFilter) {
                          'Active' =>
                            rides
                                .where(
                                  (ride) =>
                                      ride.status == RideService.activeStatus &&
                                      !_isPastRide(ride),
                                )
                                .toList(),
                          'Cancelled' => rides.where(_isCancelledRide).toList(),
                          'Past Rides' => rides.where(_isPastRide).toList(),
                          _ => rides,
                        };

                        if (filteredRides.isEmpty) {
                          return Center(
                            child: Text('No $selectedFilter rides found.'),
                          );
                        }
                        // Build a ListView of the filtered rides, showing a badge for cancelled rides and allowing navigation to details on tap
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredRides.length,
                          itemBuilder: (context, index) {
                            final ride = filteredRides[index];
                            final initialBadgeType = _badgeForOfferedRide(ride);

                            return FutureBuilder<int>(
                              future: rideService.getPendingRequestCountForRide(
                                ride.rideId,
                              ),
                              builder: (context, snapshot) {
                                BadgeType badgeType =
                                    initialBadgeType ?? BadgeType.pending;

                                // If the ride is not cancelled or in the past,
                                // check if there are pending requests to determine if we should show the "Requested" badge
                                if (initialBadgeType == null &&
                                    snapshot.hasData &&
                                    snapshot.data! > 0) {
                                  badgeType = BadgeType.requested;
                                }

                                final offeredRideCard = RideStatusBadgeWidget(
                                  badgeType: badgeType,
                                  requestCount: snapshot.data ?? 0,
                                  showBadge: badgeType != BadgeType.pending,
                                  ride: ride,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            _isCancelledRide(ride)
                                            ? CanceledRideDetailsScreen(
                                                ride: ride,
                                              )
                                            : DriverRideDetailsScreen(
                                                ride: ride,
                                              ),
                                      ),
                                    );
                                  },
                                );
                                // If the ride has a badge (e.g. cancelled), we add some spacing below it for visual separation
                                return offeredRideCard;
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Filter options using SegmentedButton to allow filtering by All, Active, Cancelled, or Past Rides
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 15, 12, 50),
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(const StadiumBorder()),
                        side: WidgetStateProperty.all(
                          BorderSide(
                            color: UNHColorsPalette.unhWildcatBlue.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return UNHColorsPalette.unhWildcatBlue;
                          }
                          return UNHColorsPalette.freshSnow;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return UNHColorsPalette.unhWildcatBlue;
                        }),
                      ),
                      segments: const [
                        ButtonSegment<String>(value: 'All', label: Text('All')),
                        ButtonSegment<String>(
                          value: 'Active',
                          label: Text('Active'),
                        ),
                        ButtonSegment<String>(
                          value: 'Cancelled',
                          label: Text('Cancelled'),
                        ),
                        ButtonSegment<String>(
                          value: 'Past Rides',
                          label: Text('Past Rides'),
                        ),
                      ],
                      selected: {selectedFilter},
                      onSelectionChanged: (selection) {
                        setBottomSheetState(() {
                          selectedFilter = selection.first;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
