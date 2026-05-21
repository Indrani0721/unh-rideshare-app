import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/view/canceled_ride_details_screen.dart';
import 'package:unh_rideshare_app/view/driver_ride_details_screen.dart';
import 'package:unh_rideshare_app/widgets/request_departure_placeholder_helper.dart';
import 'package:unh_rideshare_app/widgets/ride_status_badge_widget.dart';

// Helper function to determine if a ride is cancelled based on its status
bool _isCancelledRide(RideModel ride) {
  return ride.status == RideService.cancelledStatus ||
      ride.status.toLowerCase() == 'canceled';
}

// Helper function to determine the badge type for a ride request based on its status
BadgeType? _statusStringToBadgeType(String statusString) {
  final normalizedStatus = statusString.toLowerCase().trim();
  switch (normalizedStatus) {
    case 'pending':
      return BadgeType.pending;
    case 'accepted':
      return BadgeType.accepted;
    case RideService.requestCancelledStatus:
    case 'canceled':
      return BadgeType.cancelled;
    case 'declined':
    case 'rejected':
      return BadgeType.rejected;
    default:
      return null;
  }
}

// Helper function to determine the badge type for a ride request based on its status and cancellation
BadgeType? _badgeForMyRideRequest(RideModel ride, String? requestStatus) {
  if (_isCancelledRide(ride)) {
    return BadgeType.cancelled;
  }
  if (requestStatus == null) {
    return null;
  }
  return _statusStringToBadgeType(requestStatus);
}

// Helper function to determine the sort order for request status badges
int _requestStatusSortOrder(BadgeType? badgeType) {
  switch (badgeType) {
    case BadgeType.pending:
      return 1;
    case BadgeType.cancelled:
      return 2;
    case BadgeType.rejected:
      return 3;
    case BadgeType.accepted:
      return 4;
    default:
      return 5;
  }
}

// Helper function to determine if a ride request is for a past ride
//based on the departure date and time, and return the appropriate badge type
BadgeType? _displayBadgeTypeForMyRideRequest({
  required BadgeType? baseBadgeType,
  required bool isPastRequest,
}) {
  // If the request is for a past ride and the base badge type is accepted or pending, show the past ride badge instead
  final shouldShowPastRideBadge =
      isPastRequest &&
      (baseBadgeType == BadgeType.accepted ||
          baseBadgeType == BadgeType.pending);

  if (shouldShowPastRideBadge) {
    return BadgeType.pastRide;
  }

  return baseBadgeType;
}

// Helper function to convert a Firestore document row into a RideModel instance
RideModel _rideFromRequestRow(Map<String, dynamic> row) {
  return RideModel(
    rideId: (row[RideService.requestRideIdField] as String? ?? '').trim(),
    driverId: (row[RideService.requestDriverIdField] as String? ?? '').trim(),
    vehicleId: (row[RideService.vehicleIdField] as String? ?? '').trim(),
    departureDate: (row[RideService.departureDateField] as String? ?? '')
        .trim(),
    departureTime: (row[RideService.departureTimeField] as String? ?? '')
        .trim(),
    totalSeats: (row[RideService.totalSeatsField] as num?)?.toInt() ?? 0,
    availableSeats:
        (row[RideService.availableSeatsField] as num?)?.toInt() ?? 0,
    routeDetails: (row[RideService.routeDetailsField] as String? ?? '').trim(),
    status: (row['rideStatus'] as String? ?? '').trim(),
    createdTime: row[RideService.createdTimeField] as Timestamp?,
    cancelReason: (row[RideService.cancelReasonField] as String? ?? '').trim(),
    cancelledAt: row[RideService.cancelledAtField] as Timestamp?,
    enrolledUserIds: List<String>.from(
      row[RideService.enrolledUserIdsField] ?? const <String>[],
    ),
  );
}

