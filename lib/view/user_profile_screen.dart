import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unh_rideshare_app/models/car_model.dart';
import 'package:unh_rideshare_app/models/user_model.dart';
import 'package:unh_rideshare_app/services/user_profile_service.dart';
import 'package:unh_rideshare_app/services/vehicle_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/utils/formatter.dart';
import 'package:unh_rideshare_app/view/added_car_details_screen.dart';
import 'package:unh_rideshare_app/view/add_car_screen.dart';
import 'package:unh_rideshare_app/view/welcome_screen.dart';
import 'package:unh_rideshare_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unh_rideshare_app/services/storage_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final VehicleService vehicleService = VehicleService();
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();
  String userName = "";
  String phoneNumber = "";
  String? profilePhotoUrl;
  bool _rideReminderEnabled = true;
  int _rideReminderMinutes = 60;
  XFile? _selectedProfilePhoto;
  bool _isSavingProfile = false;
  bool _isSavingReminderSettings = false;
  bool _isDeletingAccount = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    final user = context.read<UserModel?>();
    _nameController = TextEditingController(text: user!.name);
    userName = user.name;
    phoneNumber = phoneNumberFormatter(user.phone.replaceFirst('+1', ''));
    profilePhotoUrl = user.profilePhotoUrl;
    _rideReminderEnabled = user.rideReminderEnabled;
    _rideReminderMinutes = user.rideReminderMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedProfilePhoto = pickedFile;
    });
  }

  Future<void> _saveProfile(BuildContext bottomSheetContext) async {
    if (_isSavingProfile) return;
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<UserModel?>()!;
    String? newPhotoUrl = profilePhotoUrl;
    setState(() {
      _isSavingProfile = true;
      userName = _nameController.text.trim();
    });
    try {
      if (_selectedProfilePhoto != null) {
        newPhotoUrl = await _storageService.uploadProfilePhoto(
          uid: user.userId,
          file: _selectedProfilePhoto!,
        );
      }
      await UserProfileService().updateUserProfile(
        uid: user.userId,
        name: userName,
        profilePhotoUrl: newPhotoUrl,
      );
      if (!mounted) return;
      setState(() {
        profilePhotoUrl = newPhotoUrl;
        _selectedProfilePhoto = null;
      });
      if (!bottomSheetContext.mounted) return;
      Navigator.pop(bottomSheetContext);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  void _showEditNameBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            spacing: 20,
            children: [
              const Text(
                "Edit Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Edit Name",
                  filled: true,
                  fillColor: UNHColorsPalette.freshSnow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Profile Photo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isSavingProfile ? null : _pickProfilePhoto,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Upload Profile Photo"),
                  ),
                  if (_selectedProfilePhoto != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Selected: ${_selectedProfilePhoto!.name}'),
                    ),
                ],
              ),
              ElevatedButton(
                onPressed: _isSavingProfile
                    ? null
                    : () => _saveProfile(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UNHColorsPalette.unhWildcatBlue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSavingProfile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UNHColorsPalette.freshSnow,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Opens the details screen for a specific car when tapped in the list
  void _openAddedCarDetails(CarModel vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddedCarDetailsScreen(vehicle: vehicle),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await authService.deleteCurrentUserAccount();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  // Builds the "My Cars" panel with a list of the user's saved vehicles and an option to add new ones
  Widget _buildMyCarsPanel() {
    return SizedBox(
      width: double.infinity, // Make the card take full width
      child: Card(
        color: UNHColorsPalette.freshSnow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and "Add Car" button
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Space between title and button
                children: [
                  const Text(
                    'My Cars',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 34,
                    // "Add Car" button with icon
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final addedVehicle = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddCarScreen(),
                          ),
                        );
                        // If a new vehicle was added, refresh the list by calling setState
                        if (addedVehicle == true && mounted) {
                          setState(() {});
                        }
                      },
                      // Button styling to match app theme
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UNHColorsPalette.unhWildcatBlue,
                        foregroundColor: UNHColorsPalette.freshSnow,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Car'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Container for the list of vehicles with a fixed height and scrollable content
              Container(
                height:
                    390, // Fixed height to allow scrolling if there are many vehicles
                decoration: BoxDecoration(
                  color: UNHColorsPalette.freshSnow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12, width: 1.2),
                ),
                // FutureBuilder to load the user's vehicles and display them in a list
                child: FutureBuilder<List<CarModel>>(
                  future: vehicleService.getVehiclesForCurrentUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Error loading vehicles: ${snapshot.error}',
                          ),
                        ),
                      );
                    }

                    final vehicles = snapshot.data ?? [];
                    if (vehicles.isEmpty) {
                      return const Center(
                        child: Text('No vehicles saved yet.'),
                      );
                    }
                    // ListView to display each vehicle in a card format with an image,
                    //details, and navigation to the details screen on tap
                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        // Each vehicle is displayed in a card with an image (or placeholder icon),
                        return Card(
                          color: UNHColorsPalette.freshSnow,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openAddedCarDetails(v),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  // Display the vehicle photo if available, otherwise show a car icon
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        (v.vehiclePhotoUrl != null &&
                                            v.vehiclePhotoUrl!.isNotEmpty)
                                        ? Image.network(
                                            v.vehiclePhotoUrl!,
                                            width: 56,
                                            height: 42,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.directions_car,
                                                      size: 42,
                                                      color: Colors.grey,
                                                    ),
                                          )
                                        : const Icon(
                                            Icons.directions_car,
                                            size: 42,
                                            color: Colors.grey,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      // Display the vehicle's year, make, model, color, and license plate information
                                      children: [
                                        Text(
                                          '${v.year} ${v.make} ${v.model}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Color: ${v.color} | Plate: ${v.licensePlate}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRideReminderSettings() async {
    if (_isSavingReminderSettings) return;

    final user = context.read<UserModel?>()!;

    setState(() {
      _isSavingReminderSettings = true;
    });

    try {
      await UserProfileService().updateUserProfile(
        uid: user.userId,
        rideReminderEnabled: _rideReminderEnabled,
        rideReminderMinutes: _rideReminderMinutes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride reminder settings updated')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save reminder settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingReminderSettings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile Info",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              spacing: 30, // Vertical spacing between sections
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: UNHColorsPalette.freshSnow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  profilePhotoUrl != null &&
                                      profilePhotoUrl!.isNotEmpty
                                  ? NetworkImage(profilePhotoUrl!)
                                  : null,
                              child:
                                  (profilePhotoUrl == null ||
                                      profilePhotoUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Name",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Phone Number",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phoneNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: UNHColorsPalette.freshSnow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Ride Reminder",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _rideReminderEnabled,
                                onChanged: _isSavingReminderSettings
                                    ? null
                                    : (value) async {
                                        setState(() {
                                          _rideReminderEnabled = value;
                                        });
                                        await _saveRideReminderSettings();
                                      },
                              ),
                            ],
                          ),
                          if (_rideReminderEnabled) ...[
                            const SizedBox(height: 12),
                            const Text(
                              "Reminder Time",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: _rideReminderMinutes,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: UNHColorsPalette.freshSnow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text("30 minutes"),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text("1 hour"),
                                ),
                                DropdownMenuItem(
                                  value: 120,
                                  child: Text("2 hours"),
                                ),
                              ],
                              onChanged: _isSavingReminderSettings
                                  ? null
                                  : (value) async {
                                      if (value == null) return;
                                      setState(() {
                                        _rideReminderMinutes = value;
                                      });
                                      await _saveRideReminderSettings();
                                    },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _buildMyCarsPanel(), // My Cars panel with list of vehicles and add button
                SizedBox(
                  width: 250,
                  child: Column(
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showEditNameBottomSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UNHColorsPalette.unhWildcatBlue,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: UNHColorsPalette.freshSnow,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await authService.signOut();
                            Navigator.pushAndRemoveUntil(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                              color: UNHColorsPalette.unhWildcatBlue,
                              width: 1,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: UNHColorsPalette.unhWildcatBlue,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isDeletingAccount
                              ? null
                              : _confirmDeleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isDeletingAccount
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Delete Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
