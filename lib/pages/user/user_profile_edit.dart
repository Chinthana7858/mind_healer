import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/const/styles.dart';
import 'package:mind_healer/service/FirestoreService.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

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
  final TextEditingController _dobController = TextEditingController();
  String? _profilePicUrl; // Nullable string for profile picture URL
  File? _image;

  String _gender = 'Male';
  bool _isloading = false;
  @override
  void initState() {
    super.initState();
    _loadUserrofile();
  }

  Future<void> _loadUserrofile() async {
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
        });
      } else {
        print('User data not found');
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isloading = true;
    });

    try {
      Map<String, dynamic>? userDoc =
          await widget._firestoreService.getUserData(widget.userId);
      if (userDoc != null) {
        Map<String, dynamic> userData = {
          'name': _nameController.text,
          'lowercasename': _nameController.text.toLowerCase(),
          'phone': _phoneController.text,
          'gender': _gender,
          'dateOfBirth': _dobController.text,
        };

        if (_image != null) {
          String imageUrl = await uploadProfilePicture(widget.userId);
          userData['profilePicture'] = imageUrl;
        }

        try {
          await widget._firestoreService
              .updateUserData(widget.userId, userData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }
        } catch (e) {
          if (e is FirebaseException && e.code == 'not-found') {
            // Document does not exist, create it
            await widget._firestoreService
                .createUserData(widget.userId, userData);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile created successfully!')),
              );
            }
          } else {
            throw e;
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data does not exist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
        print('Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isloading = false;
        });
      }
    }
  }

  Future<File> _resizeImage(File pickedImage) async {
    // Read the file and decode it to Image object
    img.Image image = img.decodeImage(await pickedImage.readAsBytes())!;

    // Resize the image to 300x300 pixels
    img.Image resizedImage = img.copyResize(image, width: 300);

    // Save resized image to a temporary file
    File resizedFile = File(pickedImage.path)
      ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

    return resizedFile;
  }

  Future<String> uploadProfilePicture(String userId) async {
    String imageUrl = '';
    try {
      File resizedImage =
          await _resizeImage(_image!); // Resize image before upload

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      UploadTask uploadTask = storageReference.putFile(resizedImage);

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
      File pickedImage = File(pickedFile.path);
      setState(() {
        _image = pickedImage;
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
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
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
                backgroundImage: _image != null
                    ? FileImage(_image!) // Use FileImage for local File
                    : _profilePicUrl != null
                        ? NetworkImage(
                            _profilePicUrl!) // Use NetworkImage for URL
                        : AssetImage(
                            'assets/images/default_profile.png'), // Default image
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
                controller: _nameController,
                labelText: 'Name',
                icon: Icons.person),
            const SizedBox(height: 20),
            CustomTextField(
                controller: _phoneController,
                labelText: 'Phone',
                icon: Icons.phone),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _gender,
              items: <String>['Male', 'Female', 'Other']
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: primegreen),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Gender',
                labelStyle: TextStyle(
                  color: primegreen,
                  fontWeight: FontWeight.w400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(color: primegreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(color: primegreen, width: 1.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            DateOfBirthPicker(
              controller: _dobController,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isloading ? null : _updateUserProfile,
                child: _isloading
                    ? CircularProgressIndicator()
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: primegreen),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
