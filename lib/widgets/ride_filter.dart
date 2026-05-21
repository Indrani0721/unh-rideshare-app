import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_filter_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/widgets/weekly_range_selector.dart';

class RideFilter extends StatefulWidget {
  final Function(RideFilterModel filterParams)? onApplyFilters;
  final RideFilterModel? initialFilters;
  const RideFilter({super.key, this.onApplyFilters, this.initialFilters});

  @override
  State<RideFilter> createState() => _RideFilterState();
}

class _RideFilterState extends State<RideFilter> {
  late RideFilterModel _currentFilters;

  void _applyFilters() {
    widget.onApplyFilters?.call(_currentFilters);
  }

  void _handleDateFilterChange(Set<DateFilterType> newSelection) {
    setState(() => _currentFilters.dateFilterType = newSelection);
  }

  void _handleDateSelected(DateTime date) {
    setState(() {
      _currentFilters.selectedDate = date;
    });
  }

  void _handleDateRangeChange(DateTime start, DateTime end) {
    setState(() {
      _currentFilters.rangeStart = start;
      _currentFilters.rangeEnd = end;
    });
  }

  void _handleDayOfWeekChange(Set<DayOfWeek> newSelection) {
    setState(() => _currentFilters.selectedDayOfWeek = newSelection);
  }

  void _handleTimeOfDayChange(Set<String> newSelection) {
    setState(() => _currentFilters.selectedTimeOfDay = newSelection);
  }

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters ?? RideFilterModel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Rides',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              WeeklyRangeSelector(
                focusedMonday: _currentFilters.rangeStart,
                initialDate: _currentFilters.selectedDate,
                dateSelecting: _currentFilters.dateFilterType.contains(
                  DateFilterType.byDate,
                ),
                onDateSelected: _handleDateSelected,
                onRangeChanged: _handleDateRangeChange,
              ),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<DateFilterType>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: DateFilterType.byWeekRange,
                      label: Text('Week Range'),
                    ),
                    ButtonSegment(
                      value: DateFilterType.byDate,
                      label: Text('Specific Date'),
                    ),
                    ButtonSegment(
                      value: DateFilterType.byDayOfWeek,
                      label: Text('Day of Week'),
                    ),
                  ],
                  selected: _currentFilters.dateFilterType,
                  onSelectionChanged: (newSelection) {
                    _handleDateFilterChange(newSelection);
                  },
                ),
              ),
              // Day of week picker
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<DayOfWeek>(
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: List.generate(7, (index) {
                    String dayLabel = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ][index];
                    return ButtonSegment(
                      value: DayOfWeek.values[index],
                      label: Text(dayLabel),
                      enabled: _currentFilters.dateFilterType.contains(
                        DateFilterType.byDayOfWeek,
                      ),
                    );
                  }),
                  selected: _currentFilters.selectedDayOfWeek,
                  onSelectionChanged: (newSelection) {
                    _handleDayOfWeekChange(newSelection);
                  },
                ),
              ),
              // Time of day picker (morning, afternoon, evening) - can be added similarly to the above segmented buttons
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'Morning',
                      label: Text('Morning'),
                      icon: Icon(Icons.wb_sunny_outlined, color: Colors.amber),
                    ),
                    ButtonSegment(
                      value: 'Afternoon',
                      label: Text('Afternoon'),
                      icon: Icon(Icons.cloud_outlined, color: Colors.blueGrey),
                    ),
                    ButtonSegment(
                      value: 'Evening',
                      label: Text('Evening'),
                      icon: Icon(Icons.bedtime_outlined, color: Colors.indigo),
                    ),
                  ],
                  selected: _currentFilters.selectedTimeOfDay,
                  onSelectionChanged: (newSelection) {
                    _handleTimeOfDayChange(newSelection);
                  },
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UNHColorsPalette.unhWildcatBlue,
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: Text(
                  'Search',
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
      ],
    );
  }
}
