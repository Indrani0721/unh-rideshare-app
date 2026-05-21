import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/main_navigation.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/ride_card.dart';
import '../services/ride_service.dart';



class OfferRideConfirmationScreen extends StatefulWidget {
  final RideModel ride;
  final DateTime departureDate;
  final DateTime departureTime;

  const OfferRideConfirmationScreen({
    super.key,
    required this.ride,
    required this.departureDate,
    required this.departureTime,
    }
  );
  @override
  State<OfferRideConfirmationScreen> createState() => _OfferRideConfirmationScreenState();
}

class _OfferRideConfirmationScreenState
    extends State<OfferRideConfirmationScreen> {
  final RideService _rideService = RideService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final RideModel ride = widget.ride;

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Confirmation')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Ride details summary
                RideCard(ride: ride),
                const SizedBox(height: 50),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Please review your ride information details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                // Confirm button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UNHColorsPalette.unhWildcatBlue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : () async {
                    if (_isSubmitting) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await _rideService.createRideFromModel(
                        ride: widget.ride,
                        departureDate: widget.departureDate,
                        departureTime: widget.departureTime,
                      );

                      if(!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ride posted successfully!')),
                      );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainNavigationScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to post ride: $e')),
                      );
                      setState(() => _isSubmitting = false);
                    }
                  },
                  child: Text(_isSubmitting ? 'Posting...' :
                    'Confirm Ride',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: UNHColorsPalette.freshSnow,
                    ),
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
