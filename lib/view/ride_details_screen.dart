import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/ride_card.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';

class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final RideService _rideService = RideService();
  bool _isLoading = false;
  bool _isStatusLoading = true;
  String? _requestStatus;

  @override
  void initState() {
    super.initState();
    _loadRequestStatus();
  }

  Future<void> _loadRequestStatus() async {
    try {
      final status = await _rideService.getCurrentUserRideRequestStatus(
        widget.ride.rideId,
      );
      if (!mounted) return;
      setState(() {
        _requestStatus = status;
        _isStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isStatusLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final RideModel ride = widget.ride;
    final bool hasNoSeats = ride.availableSeats <= 0;
    final bool hasPendingRequest = _requestStatus == RideService.requestPendingStatus;
    final bool isButtonDisabled = _isLoading || _isStatusLoading || hasNoSeats || hasPendingRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Ride details summary
                RideCard(ride: ride),
                SizedBox(height: 50),

                // Request seat button
                if (_requestStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Chip(
                      label: Text('Request: ${_requestStatus![0].toUpperCase()}${_requestStatus!.substring(1)}'),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UNHColorsPalette.unhWildcatBlue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context);
                          setState(() => _isLoading = true);

                          try {
                            await _rideService.submitRideRequest(ride.rideId);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Seat request sent successfully.'),
                              ),
                            );

                            setState(() {
                              _requestStatus = RideService.requestPendingStatus;
                            });

            
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (mounted) {
                              
                              setState(() => _isLoading = false);
                            }
                          }
                    },
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(
                        hasNoSeats ? 'No Seats Available' : 'Request Seat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UNHColorsPalette.freshSnow,
                    ),
                  ),
                ),
                if (_requestStatus == RideService.requestPendingStatus)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _isLoading = true);
                              try {
                                await _rideService.cancelPendingRequest(ride.rideId);
                                if (!mounted) return;
                                setState(() => _requestStatus = RideService.requestCancelledStatus);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Pending request cancelled.')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                      child: const Text('Cancel Pending Request'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
