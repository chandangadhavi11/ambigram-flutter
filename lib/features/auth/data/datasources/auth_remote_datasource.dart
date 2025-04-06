import '../models/user_model.dart';

// Simulate a Firebase or API auth remote data source
class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password) async {
    // In a real app, you'd use Firebase Auth or an API call here
    // We'll just pretend this is successful if email & password are non-empty
    if (email.isNotEmpty && password.isNotEmpty) {
      return UserModel(id: '123', email: email, name: 'John Doe');
    } else {
      throw Exception('Login failed: Invalid credentials');
    }
  }

  Future<void> logout() async {
    // Sign out logic
    // In Firebase, you'd call FirebaseAuth.instance.signOut();
  }
}
