import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/const/styles.dart';
import 'package:mind_healer/service/FirestoreService.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

class PsychiatristProfileEditPage extends StatefulWidget {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  PsychiatristProfileEditPage({required this.userId});

  @override
  _PsychiatristProfileEditPageState createState() =>
      _PsychiatristProfileEditPageState();
}

class _PsychiatristProfileEditPageState
    extends State<PsychiatristProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final Map<String, TextEditingController> _availabilityControllers = {
    'Monday': TextEditingController(),
    'Tuesday': TextEditingController(),
    'Wednesday': TextEditingController(),
    'Thursday': TextEditingController(),
    'Friday': TextEditingController(),
    'Saturday': TextEditingController(),
    'Sunday': TextEditingController(),
  };

  String? _profilePicUrl; // Nullable string for profile picture URL
  File? _image;

  String _gender = 'Male';
  bool _isSpecialist = false;
  bool _isLoading = false;

  final Map<String, String?> _startTimes = {};
  final Map<String, String?> _endTimes = {};

  @override
  void initState() {
    super.initState();
    _loadPsychiatristProfile();
  }

  Future<void> _loadPsychiatristProfile() async {
    try {
      Map<String, dynamic>? userData =
          await widget._firestoreService.getPsychiatristData(widget.userId);
      if (userData != null) {
        setState(() {
          _profilePicUrl = userData['profilePicture'];
          _nameController.text = userData['name'];
          _phoneController.text = userData['phone'];
          _gender = userData['gender'];
          _dobController.text = userData['dateOfBirth'] ?? '';
          _isSpecialist = userData['userType'] == 'psychiatrist' &&
              (userData['specialist']?.toString().toLowerCase() == 'true');
          _qualificationController.text = userData['qualification'];
          if (_isSpecialist) {
            _specialityController.text = userData['speciality'];
          }

          // Load availability times
          for (String day in _availabilityControllers.keys) {
            _availabilityControllers[day]?.text =
                userData['availability']['startTimes'][day] ?? '';
            _startTimes[day] =
                userData['availability']['startTimes'][day] ?? '';
            _endTimes[day] = userData['availability']['endTimes'][day] ?? '';
          }
        });
      } else {
        print('User data not found');
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _updatePsychiatristProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? psychiatristDoc =
          await widget._firestoreService.getPsychiatristData(widget.userId);
      if (psychiatristDoc != null) {
        Map<String, dynamic> userData = {
          'name': _nameController.text,
          'lowercasename': _nameController.text.toLowerCase(),
          'phone': _phoneController.text,
          'gender': _gender,
          'dateOfBirth': _dobController.text,
          'qualification': _qualificationController.text,
          'specialist': _isSpecialist.toString(),
          'availability': {
            'startTimes': _availabilityControllers.map(
                (day, controller) => MapEntry(day, _startTimes[day] ?? '')),
            'endTimes': _availabilityControllers
                .map((day, controller) => MapEntry(day, _endTimes[day] ?? '')),
          }
        };

        if (_isSpecialist) {
          userData['speciality'] = _specialityController.text;
        }

        if (_image != null) {
          String imageUrl = await uploadProfilePicture(widget.userId);
          userData['profilePicture'] = imageUrl;
        }

        try {
          await widget._firestoreService
              .updatePsychiatristData(widget.userId, userData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }
        } catch (e) {
          if (e is FirebaseException && e.code == 'not-found') {
            await widget._firestoreService
                .createPsychiatristUserData(widget.userId, userData);
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete profile picture from Firebase Storage if it exists
      if (_profilePicUrl != null) {
        Reference storageReference =
            FirebaseStorage.instance.refFromURL(_profilePicUrl!);
        await storageReference.delete();
      }

      // Delete user data from Firestore
      await widget._firestoreService
          .deletePsychiatristData(context, widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile deleted successfully!')),
        );
        Navigator.of(context).pop(); // Go back after deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete profile: $e')),
        );
        print('Error deleting profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  Future<void> _confirmDeleteProfile(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete your profile?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _deleteProfile(); // Call _deleteProfile if user confirmed deletion
    }
  }

  Widget _buildAvailabilityField(String day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  day,
                  style: const TextStyle(color: primegreen, fontSize: 16),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    setState(() {
                      _startTimes[day] = selectedTime.format(context);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _startTimes[day] ?? 'From',
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.black54),
                        ),
                        Icon(Icons.access_time, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    setState(() {
                      _endTimes[day] = selectedTime.format(context);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _endTimes[day] ?? 'To',
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.black54),
                        ),
                        Icon(Icons.access_time, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                        : AssetImage('assets/images/default_profile.png')
                            as ImageProvider, // Default image
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
            CustomTextField(
                controller: _qualificationController,
                labelText: 'Qualification',
                icon: Icons.school),
            const SizedBox(height: 20),
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
            if (_isSpecialist) ...[
              CustomTextField(
                  controller: _specialityController,
                  labelText: 'Speciality',
                  icon: Icons.local_hospital),
            ],
            const SizedBox(height: 20),
            Text(
              'Availability',
              style: const TextStyle(fontSize: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _availabilityControllers.keys
                  .map((day) => _buildAvailabilityField(day))
                  .toList(),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      primegreen, // Set the button background color to red
                ),
                onPressed: _isLoading ? null : _updatePsychiatristProfile,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _confirmDeleteProfile(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red, // Set the button background color to red
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : const Text(
                        'Delete Profile',
                        style: TextStyle(
                            color: Colors.white), // Set the text color to white
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
