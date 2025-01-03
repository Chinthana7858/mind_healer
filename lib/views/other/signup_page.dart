import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mind_healer/views/widgets/psychiatrist_bottom_nav_bar.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/const/styles.dart';
import 'package:mind_healer/views/widgets/user_bottom_nav_bar.dart';
import 'package:image/image.dart' as img;

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key); // Corrected the key parameter

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reEnteredPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();

  String _gender = 'Male';
  bool _isPsychiatrist = false;
  bool _isSpecialist = false;
  bool _isLoading = false;
  File? _image;

  Map<String, String> _startTimes = {};
  Map<String, String> _endTimes = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Initial date of the calendar
      firstDate: DateTime(1900), // Starting date
      lastDate: DateTime(2100), // Ending date
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}"
            .split(' ')[0]; // Update the date in the text field
      });
    }
  }

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if the profile picture is mandatory and selected for psychiatrists
      if (_isPsychiatrist && _image == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile picture is mandatory for psychiatrists.')),
        );
        return;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Determine the collection based on the user type
      String collection = _isPsychiatrist ? 'psychiatrists' : 'users';

      // Prepare user data
      Map<String, dynamic> userData = {
        'email': _emailController.text,
        'name': _nameController.text,
        'lowercasename': _nameController.text.toLowerCase(),
        'phone': _phoneController.text,
        'gender': _gender,
        'userType': _isPsychiatrist ? 'psychiatrist' : 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'dateOfBirth': _dobController.text,
        'userId': userCredential.user!.uid,
      };

      if (_isPsychiatrist) {
        userData['qualification'] = _qualificationController.text;
        userData['specialist'] = _isSpecialist ? 'true' : 'false';
        if (_isSpecialist) {
          userData['speciality'] = _specialityController.text;
        }

        // Add availability data
        userData['availability'] = {
          'startTimes': _startTimes,
          'endTimes': _endTimes,
        };
      }

      // Upload profile picture if selected
      if (_image != null) {
        String imageUrl = await uploadProfilePicture(userCredential.user!.uid);
        userData['profilePicture'] = imageUrl;
      }

      // Save user data to Firestore
      await _firestore
          .collection(collection)
          .doc(userCredential.user!.uid)
          .set(userData);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Signup successful!')));
      final userType = await _getUserType(userCredential.user!.uid);
      if (userType == 'psychiatrist') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PsyBottomBar(selectedIndex: 0)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const UserBottomBar(selectedIndex: 0)),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'Firebase Auth Error: ${e.message}';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred. Please try again.')));
      print('Error during signup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Resize the image using the image package
      File pickedImage = File(pickedFile.path);
      final File resizedImage = await _resizeImage(pickedImage);

      setState(() {
        _image = resizedImage;
      });
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

  Future<String?> _getUserType(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc['userType'];
    }

    final psychiatristDoc = await FirebaseFirestore.instance
        .collection('psychiatrists')
        .doc(uid)
        .get();
    if (psychiatristDoc.exists) {
      return psychiatristDoc['userType'];
    }

    return null;
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
                    child: Text(
                      _startTimes[day] ?? 'Start Time',
                      style: const TextStyle(
                          fontSize: 16.0, color: Colors.black54),
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
                    child: Text(
                      _endTimes[day] ?? 'End Time',
                      style: const TextStyle(
                          fontSize: 16.0, color: Colors.black54),
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: primegreen,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
              color: Colors.white,
              iconSize: 25.0,
            ),
          ),
        ),
        title: const Text(
          'Sign Up',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/deco-1.png'),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: screenHeight * 0.05,
              ),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.email,
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              CustomTextField(
                controller: _nameController,
                labelText: 'Name',
                icon: Icons.man,
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
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
              SizedBox(
                height: screenHeight * 0.01,
              ),
              DateOfBirthPicker(
                controller: _dobController,
                onTap: () => _selectDate(context),
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              CustomTextField(
                controller: _reEnteredPasswordController,
                labelText: 'Confirm Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'I am a psychiatrist',
                    style: TextStyle(color: primegreen),
                  ),
                  Switch(
                    value: _isPsychiatrist,
                    onChanged: (bool value) {
                      setState(() {
                        _isPsychiatrist = value;
                      });
                    },
                  ),
                ],
              ),
              if (_isPsychiatrist) ...[
                const Text(
                  'Enter your qualifications here(ex: Bsc (Hons))',
                  style: TextStyle(color: primegreen),
                ),
                SizedBox(
                  height: screenHeight * 0.01,
                ),
                CustomTextField(
                  controller: _qualificationController,
                  labelText: 'Qualifications',
                  icon: Icons.school,
                  obscureText: false,
                ),
                SizedBox(
                  height: screenHeight * 0.01,
                ),
                const Text(
                  'Enter your availability here',
                  style: TextStyle(color: primegreen),
                ),
                _buildAvailabilityField('Sunday'),
                _buildAvailabilityField('Monday'),
                _buildAvailabilityField('Tuesday'),
                _buildAvailabilityField('Wednesday'),
                _buildAvailabilityField('Thursday'),
                _buildAvailabilityField('Friday'),
                _buildAvailabilityField('Saturday'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'I am a specialist',
                      style: TextStyle(color: primegreen),
                    ),
                    Switch(
                      value: _isSpecialist,
                      onChanged: (bool value) {
                        setState(() {
                          _isSpecialist = value;
                        });
                      },
                    ),
                  ],
                ),
                if (_isSpecialist) ...[
                  const Text(
                    'Enter your speciality',
                    style: TextStyle(color: primegreen),
                  ),
                  SizedBox(
                    height: screenHeight * 0.01,
                  ),
                  CustomTextField(
                    controller: _specialityController,
                    labelText: 'Speciality',
                    icon: Icons.local_hospital,
                    obscureText: false,
                  ),
                ] else
                  ...[]
              ] else
                ...[],
              const SizedBox(height: 20),
              SizedBox(
                width: screenWidth * 0.7,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primegreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    shadowColor: primegreen,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_passwordController.text ==
                              _reEnteredPasswordController.text) {
                            _signup();
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Passwords are not matching'),
                            ));
                          }
                        },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signin');
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?'),
                    Text(
                      'Sign In',
                      style: TextStyle(color: primegreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
