import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/car_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/services/vehicle_service.dart';

class AddedCarDetailsScreen extends StatelessWidget {
  const AddedCarDetailsScreen({super.key, required this.vehicle});

  final CarModel vehicle;
  static final VehicleService vehicleService = VehicleService();
  Widget _buildPhotoSection() {
    final String? carPhotoUrl = vehicle.vehiclePhotoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: carPhotoUrl != null && carPhotoUrl.isNotEmpty
          // Use Image.network to load the car photo from the URL.
          ? Image.network(
              carPhotoUrl,
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              // Show a loading indicator while the image is loading
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  height: 170,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, _, _) => _photoPlaceholder(),
            )
          : _photoPlaceholder(),
    );
  }

  // Placeholder shown when no car photo is available
  // This is a simple grey box with a car icon and text indicating no photo is available.
  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 170,
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('No photo available', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // License plate photo display section.
  Widget _buildLicensePlatePhotoSection() {
    final String? licensePlatePhotoUrl = vehicle.licensePlatePhotoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: licensePlatePhotoUrl != null && licensePlatePhotoUrl.isNotEmpty
          // Use Image.network to load the license plate photo from the URL.
          ? Image.network(
              licensePlatePhotoUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              // Show a loading indicator while the image is loading
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  height: 110,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, _, _) => _licensePlatePlaceholder(),
            )
          : _licensePlatePlaceholder(),
    );
  }

  // Placeholder shown when no license plate photo is available
  Widget _licensePlatePlaceholder() {
    return Container(
      width: double.infinity,
      height: 110,
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pin, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No license plate photo available',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: UNHColorsPalette.unhWildcatBlue),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'My Car Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.normal,
            color: UNHColorsPalette.unhWildcatBlue,
          ),
        ),
        backgroundColor: UNHColorsPalette.parchmentWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                // Display the car details in a card
                child: Card(
                  color: UNHColorsPalette.freshSnow,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car photo display section
                        _buildPhotoSection(),
                        // Car make, model, year, and color details
                        Column(
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 25,
                                  color: UNHColorsPalette.unhWildcatBlue,
                                ),
                                Text(
                                  '${vehicle.make} ${vehicle.model} - ${vehicle.year}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 8,
                              children: [
                                Icon(
                                  Icons.color_lens,
                                  size: 25,
                                  color: UNHColorsPalette.unhWildcatBlue,
                                ),
                                Text(
                                  vehicle.color,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 8,
                              children: [
                                Icon(
                                  Icons.confirmation_num,
                                  size: 25,
                                  color: UNHColorsPalette.unhWildcatBlue,
                                ),
                                Text(
                                  vehicle.licensePlate,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // License plate photo display section
                        _buildLicensePlatePhotoSection(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Vehicle'),
                        content: const Text(
                          'Are you sure you want to delete this vehicle?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;
                    try {
                      await vehicleService.deleteVehicleSafely(
                        vehicleId: vehicle.vehicleId,
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vehicle deleted successfully.'),
                        ),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;

                      final message = e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      );

                      if (message.contains('upcoming active rides')) {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cannot Delete Vehicle'),
                            content: const Text(
                              'This vehicle is assigned to one or more upcoming active rides. '
                              'Cancel those rides before deleting this vehicle.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    }
                  },
                  child: const Text(
                    'Delete This Car',
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
