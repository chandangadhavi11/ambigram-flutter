import '../../data/models/home_model.dart';
import '../../data/repositories/home_repository_impl.dart';

class FetchHomeData {
  final HomeRepositoryImpl repository;

  FetchHomeData({required this.repository});

  Future<HomeModel> execute() async {
    return repository.fetchHomeData();
  }
}
