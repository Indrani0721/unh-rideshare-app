import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_filter_model.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/services/ride_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/ride_calendar_view.dart';
import 'package:unh_rideshare_app/widgets/ride_filter.dart';
import 'package:unh_rideshare_app/widgets/ride_list_view.dart';

enum ViewType { list, calendar }

class AvailableRideScreen extends StatefulWidget {
  const AvailableRideScreen({super.key});

  @override
  State<AvailableRideScreen> createState() => _AvailableRideScreenState();
}

class _AvailableRideScreenState extends State<AvailableRideScreen> {
  final RideService _rideService = RideService();
  final RideFilterModel _currentFilters = RideFilterModel();
  late Future<List<RideModel>> _rides;
  late Future<List<RideModel>> _ridesSubList;

  int _viewIndex = 0;

  void _handleOnCalendarCellTap(List<RideModel> rides, DateTime date) {
    setState(() {
      _ridesSubList = Future.value(rides);
      _viewIndex = 0;
      _currentFilters.dateFilterType = {DateFilterType.byDate};
      _currentFilters.selectedDate = date;
    });
  }

  void _fetchRides([RideFilterModel? filterParams]) {
    Future<List<RideModel>> ridesResponse;
    DateTime? startDate;
    DateTime? endDate;

    if (filterParams != null && filterParams.dateFilterType.isNotEmpty) {
      if (filterParams.dateFilterType.contains(DateFilterType.byDate)) {
        startDate = filterParams.selectedDate;
        endDate = filterParams.selectedDate;
      } else {
        startDate = filterParams.rangeStart;
        endDate = filterParams.rangeEnd;
      }
      ridesResponse = _rideService.getAvailableRidesWithVehicles(
        startDate: startDate,
        endDate: endDate,
        selectedDaysOfWeek: filterParams.dateFilterType.contains(
              DateFilterType.byDayOfWeek,
            )
            ? filterParams.selectedDayOfWeek
            : <DayOfWeek>{},
        selectedTimesOfDay: filterParams.selectedTimeOfDay,
      );
    } else {
      ridesResponse = _rideService.getAvailableRidesWithVehicles(
        selectedDaysOfWeek: _currentFilters.dateFilterType.contains(
              DateFilterType.byDayOfWeek,
            )
            ? _currentFilters.selectedDayOfWeek
            : <DayOfWeek>{},
        selectedTimesOfDay: _currentFilters.selectedTimeOfDay,
      );
    }

    setState(() {
      _rides = ridesResponse;
      _ridesSubList = ridesResponse;
    });
  }

  void _handleApplyFilters(RideFilterModel appliedFilters) {
    _fetchRides(appliedFilters);
    setState(() {
      _currentFilters
        ..selectedDate = appliedFilters.selectedDate
        ..rangeStart = appliedFilters.rangeStart
        ..rangeEnd = appliedFilters.rangeEnd
        ..dateFilterType = appliedFilters.dateFilterType
        ..selectedDayOfWeek = appliedFilters.selectedDayOfWeek
        ..selectedTimeOfDay = appliedFilters.selectedTimeOfDay;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchRides();
    _ridesSubList = _rides;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: _viewIndex == 1 ? UNHColorsPalette.unhWildcatBlue : null,
            ),
            onPressed: () => setState(() => _viewIndex = 1),
          ),
          IconButton(
            icon: Icon(
              Icons.list,
              color: _viewIndex == 0 ? UNHColorsPalette.unhWildcatBlue : null,
            ),
            onPressed: () {
              setState(() {
                _ridesSubList = _rides;
                _viewIndex = 0;
              });
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _viewIndex,
        children: [
          RefreshIndicator(
            onRefresh: () async => _fetchRides(_currentFilters),
            child: RideListView(rides: _ridesSubList),
          ),
          RideCalendarView(rides: _rides, onCellTap: _handleOnCalendarCellTap),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        onPressed: () {
          showModalBottomSheet(
            useSafeArea: true,
            isScrollControlled: true,
            context: context,
            builder: (context) => RideFilter(
              initialFilters: _currentFilters,
              onApplyFilters: _handleApplyFilters,
            ),
          );
        },
        child: Icon(Icons.filter_list_alt, color: UNHColorsPalette.freshSnow),
      ),
    );
  }
}
