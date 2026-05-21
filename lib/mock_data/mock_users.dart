import 'package:unh_rideshare_app/models/car_model.dart';
import 'package:unh_rideshare_app/models/user_model.dart';

final mockUser_1 = UserModel(
  userId: 'user1',
  name: 'Alice Johnson',
  phone: '555-1234',
  rideReminderEnabled: true,
  rideReminderMinutes: 60,
  cars: [
    CarModel(
      vehicleId: 'car1',
      make: 'Toyota',
      model: 'Camry',
      year: '2018',
      color: 'Blue',
      licensePlate: 'ABC123',
      seats: 4,
      isComplete: true,
    ),
    CarModel(
      vehicleId: 'car2',
      make: 'Honda',
      model: 'Civic',
      year: '2020',
      color: 'Red',
      licensePlate: 'XYZ789',
      seats: 4,
      isComplete: true,
    ),
    CarModel(
      vehicleId: 'car4',
      make: 'Subaru',
      model: 'Outback',
      year: '2013',
      color: 'Green',
      licensePlate: 'JKL321',
      seats: 4,
      isComplete: true,
    ),
  ],
);

final mockUser_2 = UserModel(
  userId: 'user2',
  name: 'Bob Smith',
  phone: '555-5678',
  rideReminderEnabled: true,
  rideReminderMinutes: 60,
  cars: [
    CarModel(
      vehicleId: 'car3',
      make: 'Ford',
      model: 'Focus',
      year: '2017',
      color: 'Black',
      licensePlate: 'DEF456',
      seats: 4,
      isComplete: true,
    ),
    CarModel(
      vehicleId: 'car5',
      make: 'Hyundai',
      model: 'Elantra',
      year: '2022',
      color: 'Silver',
      licensePlate: 'MNO654',
      seats: 4,
      isComplete: true,
    ),
    CarModel(
      vehicleId: 'car6',
      make: 'Jeep',
      model: 'Wrangler',
      year: '2010',
      color: 'Orange',
      licensePlate: 'PQR987',
      seats: 4,
      isComplete: true,
    ),
  ],
);
