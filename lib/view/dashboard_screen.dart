import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unh_rideshare_app/models/user_model.dart';
import 'package:unh_rideshare_app/services/vehicle_service.dart';
import 'package:unh_rideshare_app/view/offer_ride_screen.dart';
import 'package:unh_rideshare_app/view/add_car_screen.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/dashboard_card_widget.dart';
import 'package:unh_rideshare_app/widgets/my_ride_requests_bottom_sheet.dart';
import 'package:unh_rideshare_app/widgets/offered_rides_bottom_sheet.dart';
import 'package:unh_rideshare_app/widgets/request_departure_placeholder_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RideService _rideService = RideService();
  // Vehicle service is needed to check if the user has added any vehicles before allowing them to offer a ride
  final VehicleService _vehicleService = VehicleService();

  // Helper function to load the counts of offered rides, ride requests, and accepted requests for the current user
  Future<
    ({
      List<RideModel> offeredRides,
      int requestCount,
      int acceptedRequestCount,
      int pastRequestCount,
    })
  >
  // This function fetches the offered rides and ride requests for the current user, and calculates the counts needed for the dashboard cards
  _loadDashboardCounts() async {
    final offeredRides = await _rideService
        .getRidesForCurrentUserWithVehicles();
    final requestRows = await _rideService
        .getRideRequestsForCurrentUserWithRideDetails();
    // Count the number of accepted requests by filtering the request rows based on their status
    final acceptedRequestCount = requestRows.where((row) {
      final requestStatus =
          ((row[RideService.requestStatusField] as String?) ?? '')
              .trim()
              .toLowerCase();
      if (requestStatus != 'accepted') {
        return false;
      }

      return !RequestDeparturePlaceholderHelper.isPastDeparture(
        departureDate: ((row[RideService.departureDateField] as String?) ?? '')
            .trim(),
        departureTime: ((row[RideService.departureTimeField] as String?) ?? '')
            .trim(),
      );
    }).length;

    final requestCount = requestRows.where((row) {
      final requestStatus =
          ((row[RideService.requestStatusField] as String?) ?? '')
              .trim()
              .toLowerCase();
      final isPastRequest = RequestDeparturePlaceholderHelper.isPastDeparture(
        departureDate: ((row[RideService.departureDateField] as String?) ?? '')
            .trim(),
        departureTime: ((row[RideService.departureTimeField] as String?) ?? '')
            .trim(),
      );
      // Exclude past accepted requests from the request count if the filter option is enabled
      if (requestStatus == 'accepted') {
        return false;
      }

      if (isPastRequest && requestStatus == 'pending') {
        return false;
      }

      return true;
    }).length;

    final pastRequestCount = requestRows.where((row) {
      final requestStatus =
          ((row[RideService.requestStatusField] as String?) ?? '')
              .trim()
              .toLowerCase();
      final isAcceptedOrPending =
          requestStatus == 'accepted' || requestStatus == 'pending';

      if (!isAcceptedOrPending) {
        return false;
      }

      return RequestDeparturePlaceholderHelper.isPastDeparture(
        departureDate: ((row[RideService.departureDateField] as String?) ?? '')
            .trim(),
        departureTime: ((row[RideService.departureTimeField] as String?) ?? '')
            .trim(),
      );
    }).length;

    return (
      offeredRides: offeredRides,
      requestCount: requestCount,
      acceptedRequestCount: acceptedRequestCount,
      pastRequestCount: pastRequestCount,
    );
  }

  void _showOfferedRidesBottomSheet() {
    showOfferedRidesBottomSheet(context: context, rideService: _rideService);
  }

  void _showMyRideRequestsBottomSheet() {
    showMyRideRequestsBottomSheet(
      context: context,
      excludePastAcceptedAndPending: true,
      onRequestsUpdated: () {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  // Function to show the bottom sheet with the list of upcoming rides for the current user
  void _showUpcomingRideBottomSheet() {
    showMyRideRequestsBottomSheet(
      context: context,
      initialRequestFilter: 'accepted',
      showFilterControls: false,
      includeAcceptedRequests: true,
      excludePastAcceptedAndPending: true,
      title: 'Upcoming Ride',
      // When the user updates their requests (e.g., cancels an accepted ride)
      onRequestsUpdated: () {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  void _showPastRequestsBottomSheet() {
    showMyRideRequestsBottomSheet(
      context: context,
      showFilterControls: false,
      includeAcceptedRequests: true,
      showOnlyPastRequests: true,
      title: 'Past Requests',
      onRequestsUpdated: () {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  // When the user presses the "Offer Rides" button, check if they have any vehicles added to their profile.
  Future<void> _handleOfferRidePressed() async {
    try {
      final vehicles = await _vehicleService.getVehiclesForCurrentUser();

      if (!mounted) return;
      // If the user has at least one vehicle, navigate them directly to the Offer Ride screen
      if (vehicles.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OfferRideScreen()),
        );
        return;
      }
      // If the user has no vehicles, navigate them to the Vehicle Details screen
      final addedVehicle = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => AddCarScreen()),
      );

      if (!mounted) return;
      // If the user added a vehicle, navigate them to the Offer Ride screen, otherwise they can stay on the dashboard and add a vehicle later
      if (addedVehicle == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OfferRideScreen()),
        );
      }
      // If there was an error checking for vehicles, show a snackbar message to the user
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to check your added cars right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();

    return Scaffold(
      // App bar with title
      appBar: AppBar(
        title: Text(
          "${user?.name}'s Dashboard",
          style: const TextStyle(
            color: Color.fromARGB(255, 0, 27, 67),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Body with welcome message
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Spacing from app bar
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Row with 2 cards: Canceled Rides and Offered Rides,
                  //each showing the number of rides in that category
                  FutureBuilder<
                    ({
                      List<RideModel> offeredRides,
                      int requestCount,
                      int acceptedRequestCount,
                      int pastRequestCount,
                    })
                  >(
                    // Load the counts for the dashboard cards when the screen is built
                    future: _loadDashboardCounts(),
                    builder: (context, snapshot) {
                      // Show loading indicators while fetching rides, and handle error states
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                // Show the Ride Requests card with a loading indicator
                                buildDashBoardCard(
                                  title: 'Ride Requests',
                                  cardColor: Colors.orange,
                                  onTap: _showMyRideRequestsBottomSheet,
                                  body: const SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Show the Offered Rides card with a loading indicator
                                buildDashBoardCard(
                                  title: 'Offered Rides',
                                  cardColor: UNHColorsPalette.seacoastBlue,
                                  onTap: _showOfferedRidesBottomSheet,
                                  body: const SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildDashBoardCard(
                                  title: 'Upcoming Ride',
                                  cardColor: UNHColorsPalette.forestGreen,
                                  onTap: _showUpcomingRideBottomSheet,
                                  body: const SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                buildDashBoardCard(
                                  title: 'Past Requests',
                                  cardColor: UNHColorsPalette.graniteGray,
                                  onTap: _showPastRequestsBottomSheet,
                                  body: const SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      // Handle error state when fetching rides
                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                buildDashBoardCard(
                                  title: 'Ride Requests',
                                  cardColor: Colors.orange,
                                  onTap: _showMyRideRequestsBottomSheet,
                                  body: const Text(
                                    '--',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                buildDashBoardCard(
                                  title: 'Offered Rides',
                                  cardColor: UNHColorsPalette.seacoastBlue,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unable to load offered rides right now.',
                                        ),
                                      ),
                                    );
                                  },
                                  // Show an error message in the body of the card when rides fail to load
                                  body: const Text(
                                    '--',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildDashBoardCard(
                                  title: 'Upcoming Ride',
                                  cardColor: UNHColorsPalette.forestGreen,
                                  onTap: _showUpcomingRideBottomSheet,
                                  body: const Text(
                                    '--',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                buildDashBoardCard(
                                  title: 'Past Requests',
                                  cardColor: UNHColorsPalette.graniteGray,
                                  onTap: _showPastRequestsBottomSheet,
                                  body: const Text(
                                    '--',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      final counts = snapshot.data;
                      final offeredRides =
                          counts?.offeredRides ?? const <RideModel>[];
                      final requestCount = counts?.requestCount ?? 0;
                      final acceptedRequestCount =
                          counts?.acceptedRequestCount ?? 0;
                      final pastRequestCount = counts?.pastRequestCount ?? 0;

                      // Build the dashboard cards with the fetched counts for ride requests, offered rides, and upcoming rides
                      return Column(
                        children: [
                          Row(
                            children: [
                              // Build the card for rides that have incoming requests
                              buildDashBoardCard(
                                title: 'Ride Requests',
                                itemCount: requestCount,
                                cardColor: Colors.orange,
                                onTap: _showMyRideRequestsBottomSheet,
                              ),
                              const SizedBox(width: 8),
                              // Build the card for offered rides with the count of offered rides
                              buildDashBoardCard(
                                title: 'Offered Rides',
                                itemCount: offeredRides.length,
                                cardColor: UNHColorsPalette.seacoastBlue,
                                onTap: _showOfferedRidesBottomSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              buildDashBoardCard(
                                title: 'Upcoming Ride',
                                itemCount: acceptedRequestCount,
                                cardColor: UNHColorsPalette.forestGreen,
                                onTap: _showUpcomingRideBottomSheet,
                              ),
                              const SizedBox(width: 8),
                              buildDashBoardCard(
                                title: 'Past Requests',
                                itemCount: pastRequestCount,
                                cardColor: UNHColorsPalette.graniteGray,
                                onTap: _showPastRequestsBottomSheet,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 150),
            // Section for offering a new ride with a button to navigate to the offer ride screen
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Ready to offer a new ride?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UNHColorsPalette.unhWildcatBlue,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      // When the user presses the "Offer Rides" button,
                      //check if they have any vehicles added to their profile.
                      onPressed: () {
                        _handleOfferRidePressed();
                      },
                      child: const Text(
                        'Offer Rides',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
