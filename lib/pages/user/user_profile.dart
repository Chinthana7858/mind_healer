import 'package:flutter/material.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/service/FirestoreService.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? _profilePicUrl; // Nullable string for profile picture URL
  String _name = '';
  String _phone = '';
  String _gender = 'Male';
  String _dob = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      Map<String, dynamic>? userData =
          await widget._firestoreService.getUserData(widget.userId);
      if (userData != null) {
        setState(() {
          _profilePicUrl = userData['profilePicture'];
          _name = userData['name'] ?? '';
          _phone = userData['phone'] ?? '';
          _gender = userData['gender'] ?? 'Male';
          _dob = userData['dateOfBirth'] ?? '';
        });
      } else {
        print('User data not found');
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$_name',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _profilePicUrl != null
                  ? NetworkImage(_profilePicUrl!)
                  : AssetImage('assets/images/default_profile.png'),
            ),
            const SizedBox(height: 20),
            ProfileInfoField(label: 'Name', value: _name),
            const SizedBox(height: 20),
            ProfileInfoField(label: 'Phone', value: _phone),
            const SizedBox(height: 20),
            ProfileInfoField(label: 'Gender', value: _gender),
            const SizedBox(height: 20),
            ProfileInfoField(label: 'Date of Birth', value: _dob),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoField extends StatelessWidget {
  final String label;
  final String value;

  ProfileInfoField({required this.label, required this.value});

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
