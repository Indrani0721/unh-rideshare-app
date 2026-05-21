import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unh_rideshare_app/theme/colors.dart';

class WeeklyRangeSelector extends StatefulWidget {
  final Function(DateTime selectedDate)? onDateSelected;
  final Function(DateTime start, DateTime end)? onRangeChanged;
  final bool allowPast;
  final bool dateSelecting;
  final DateTime initialDate;
  final DateTime? focusedMonday;

  const WeeklyRangeSelector({
    super.key,
    this.onDateSelected,
    this.onRangeChanged,
    this.allowPast = false,
    this.dateSelecting = false,
    required this.initialDate,
    this.focusedMonday,
  });

  @override
  State<WeeklyRangeSelector> createState() => _WeeklyRangeSelectorState();
}

class _WeeklyRangeSelectorState extends State<WeeklyRangeSelector> {
  late DateTime _focusedMonday;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonday = _getMonday(widget.focusedMonday ?? DateTime.now());
    _selectedDate = widget.initialDate;
    // Initial report of the range
    _reportRange();
  }

  void _handleSlectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDateSelected?.call(date);
      }
    });
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _reportRange() {
    if (widget.onRangeChanged != null) {
      DateTime sunday = _focusedMonday.add(const Duration(days: 6));
      DateTime today = DateTime.now();
      if (!widget.allowPast &&
          today.isAfter(_focusedMonday) &&
          today.isBefore(sunday)) {
        // Wrap the callback in a post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onRangeChanged!(
              DateUtils.dateOnly(today),
              DateUtils.dateOnly(sunday),
            );
          }
        });
      } else {
        // Wrap the callback in a post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onRangeChanged!(
              DateUtils.dateOnly(_focusedMonday),
              DateUtils.dateOnly(sunday),
            );
          }
        });
      }
    }
  }

  void _changeWeek(int weeks) {
    DateTime nextMonday = _focusedMonday.add(Duration(days: weeks * 7));
    DateTime sunday = nextMonday.add(const Duration(days: 6));

    // Logic to prevent going into the past if allowPast is false
    if (!widget.allowPast &&
        nextMonday.isBefore(sunday) &&
        sunday.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return;
    }

    setState(() {
      _focusedMonday = nextMonday;
    });
    _reportRange();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should disable the "Back" button
    bool canGoBack =
        widget.allowPast || _focusedMonday.isAfter(_getMonday(DateTime.now()));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_focusedMonday),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: canGoBack ? Colors.black : Colors.grey.shade300,
                  ),
                  onPressed: canGoBack ? () => _changeWeek(-1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeWeek(1),
                ),
              ],
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              DateTime day = _focusedMonday.add(Duration(days: index));
              bool isSelected =
                  widget.dateSelecting &&
                  DateUtils.isSameDay(day, _selectedDate);
              bool isSelectable =
                  widget.allowPast ||
                  !day.isBefore(DateUtils.dateOnly(DateTime.now()));

              return GestureDetector(
                onTap: () {
                  if (!isSelectable || !widget.dateSelecting) return;
                  _handleSlectedDate(day);
                },
                child: Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? UNHColorsPalette.thermosphereBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 3),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      Text(
                        "${day.day}",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isSelectable
                              ? Colors.black
                              : Colors.grey.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
