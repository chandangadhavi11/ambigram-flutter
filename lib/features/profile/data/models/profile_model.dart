class ProfileModel {
  final String name;
  final String bio;

  ProfileModel({required this.name, required this.bio});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'bio': bio};
  }
}
