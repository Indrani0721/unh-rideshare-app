import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';

// A class to represent the result of the cancellation process,
//indicating whether the ride was cancelled and providing the updated cancelled ride details if applicable
class CancelRideResult {
  const CancelRideResult._({required this.didCancel, this.cancelledRide});

  const CancelRideResult.cancelled(RideModel ride)
    : this._(didCancel: true, cancelledRide: ride);

  final bool didCancel;
  final RideModel? cancelledRide;
}

class CancelRideScreen extends StatefulWidget {
  const CancelRideScreen({super.key, required this.ride});

  final RideModel ride;

  // Static method to open the CancelRideScreen and return a CancelRideResult when the user finishes the cancellation process
  static Future<CancelRideResult?> open(
    BuildContext context, {
    required RideModel ride,
  }) {
    return Navigator.push<CancelRideResult>(
      context,
      MaterialPageRoute<CancelRideResult>(
        builder: (context) => CancelRideScreen(ride: ride),
      ),
    );
  }

  @override
  State<CancelRideScreen> createState() => _CancelRideScreenState();
}

class _CancelRideScreenState extends State<CancelRideScreen> {
  static const List<String> _reasons = [
    'Emergency',
    'Schedule Change',
    'Vehicle Issue',
    'Other',
  ];
  final RideService _rideService = RideService();
  bool _isCancelling = false;

  // Default to the first reason in the list when the screen is initialized
  String _selectedReason = _reasons.first;
  // Controller for the "Other" reason text field, allowing users to specify a custom reason if they select "Other"
  final TextEditingController _otherReasonController = TextEditingController();

  @override
  // Dispose the text controller when the widget is removed from the widget tree to free up resources
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  String _getFinalCancelReason() {
    if (_selectedReason == 'Other') {
      return _otherReasonController.text.trim();
    }
    return _selectedReason;
  }

  // Show a confirmation dialog when the user attempts to cancel the ride
  Future<void> _showCancellationConfirmationDialog() async {
    final cancelReason = _getFinalCancelReason();
    final affectedPassengers = widget.ride.enrolledUserIds.length;
    if (cancelReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cancellation reason.')),
      );
      return;
    }
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: Text(
            'Warning: $affectedPassengers passengers will be affected by this cancellation.\n\nDo you want to continue?',
          ),
          actions: [
            // Button to go back without canceling the ride
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Go Back'),
            ),

            // Button to confirm the cancellation of the ride
            // When pressed, it will close the dialog and return true to indicate that the user confirmed the cancellation
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    // If the user did not confirm the cancellation (i.e., they pressed "Go Back" or dismissed the dialog),
    //return early and do not proceed with cancelling the ride
    if (shouldCancel != true || !mounted) return;
    setState(() {
      _isCancelling = true;
    });

    // Attempt to cancel the ride using the RideService, passing the ride ID and the cancellation reason
    try {
      await _rideService.cancelRide(
        rideId: widget.ride.rideId,
        cancelReason: cancelReason,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride cancelled successfully.')),
      );
      // Return an updated canceled ride so the caller can route to canceled details.
      Navigator.pop<CancelRideResult>(
        context,
        CancelRideResult.cancelled(
          widget.ride.copyWith(
            status: RideService
                .cancelledStatus, // Update the ride status to "cancelled" after successful cancellation
            cancelReason: cancelReason,
            cancelledAt: Timestamp.now(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // If an error occurs during the cancellation process,
      //display a SnackBar with the error message to inform the user about the issue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel a Ride')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 35),

              // add cancellation reason dropdown, and typed input here
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  initialValue:
                      _selectedReason, // Set the initial value of the dropdown to the currently selected reason
                  decoration: const InputDecoration(
                    labelText: 'Cancellation Reason',
                    border: OutlineInputBorder(),
                  ),

                  // Map the list of reasons to DropdownMenuItem widgets to populate the dropdown menu
                  items: _reasons
                      .map(
                        (reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      // Convert the list of reasons into a list of DropdownMenuItem widgets for the dropdown menu
                      .toList(),
                  // Update the selected reason when the user selects a different option from the dropdown menu
                  onChanged: _isCancelling
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedReason = value;
                            // If the user selects a reason other than "Other",
                            //clear the text field for the custom reason
                            if (_selectedReason != 'Other') {
                              _otherReasonController.clear();
                            }
                          });
                        },
                ),
              ),
              // If the user selects "Other" as the cancellation reason, display a text field
              if (_selectedReason == 'Other') ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  // Text field for the user to type custom cancellation reason
                  child: TextField(
                    controller: _otherReasonController,
                    enabled: !_isCancelling,
                    decoration: const InputDecoration(
                      labelText: 'Type your reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
              const SizedBox(height: 150),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                // Display a confirmation message in a card,
                child: Card(
                  color: UNHColorsPalette.freshSnow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Are you sure you want to cancel this ride?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This action cannot be undone. All booked passengers will be notified.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                // Button to cancel ride
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // If the cancellation process is currently in progress,
                  //disable the button to prevent multiple cancellation attempts
                  onPressed: _isCancelling
                      ? null
                      : () {
                          _showCancellationConfirmationDialog();
                        },
                  child: Text(
                    _isCancelling ? 'Cancelling...' : 'Cancel',
                    style: const TextStyle(
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
