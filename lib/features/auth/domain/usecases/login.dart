import '../entities/user.dart';
import '../../data/repositories/auth_repository_impl.dart';

class LoginUseCase {
  final AuthRepositoryImpl repository;

  LoginUseCase(this.repository);

  Future<User> execute(String email, String password) async {
    return await repository.login(email, password);
  }
}
