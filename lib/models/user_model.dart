import 'package:unh_rideshare_app/models/car_model.dart';

class UserModel {
  final String userId;
  final String name;
  final String phone;
  final String? profilePhotoUrl;
  final bool rideReminderEnabled;
  final int rideReminderMinutes;
  final List<CarModel> cars;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    this.profilePhotoUrl,
    required this.rideReminderEnabled,
    required this.rideReminderMinutes,
    required this.cars,
  });
}
