import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/theme/colors.dart';

class RideCalendarView extends StatefulWidget {
  final Function(List<RideModel>, DateTime) onCellTap;
  final Future<List<RideModel>> rides;
  const RideCalendarView({super.key, required this.rides, required this.onCellTap});

  @override
  State<RideCalendarView> createState() => _RideCalendarViewState();
}

class _RideCalendarViewState extends State<RideCalendarView> {
  late Future<List<RideModel>> _rides;

  void _handleOnCellTap(List<CalendarEventData<RideModel>> events, DateTime date) {
    widget.onCellTap(events.map((event) => event.event!).toList(), date);
  }

  @override
  void initState() {
    super.initState();
    _rides = widget.rides;
  }

  @override
  void didUpdateWidget(covariant RideCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rides != widget.rides) {
      setState(() {
        _rides = widget.rides;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RideModel>>(
      future: _rides,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final rides = snapshot.data ?? [];
        final eventController = EventController<RideModel>();

        for (var ride in rides) {
          try {
            final dateParts = ride.departureDate.split('-');
            final timeParts = ride.departureTime.split(':');

            if (dateParts.length == 3 && timeParts.length == 2) {
              final date = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
              );

              eventController.add(
                CalendarEventData<RideModel>(
                  date: date,
                  title: "${ride.availableSeats} seats",
                  event: ride,
                  startTime: date,
                  endTime: date.add(const Duration(hours: 1)),
                ),
              );
            }
          } catch (e) {
            debugPrint("Error parsing date/time for ride ${ride.rideId}: $e");
          }
        }

        return Scaffold(
          body: CalendarControllerProvider<RideModel>(
            controller: eventController,
            child: SafeArea(
              child: MonthView<RideModel>(
                controller: eventController,
                cellBuilder:
                    (date, events, isToday, isInMonth, hideDaysNotInMonth) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? UNHColorsPalette.seacoastBlue.withAlpha(50)
                              : UNHColorsPalette.freshSnow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: UNHColorsPalette.graniteGray.withAlpha(50),
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isToday
                                      ? UNHColorsPalette.thermosphereBlue
                                      : (isInMonth
                                            ? UNHColorsPalette.unhWildcatBlue
                                            : UNHColorsPalette.graniteGray.withAlpha(100)),
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (events.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    final event = events[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: UNHColorsPalette.seacoastBlue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(
                                          color: UNHColorsPalette.freshSnow,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                minMonth: DateTime.now(),
                maxMonth: DateTime.now().add(const Duration(days: 90)),
                initialMonth: DateTime.now(),
                onCellTap: _handleOnCellTap,
                startDay: WeekDays.sunday,
                showWeekTileBorder: false,
                headerStringBuilder: (date, {secondaryDate}) {
                  const months = [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ];
                  return '${months[date.month - 1]} ${date.year}';
                },
                useAvailableVerticalSpace: true,
                hideDaysNotInMonth: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