// Function to show the bottom sheet with the list of ride requests made by the current user,
// allowing filtering by request status and showing badges for each request
void showMyRideRequestsBottomSheet({
  required BuildContext context,
  VoidCallback? onRequestsUpdated,
  String initialRequestFilter = 'All',
  bool showFilterControls = true,
  bool includeAcceptedRequests = false,
  bool showOnlyPastRequests = false,
  bool excludePastAcceptedAndPending = false,
  String title = 'My Ride Requests',
}) {
  // Define the valid filter options based on whether accepted requests should be included, and ensure the initial filter is valid
  final validFilters = {
    'All',
    if (includeAcceptedRequests) 'accepted',
    'pending',
    'rejected',
    'cancelled',
  };
  String selectedRequestFilter = validFilters.contains(initialRequestFilter)
      ? initialRequestFilter
      : 'All';
  final rideService = RideService();

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
                        Expanded(
                          child: Text(
                            title,
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
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: rideService
                          .getRideRequestsForCurrentUserWithRideDetails(),
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
                                'Error loading ride requests: ${snapshot.error}',
                              ),
                            ),
                          );
                        }

                        final requestRows = snapshot.data ?? [];
                        final filteredRows = requestRows.where((row) {
                          final ride = _rideFromRequestRow(row);
                          final requestStatus =
                              (row[RideService.requestStatusField] as String?)
                                  ?.trim();
                          final baseBadgeType = _badgeForMyRideRequest(
                            ride,
                            requestStatus,
                          );
                          // Determine if the request is for a past ride based on the departure date and time,
                          final isPastRequest =
                              RequestDeparturePlaceholderHelper.isPastDeparture(
                                departureDate: ride.departureDate,
                                departureTime: ride.departureTime,
                              );
                          // Apply filtering based on the selected filter option,
                          //whether to exclude past accepted and pending requests, and whether to show only past requests
                          if (excludePastAcceptedAndPending && isPastRequest) {
                            final isPastAcceptedOrPending =
                                baseBadgeType == BadgeType.accepted ||
                                baseBadgeType == BadgeType.pending;
                            if (isPastAcceptedOrPending) {
                              return false;
                            }
                          }

                          if (showOnlyPastRequests) {
                            if (!isPastRequest) {
                              return false;
                            }

                            final isAcceptedOrPending =
                                baseBadgeType == BadgeType.accepted ||
                                baseBadgeType == BadgeType.pending;
                            if (!isAcceptedOrPending) {
                              return false;
                            }
                          }

                          if (!includeAcceptedRequests &&
                              baseBadgeType == BadgeType.accepted) {
                            return false;
                          }
                          return switch (selectedRequestFilter) {
                            'accepted' => baseBadgeType == BadgeType.accepted,
                            'pending' => baseBadgeType == BadgeType.pending,
                            'rejected' => baseBadgeType == BadgeType.rejected,
                            'cancelled' => baseBadgeType == BadgeType.cancelled,
                            _ => true,
                          };
                        }).toList();

                        if (selectedRequestFilter == 'All') {
                          filteredRows.sort((a, b) {
                            final rideA = _rideFromRequestRow(a);
                            final rideB = _rideFromRequestRow(b);
                            final statusA =
                                (a[RideService.requestStatusField] as String?)
                                    ?.trim();
                            final statusB =
                                (b[RideService.requestStatusField] as String?)
                                    ?.trim();
                            final badgeA = _badgeForMyRideRequest(
                              rideA,
                              statusA,
                            );
                            final badgeB = _badgeForMyRideRequest(
                              rideB,
                              statusB,
                            );
                            return _requestStatusSortOrder(
                              badgeA,
                            ).compareTo(_requestStatusSortOrder(badgeB));
                          });
                        }

                        if (filteredRows.isEmpty) {
                          return Center(
                            child: Text(
                              'No $selectedRequestFilter ride requests found.',
                            ),
                          );
                        }
                        // Build a ListView of the filtered ride requests, showing a badge for each request and allowing navigation to details on tap
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredRows.length,
                          itemBuilder: (context, index) {
                            final requestRow = filteredRows[index];
                            final ride = _rideFromRequestRow(requestRow);
                            final requestStatus =
                                (requestRow[RideService.requestStatusField]
                                        as String?)
                                    ?.trim();
                            final baseBadgeType = _badgeForMyRideRequest(
                              ride,
                              requestStatus,
                            );
                            // Determine if the request is for a past ride based on the departure date and time,
                            // show a "Past Ride" badge if it's a past ride with an accepted or pending status
                            final isPastRequest =
                                RequestDeparturePlaceholderHelper.isPastDeparture(
                                  departureDate: ride.departureDate,
                                  departureTime: ride.departureTime,
                                );
                            // Determine the final badge type to display, showing "Past Ride" badge
                            final displayBadgeType =
                                _displayBadgeTypeForMyRideRequest(
                                  baseBadgeType: baseBadgeType,
                                  isPastRequest: isPastRequest,
                                );

                            final requestCard = RideStatusBadgeWidget(
                              badgeType: displayBadgeType ?? BadgeType.pending,
                              showBadge: displayBadgeType != null,
                              ride: ride,
                              onTap: () async {
                                // Navigate to the appropriate details screen based on whether the ride is cancelled or not, and await a result indicating if the requests were updated
                                final didUpdateRequests = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _isCancelledRide(ride)
                                        ? CanceledRideDetailsScreen(
                                            ride: ride,
                                            fromMyRideRequests: true,
                                          )
                                        : DriverRideDetailsScreen(
                                            ride: ride,
                                            // Indicate that we're coming from the My Ride Requests list
                                            fromMyRideRequests: true,
                                            fromPastRequestsList:
                                                showOnlyPastRequests,
                                            // Pass the request status to the details screen so it can show the appropriate badge and determine which actions to show
                                            requestStatus: requestStatus,
                                          ),
                                  ),
                                );
                                // If the details screen indicates that the requests were updated (e.g. a request was cancelled),
                                //call the onRequestsUpdated callback to refresh the list in the bottom sheet
                                if (didUpdateRequests == true) {
                                  onRequestsUpdated?.call();
                                }
                              },
                            );

                            return displayBadgeType == null
                                ? requestCard
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: requestCard,
                                  );
                          },
                        );
                      },
                    ),
                  ),
                  if (showFilterControls)
                    // Filter options using SegmentedButton to allow filtering by All, Accepted, Pending, or Rejected requests
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 15, 12, 50),
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(const StadiumBorder()),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 12),
                          ),
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
                        segments: [
                          ButtonSegment<String>(
                            value: 'All',
                            label: Text('All'),
                          ),
                          // Only include the 'Accepted' filter option if includeAcceptedRequests is true
                          if (includeAcceptedRequests)
                            const ButtonSegment<String>(
                              value: 'accepted',
                              label: Text('accepted'),
                            ),
                          ButtonSegment<String>(
                            value: 'pending',
                            label: Text('pending'),
                          ),
                          ButtonSegment<String>(
                            value: 'rejected',
                            label: Text('rejected'),
                          ),
                          ButtonSegment<String>(
                            value: 'cancelled',
                            label: Text('cancelled'),
                          ),
                        ],
                        selected: {selectedRequestFilter},
                        onSelectionChanged: (selection) {
                          setBottomSheetState(() {
                            selectedRequestFilter = selection.first;
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
