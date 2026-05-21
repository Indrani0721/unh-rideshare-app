import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/view/available_ride_screen.dart';
import 'package:unh_rideshare_app/view/dashboard_screen.dart';
import 'package:unh_rideshare_app/view/notification_screen.dart';
import 'package:unh_rideshare_app/view/user_profile_screen.dart';
import 'package:unh_rideshare_app/services/notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // 1. List of your screens
  final List<Widget> _screens = [
    const DashboardScreen(),
    const AvailableRideScreen(),
    const UserProfileScreen(),
    const NotificationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. IndexedStack keeps all screens 'alive' in memory
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: UNHColorsPalette.unhWildcatBlue.withValues(alpha: 0.125),
        onDestinationSelected: (int index) {
          // 3. Just update the index, no Navigator needed!
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
