enum DateFilterType { byWeekRange, byDate, byDayOfWeek }
enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class RideFilterModel {
  DateTime selectedDate;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  Set<DayOfWeek> selectedDayOfWeek;
  Set<String> selectedTimeOfDay;
  Set<DateFilterType> dateFilterType;

  RideFilterModel({
    DateTime? selectedDate,
    this.rangeStart,
    this.rangeEnd,
    Set<DayOfWeek>? selectedDayOfWeek,
    Set<String>? selectedTimeOfDay,
    Set<DateFilterType>? dateFilterType,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        selectedDayOfWeek = selectedDayOfWeek ?? {},
        selectedTimeOfDay = selectedTimeOfDay ?? {},
        dateFilterType = dateFilterType ?? {};
}
