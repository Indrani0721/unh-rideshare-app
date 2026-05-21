import 'package:unh_rideshare_app/models/ride_model.dart';

/// Helper class to parse and handle ride departure date and time
class RideDepartureHelper {
  const RideDepartureHelper._();
  // Parses the departure date and time from a RideModel and returns a DateTime object
  static DateTime? getRideDepartureDateTime(RideModel ride) {
    final departureDate = DateTime.tryParse(ride.departureDate.trim());
    if (departureDate == null) {
      return null;
    }

    final normalizedTime = ride.departureTime.trim();
    final timeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$',
    ).firstMatch(normalizedTime);
    // If the time format is invalid, return the departure date with time set to 00:00
    if (timeMatch == null) {
      return DateTime(
        departureDate.year,
        departureDate.month,
        departureDate.day,
      );
    }
    // Extract hour, minute, and meridiem (AM/PM) from the time string
    var hour = int.tryParse(timeMatch.group(1) ?? '') ?? 0;
    final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
    final meridiem = timeMatch.group(3)?.toUpperCase();
    // Convert 12-hour format to 24-hour format if meridiem is present
    if (meridiem == 'AM' && hour == 12) {
      hour = 0;
    } else if (meridiem == 'PM' && hour < 12) {
      hour += 12;
    }
    // Return the combined DateTime object with the parsed date and time
    return DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
      hour,
      minute,
    );
  }

  // Determines if the ride's departure date and time is in the past compared to the current date and time
  static bool isPastRide(RideModel ride) {
    final departureDateTime = getRideDepartureDateTime(ride);
    if (departureDateTime == null) {
      return false;
    }
    // Compare the departure date and time with the current date and time
    return departureDateTime.isBefore(DateTime.now());
  }
}
