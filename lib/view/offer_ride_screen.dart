import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/utils/formatter.dart';
import 'package:unh_rideshare_app/services/vehicle_service.dart';
import 'package:unh_rideshare_app/view/offer_ride_confirmation_screen.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/models/car_model.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';

enum RouteOption { manchesterToDurham, durhamToManchester }

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {

  final VehicleService _vehicleService = VehicleService();
  final RideService _rideService = RideService();

  late Future<List<CarModel>> _currentUserVihicleList;

  final _rideOfferFormKey = GlobalKey<FormState>();
  RouteOption? _selectedRoute = RouteOption.manchesterToDurham;
  DateTime _departureDate = DateTime.now();
  DateTime _departureTime = (DateTime.now()
      .add(Duration(hours: 2))
      .subtract(Duration(minutes: DateTime.now().minute % 10)));
  int _availableSeats = 1;
  CarModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _currentUserVihicleList = _vehicleService.getVehiclesForCurrentUser();
    _currentUserVihicleList.then((vehicles) {
    if (!mounted) return;

    if (vehicles.isNotEmpty) {
      setState(() {
        _selectedVehicle = vehicles.first;
      });
    }
  });
}

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (pickedDate == null) return;
    setState(() {
      _departureDate = pickedDate;
    });
  }

  Future<void> _showTimePicker() async {
    // Open the picker
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: UNHColorsPalette.freshSnow,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            minuteInterval: 10,

            // Get the initial time rounded to the nearest 10 minutes and at least 2 hours from now
            initialDateTime: _departureTime,

            onDateTimeChanged: (DateTime newTime) {
              setState(() {
                _departureTime = newTime;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: UNHColorsPalette.freshSnow),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Offer a Ride',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: UNHColorsPalette.freshSnow,
          ),
        ),
        backgroundColor: UNHColorsPalette.unhWildcatBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Form(
              key: _rideOfferFormKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 30,
                  children: [
                    // Route input options (Durham -> Manchester | Manchester -> Durham)
                    Column(
                      spacing: 8,
                      children: [
                        Text(
                          'Select Route',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: UNHColorsPalette.unhWildcatBlue,
                          ),
                        ),
                        SegmentedButton<RouteOption>(
                          direction: Axis.vertical,
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            foregroundColor: UNHColorsPalette.unhWildcatBlue,
                            backgroundColor: UNHColorsPalette.freshSnow,
                            selectedBackgroundColor:
                                UNHColorsPalette.unhWildcatBlue,
                            selectedForegroundColor: UNHColorsPalette.freshSnow,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 25,
                            ),
                            textStyle: TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          segments: [
                            ButtonSegment(
                              value: RouteOption.manchesterToDurham,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 8,
                                children: [
                                  Icon(Icons.drive_eta),
                                  Text('Manchester'),
                                  Icon(Icons.arrow_right_alt),
                                  Icon(Icons.location_pin),
                                  Text('Durham'),
                                ],
                              ),
                            ),
                            ButtonSegment(
                              value: RouteOption.durhamToManchester,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 8,
                                children: [
                                  Icon(Icons.location_pin),
                                  Text('Manchester'),
                                  Transform.scale(
                                    scaleX: -1,
                                    child: Icon(Icons.arrow_right_alt),
                                  ),
                                  Icon(Icons.drive_eta),
                                  Text('Durham'),
                                ],
                              ),
                            ),
                          ],
                          selected: {_selectedRoute!},
                          onSelectionChanged: (newSelectedRoute) {
                            setState(() {
                              _selectedRoute = newSelectedRoute.first;
                            });
                          },
                        ),
                      ],
                    ),
                    // Date & time picker input
                    Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            onTap: _selectDate,
                            decoration: InputDecoration(
                              labelText: 'Pickup Date',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              filled: true,
                              fillColor: UNHColorsPalette.freshSnow,
                              focusColor: UNHColorsPalette.unhWildcatBlue,
                              hintText: dateFormatter(_departureDate),
                              suffixIcon: Icon(Icons.calendar_month_sharp),
                              suffixIconColor: UNHColorsPalette.unhWildcatBlue,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: UNHColorsPalette.unhWildcatBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Time picker input with 30-minute increments (ex: 12pm | 12:30pm | 1pm)
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            onTap: _showTimePicker,
                            decoration: InputDecoration(
                              labelText: 'Pickup Time',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              filled: true,
                              fillColor: UNHColorsPalette.freshSnow,
                              focusColor: UNHColorsPalette.unhWildcatBlue,
                              hintText: timeFormatter(_departureTime, 10),
                              suffixIcon: Icon(Icons.access_time_sharp),
                              suffixIconColor: UNHColorsPalette.unhWildcatBlue,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Select car dropdown input
                    FutureBuilder(
                      future: _currentUserVihicleList,
                      builder: (context, asyncSnapshot) {
                        // While loading vehicles, show a disabled dropdown with a loading indicator
                        if (asyncSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        // If error loading vehicles, show a disabled dropdown with an error message
                        if (asyncSnapshot.hasError) {
                          return Text(
                            'Error loading vehicles',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        final vehicles = asyncSnapshot.data;
                        if (vehicles == null || vehicles.isEmpty) {
                          return Text(
                            'No vehicles available. Please add a vehicle before offering a ride.',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        return DropdownButtonFormField<CarModel>(
                          initialValue: vehicles.first,
                          isExpanded: true,
                          items: vehicles
                              .map(
                                (vehicle) => DropdownMenuItem<CarModel>(
                                  value: vehicle,
                                  child: Text(
                                    '${vehicle.year} ${vehicle.make} ${vehicle.model} (${vehicle.color}) - ${vehicle.licensePlate}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (CarModel? selectedVehicle) {
                            setState(() {
                              _selectedVehicle = selectedVehicle!;
                            });
                          },
                          dropdownColor: UNHColorsPalette.freshSnow,
                          decoration: InputDecoration(
                            labelText: 'Select Car',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            filled: true,
                            fillColor: UNHColorsPalette.freshSnow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: UNHColorsPalette.unhWildcatBlue,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Available seat number input
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Available Seats',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: UNHColorsPalette.freshSnow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: UNHColorsPalette.unhWildcatBlue,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 32,
                        children: [
                          IconButton(
                            onPressed: _availableSeats > 1
                                ? () {
                                    setState(() {
                                      _availableSeats--;
                                    });
                                  }
                                : null,
                            icon: Icon(Icons.remove_circle, size: 25),
                            color: UNHColorsPalette.unhWildcatBlue,
                            disabledColor: Colors.grey.shade300,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          Expanded(
                            child: Text(
                              '$_availableSeats',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: UNHColorsPalette.unhWildcatBlue,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _availableSeats < 4
                                ? () {
                                    setState(() {
                                      _availableSeats++;
                                    });
                                  }
                                : null,
                            icon: Icon(Icons.add_circle, size: 25),
                            color: UNHColorsPalette.unhWildcatBlue,
                            disabledColor: Colors.grey.shade300,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Submit button
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UNHColorsPalette.unhWildcatBlue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (!_rideOfferFormKey.currentState!.validate()) return;

                        try {
                          final hasCompleteVehicle = await _vehicleService
                              .isAnyVehicleCompleteForCurrentUser();

                          if (!context.mounted) return;

                          if (!hasCompleteVehicle) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Add and complete vehicle details before offering a ride.',
                                ),
                              ),
                            );
                            return;
                          }
                          final routeText =
                              _selectedRoute == RouteOption.manchesterToDurham
                              ? 'Manchester to Durham'
                              : 'Durham to Manchester';

                          final pendingRide = RideModel(
                            rideId: '',
                            driverId: _rideService.getCurrentUserId(),
                            vehicleId: _selectedVehicle?.vehicleId ?? '',
                            departureDate:
                                '${_departureDate.year.toString().padLeft(4, '0')}-'
                                '${_departureDate.month.toString().padLeft(2, '0')}-'
                                '${_departureDate.day.toString().padLeft(2, '0')}',
                            departureTime:
                                '${_departureTime.hour.toString().padLeft(2, '0')}:'
                                '${_departureTime.minute.toString().padLeft(2, '0')}',
                            totalSeats: _availableSeats,
                            availableSeats: _availableSeats,
                            routeDetails: routeText,
                            status: RideService.activeStatus,
                            createdTime: null,
                            vehicle: _selectedVehicle,
                          );
                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfferRideConfirmationScreen(
                                ride: pendingRide,
                                departureDate: _departureDate,
                                departureTime: _departureTime,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vehicle check failed: $e')),
                          );
                        }
                      },
                      child: Text(
                        'Submit Ride',
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
        ),
      ),
    );
  }
}
