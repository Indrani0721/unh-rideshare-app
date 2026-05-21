import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:unh_rideshare_app/models/ride_request_model.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/status_badge_widget.dart';
import 'package:unh_rideshare_app/widgets/user_info_widget.dart';

class ManageRideRequestWidget extends StatefulWidget {
  const ManageRideRequestWidget({
    super.key,
    required this.rideId,
    required this.rideAvailableSeats,
  });

  final String rideId;
  final int rideAvailableSeats;

  @override
  State<ManageRideRequestWidget> createState() =>
      _ManageRideRequestScreenState();
}

class _ManageRideRequestScreenState extends State<ManageRideRequestWidget> {
  final RideService _rideService = RideService();

  int availableSeats = 0;

  List<RideRequestModel> _requests = [];
  bool _isLoading = true;
  String? _error;

  Future<bool> _confirmReject(BuildContext context, String userId) async {
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: UNHColorsPalette.freshSnow,
          title: const Text('Decline Request?'),
          content: Text('Are you sure you want to decline rider?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );

    return shouldReject ?? false;
  }

  void _handleRequestAction(String requestId, String action, int index) async {
    try {
      // Call the service to accept or decline the request
      if (action == 'accepted') {
        await _rideService.acceptRideRequest(
          rideId: widget.rideId,
          requestId: requestId,
        );
        setState(() {
          availableSeats = availableSeats - 1;
        });
      } else if (action == 'declined') {
        await _rideService.declineRideRequest(
          rideId: widget.rideId,
          requestId: requestId,
        );
      }

      // Refresh the requests list
      await _loadRequests();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request $action.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Helper to convert RideRequestStatus to BadgeType
  BadgeType _getBadgeType(RideRequestStatus status) {
    switch (status) {
      case RideRequestStatus.pending:
        return BadgeType.pending;
      case RideRequestStatus.accepted:
        return BadgeType.accepted;
      case RideRequestStatus.declined:
        return BadgeType.declined;
      case RideRequestStatus.cancelled:
        return BadgeType.cancelled;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
    availableSeats = widget.rideAvailableSeats;
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await _rideService.getRequestsForRide(widget.rideId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('Failed to load requests: $_error')),
      );
    }

    if (_requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: const Center(child: Text('No ride requests yet.')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return Slidable(
          key: ValueKey(request.requestId),
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            children: [
              CustomSlidableAction(
                autoClose: true,
                backgroundColor: Colors.transparent,
                onPressed:
                    request.status == RideRequestStatus.pending &&
                        availableSeats > 0
                    ? (_) => _handleRequestAction(
                        request.requestId,
                        'accepted',
                        index,
                      )
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(
                      request.status == RideRequestStatus.pending &&
                              availableSeats > 0
                          ? 255
                          : 100,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            children: [
              CustomSlidableAction(
                backgroundColor: Colors.transparent,
                onPressed: (_) => request.status == RideRequestStatus.pending
                    ? _confirmReject(context, request.passengerId).then((
                        shouldReject,
                      ) {
                        if (shouldReject) {
                          _handleRequestAction(
                            request.requestId,
                            'declined',
                            index,
                          );
                        }
                      })
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(
                      request.status == RideRequestStatus.pending ? 255 : 100,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Icon(Icons.close, color: Colors.white),
                      Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: StatusBadgeWidget(
              badgeType: _getBadgeType(request.status),
              child: UserInfoWidget(userId: request.passengerId),
            ),
          ),
        );
      },
    );
  }
}
