import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository_impl.dart';

class GetProfile {
  final ProfileRepositoryImpl repository;

  GetProfile(this.repository);

  Future<ProfileModel> execute() async {
    return repository.getUserProfile();
  }
}
