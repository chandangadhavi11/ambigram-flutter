import '../models/profile_model.dart';

class ProfileRepositoryImpl {
  Future<ProfileModel> getUserProfile() async {
    // Simulate network or database call
    await Future.delayed(const Duration(milliseconds: 500));
    return ProfileModel(
      name: 'Jane Doe',
      bio: 'Flutter Developer at MyCompany',
    );
  }
}
