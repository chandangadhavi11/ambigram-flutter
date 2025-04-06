import 'package:flutter/material.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

class AuthNotifier extends ChangeNotifier {
  User? _currentUser;
  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;

  final _authRepository = AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource());

  Future<void> login(String email, String password) async {
    final user = await _authRepository.login(email, password);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    notifyListeners();
  }
}
