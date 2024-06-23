import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/const/styles.dart';

class MakeAppointment extends StatefulWidget {
  const MakeAppointment({super.key, required this.psychiatristId});
  final String psychiatristId;

  @override
  State<MakeAppointment> createState() => _MakeAppointmentState();
}

class _MakeAppointmentState extends State<MakeAppointment> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startingDateTime; // New variable to store combined date and time
  final TextEditingController _endTimeController = TextEditingController();
  final bool _isApproved = false;

  // Variables to hold psychiatrist details
  String _psychiatristName = '';
  String _psychiatristQualification = '';
  String _psychiatristProfileUrl = '';
  String _psychiatristEmail = '';

  @override
  void initState() {
    super.initState();
    // Fetch psychiatrist details when the widget initializes
    _fetchPsychiatristDetails();
  }

  Future<void> _fetchPsychiatristDetails() async {
    try {
      DocumentSnapshot psychiatristSnapshot = await FirebaseFirestore.instance
          .collection('psychiatrists')
          .doc(widget.psychiatristId)
          .get();

      if (psychiatristSnapshot.exists) {
        setState(() {
          _psychiatristName = psychiatristSnapshot['name'];
          _psychiatristQualification = psychiatristSnapshot['qualification'];
          _psychiatristProfileUrl = psychiatristSnapshot['profilePicture'];
          _psychiatristEmail = psychiatristSnapshot['email'];
          print(_psychiatristProfileUrl);
        });
      }
    } catch (e) {
      print('Error fetching psychiatrist details: $e');
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
        _startingDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startingDateTime?.hour ?? 0,
          _startingDateTime?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startingDateTime = DateTime(
          _startingDateTime?.year ?? DateTime.now().year,
          _startingDateTime?.month ?? DateTime.now().month,
          _startingDateTime?.day ?? DateTime.now().day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndingTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      Map<String, dynamic> appointmentData = {
        'AppointmentId':
            FirebaseFirestore.instance.collection('appointments').doc().id,
        'StartingDateTime': _startingDateTime, // Store as DateTime
        'EndingTime': _endTimeController.text,
        'PsychiatristId': widget.psychiatristId,
        'UserId': userId,
        'isApproved': _isApproved,
      };

      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointmentData);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment made successfully!')));
        Navigator.pop(context);
      } catch (e) {
        print('Error submitting form: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to make appointment')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Make appointment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primegreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display psychiatrist details
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _psychiatristProfileUrl != null &&
                            _psychiatristProfileUrl.isNotEmpty
                        ? Image.network(
                            _psychiatristProfileUrl,
                            width: screenWidth * 0.5,
                            height: screenWidth * 0.5,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Show a placeholder image or alternative UI for image load errors
                              return Image.asset(
                                'assets/images/default_profile.png',
                                width: screenWidth * 0.5,
                                height: screenWidth * 0.5,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/default_profile.png',
                            width: screenWidth * 0.5,
                            height: screenWidth * 0.5,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dr $_psychiatristName',
                        textAlign:
                            TextAlign.center, // Center align text horizontally
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primegreen,
                        ),
                      ),
                      Text(
                        '$_psychiatristQualification',
                        textAlign:
                            TextAlign.center, // Center align text horizontally
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        '$_psychiatristEmail',
                        textAlign:
                            TextAlign.center, // Center align text horizontally
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: CustomTextField(
                      labelText: 'Date',
                      controller: TextEditingController(
                          text: _startingDateTime != null
                              ? _startingDateTime!
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]
                              : ''),
                      icon: Icons.calendar_month,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: AbsorbPointer(
                    child: CustomTextField(
                      labelText: 'Starting time',
                      controller: TextEditingController(
                          text: _startingDateTime != null
                              ? TimeOfDay.fromDateTime(_startingDateTime!)
                                  .format(context)
                              : ''),
                      icon: Icons.timelapse,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                GestureDetector(
                    onTap: () => _selectEndingTime(context, _endTimeController),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _endTimeController,
                        labelText: 'Ending time',
                        icon: Icons.lock_clock,
                      ),
                    )),
                const SizedBox(height: 16.0),
                Center(
                  child: SizedBox(
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
                      onPressed: () {
                        _submitForm;
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit',
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}