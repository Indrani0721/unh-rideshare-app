class RequestDeparturePlaceholderHelper {
  const RequestDeparturePlaceholderHelper._();

  // Placeholder helper methods: replace with shared departure helper from target branch.
  static DateTime? parseDepartureDateTime({
    required String departureDate,
    required String departureTime,
  }) {
    final date = DateTime.tryParse(departureDate.trim());
    if (date == null) {
      return null;
    }

    final normalizedTime = departureTime.trim();
    final timeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$',
    ).firstMatch(normalizedTime);

    if (timeMatch == null) {
      return DateTime(date.year, date.month, date.day);
    }

    var hour = int.tryParse(timeMatch.group(1) ?? '') ?? 0;
    final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
    final meridiem = timeMatch.group(3)?.toUpperCase();

    if (meridiem == 'AM' && hour == 12) {
      hour = 0;
    } else if (meridiem == 'PM' && hour < 12) {
      hour += 12;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static bool isPastDeparture({
    required String departureDate,
    required String departureTime,
  }) {
    final departureDateTime = parseDepartureDateTime(
      departureDate: departureDate,
      departureTime: departureTime,
    );

    if (departureDateTime == null) {
      return false;
    }

    return departureDateTime.isBefore(DateTime.now());
  }
}
