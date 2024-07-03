import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mind_healer/service/FirestoreService.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileEditPage extends StatefulWidget {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  UserProfileEditPage({required this.userId});

  @override
  _UserProfileEditPageState createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _profilePicUrl; // Nullable string for profile picture URL
  File? _image;

  String _gender = 'Male';
  bool _isSpecialist = false;
  bool _isLoading = false;

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
          _nameController.text = userData['name'];
          _phoneController.text = userData['phone'];
          _gender = userData['gender'];
          _dobController.text = userData['dateOfBirth'] ?? '';
          // Ensure to handle specialist as boolean
          _isSpecialist = userData['userType'] == 'psychiatrist' &&
              (userData['specialist'] ?? false);
          if (_isSpecialist) {
            _qualificationController.text = userData['qualification'];
            _specialityController.text = userData['speciality'];
          }
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> userData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'gender': _gender,
        'dateOfBirth': _dobController.text,
      };

      // Include specialist fields if user is a psychiatrist
      if (_isSpecialist) {
        userData['qualification'] = _qualificationController.text;
        userData['specialist'] = _isSpecialist;
        userData['speciality'] = _specialityController.text;
      }

      // Upload profile picture if selected
      if (_image != null) {
        String imageUrl = await uploadProfilePicture(widget.userId);
        userData['profilePicture'] = imageUrl;
      }

      await widget._firestoreService.updateUserData(widget.userId, userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
      print('Error updating profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> uploadProfilePicture(String userId) async {
    String imageUrl = '';
    try {
      // Example storage reference path for profile pictures
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      UploadTask uploadTask = storageReference.putFile(_image!);

      await uploadTask.whenComplete(() async {
        imageUrl = await storageReference.getDownloadURL();
      });
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
    return imageUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _profilePicUrl != null && _image == null
                    ? NetworkImage(_profilePicUrl!)
                    : AssetImage('assets/images/default_profile.png'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            DropdownButtonFormField<String>(
              value: _gender,
              items: <String>['Male', 'Female', 'Other']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(labelText: 'Date of Birth'),
            ),
            if (_isSpecialist) ...[
              TextField(
                controller: _qualificationController,
                decoration: InputDecoration(labelText: 'Qualification'),
              ),
              TextField(
                controller: _specialityController,
                decoration: InputDecoration(labelText: 'Speciality'),
              ),
            ],
            CheckboxListTile(
              title: const Text('I am a specialist'),
              value: _isSpecialist,
              onChanged: (bool? value) {
                setState(() {
                  _isSpecialist = value ?? false;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateUserProfile,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
