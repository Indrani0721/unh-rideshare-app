import 'package:flutter_test/flutter_test.dart';
import 'package:unh_rideshare_app/models/ride_request_model.dart';

void main() {
  test('Ride request status enum values are available', () {
    expect(RideRequestStatus.pending.name, 'pending');
    expect(RideRequestStatus.accepted.name, 'accepted');
    expect(RideRequestStatus.declined.name, 'declined');
    expect(RideRequestStatus.cancelled.name, 'cancelled');
  });
}
