import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/user_public_info_model.dart';
import 'package:unh_rideshare_app/services/user_profile_service.dart';
import 'package:unh_rideshare_app/theme/colors.dart';

class UserInfoWidget extends StatefulWidget {
  final String userId;
  const UserInfoWidget({super.key, required this.userId});

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  // Get user info by widget.userId
  late Future<UserPublicInfoModel?> _userInfo;

  @override
  void initState() {
    super.initState();
    _userInfo = UserProfileService().getUserPublicInfo(widget.userId);
  }

  void _showUserDetailsModal(
    BuildContext context,
    UserPublicInfoModel userInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: UNHColorsPalette.freshSnow,
          title: const Text(''),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: [
                userInfo.profilePictureUrl == null ||
                        userInfo.profilePictureUrl!.isEmpty
                    ? Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                      )
                    : CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          userInfo.profilePictureUrl!,
                        ),
                      ),
                Text(
                  userInfo.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserPublicInfoModel?>(
      future: _userInfo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Card(
            color: UNHColorsPalette.freshSnow,
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Text('User not found'),
              ),
            ),
          );
        }
        final userInfo = snapshot.data!;
        return GestureDetector(
          onTap: () => _showUserDetailsModal(context, userInfo),
          child: Card(
            color: UNHColorsPalette.freshSnow,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                spacing: 16,
                children: [
                  userInfo.profilePictureUrl == null || userInfo.profilePictureUrl!.isEmpty
                      ? Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[600],
                          ),
                        )
                      : CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            userInfo.profilePictureUrl!,
                          ),
                        ),
                  Text(
                    userInfo.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
