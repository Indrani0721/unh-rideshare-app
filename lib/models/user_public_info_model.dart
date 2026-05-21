class UserPublicInfoModel {
  final String userId;
  final String name;
  final String? profilePictureUrl;

  UserPublicInfoModel({
    required this.userId,
    required this.name,
    this.profilePictureUrl,
  });
}
