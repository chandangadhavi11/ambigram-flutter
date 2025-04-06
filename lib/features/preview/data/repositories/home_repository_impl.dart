import '../models/home_model.dart';

class HomeRepositoryImpl {
  Future<HomeModel> fetchHomeData() async {
    // Simulate fetching data from an API or local DB
    await Future.delayed(const Duration(milliseconds: 500));
    return HomeModel(
      title: 'Home Screen Title',
      description: 'Welcome to the home screen!',
    );
  }
}
