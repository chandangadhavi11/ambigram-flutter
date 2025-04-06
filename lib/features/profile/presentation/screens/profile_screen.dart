import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/usecases/get_profile.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../global/state/auth_notifier.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../core/utils/helpers.dart';
import '../widgets/profile_widget.dart';
import '../../data/repositories/profile_repository_impl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  String? userBio;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final getProfile = GetProfile(ProfileRepositoryImpl());
    final profile = await getProfile.execute();

    final user = context.read<AuthNotifier>().currentUser;

    setState(() {
      userName = user != null ? user.name : profile.name; 
      userBio = profile.bio;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthNotifier, User?>((auth) => auth.currentUser);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: isLoading
          ? const Center(child: LoadingIndicator())
          : ProfileWidget(
              name: userName ?? 'Unknown User',
              bio: userBio ?? 'No bio available',
              greetingMessage: user != null
                  ? Helpers.formatWelcomeMessage(user.name)
                  : 'Welcome, Guest!',
            ),
    );
  }
}
