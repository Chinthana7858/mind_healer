import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_profile_viewmodel.dart';
import '../../const/colors.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Access the ViewModel
    final viewModel = Provider.of<UserProfileViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          viewModel.user?.name ?? 'Loading...',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
              ? Center(child: Text(viewModel.errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: viewModel.user?.profilePicture != null
                            ? NetworkImage(viewModel.user!.profilePicture!)
                            : AssetImage('assets/images/default_profile.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      ProfileInfoField(
                          label: 'Name', value: viewModel.user!.name),
                      const SizedBox(height: 20),
                      ProfileInfoField(
                          label: 'Phone', value: viewModel.user!.phone),
                      const SizedBox(height: 20),
                      ProfileInfoField(
                          label: 'Gender', value: viewModel.user!.gender),
                      const SizedBox(height: 20),
                      ProfileInfoField(
                          label: 'Date of Birth',
                          value: viewModel.user!.dateOfBirth),
                    ],
                  ),
                ),
    );
  }
}

class ProfileInfoField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: primegreen, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
