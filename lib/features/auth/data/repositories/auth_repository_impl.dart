import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  Future<User> login(String email, String password) async {
    try {
      final UserModel userModel = await remoteDataSource.login(email, password);
      return User(
        id: userModel.id,
        email: userModel.email,
        name: userModel.name,
      );
    } catch (e) {
      debugPrint('Error in AuthRepositoryImpl.login: \$e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await remoteDataSource.logout();
  }
}
