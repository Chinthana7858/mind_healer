import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/const/styles.dart';

class MakeAppointmentByTime extends StatefulWidget {
  const MakeAppointmentByTime({
    super.key,
    required this.psychiatristId,
    required this.startTime,
    required this.endTime,
    required this.day,
  });

  final String psychiatristId;
  final String startTime;
  final String endTime;
  final String day;

  @override
  State<MakeAppointmentByTime> createState() => _MakeAppointmentByTimeState();
}

class _MakeAppointmentByTimeState extends State<MakeAppointmentByTime> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startingDateTime;
  DateTime? _endingDateTime;
  late TextEditingController _endTimeController;
  late TextEditingController _startTimeController;

  final bool _isApproved = false;

  // Variables to hold psychiatrist details
  String _psychiatristName = '';
  String _psychiatristQualification = '';
  String _psychiatristProfileUrl = '';
  String _psychiatristEmail = '';

  @override
  void initState() {
    super.initState();
    _endTimeController = TextEditingController(text: widget.endTime);
    _startTimeController = TextEditingController(text: widget.startTime);
    _fetchPsychiatristDetails();
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final format = RegExp(r'(\d+):(\d+)\s*([APMapm]*)');
    final match = format.firstMatch(timeString);

    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)?.toUpperCase() ?? '';

      if (period == 'PM' && hour < 12) {
        return TimeOfDay(hour: hour + 12, minute: minute);
      } else if (period == 'AM' && hour == 12) {
        return TimeOfDay(hour: 0, minute: minute);
      } else {
        return TimeOfDay(hour: hour, minute: minute);
      }
    } else {
      throw FormatException("Invalid time format: $timeString");
    }
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
        });
      }
    } catch (e) {
      print('Error fetching psychiatrist details: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime date) {
        // Allow selection of the day passed to the widget
        switch (widget.day.toLowerCase()) {
          case 'monday':
            return date.weekday == DateTime.monday;
          case 'tuesday':
            return date.weekday == DateTime.tuesday;
          case 'wednesday':
            return date.weekday == DateTime.wednesday;
          case 'thursday':
            return date.weekday == DateTime.thursday;
          case 'friday':
            return date.weekday == DateTime.friday;
          case 'saturday':
            return date.weekday == DateTime.saturday;
          case 'sunday':
            return date.weekday == DateTime.sunday;
          default:
            return false;
        }
      },
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
        _endingDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endingDateTime?.hour ?? 0,
          _endingDateTime?.minute ?? 0,
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
        _startTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectEndingTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endingDateTime = DateTime(
          _endingDateTime?.year ?? DateTime.now().year,
          _endingDateTime?.month ?? DateTime.now().month,
          _endingDateTime?.day ?? DateTime.now().day,
          picked.hour,
          picked.minute,
        );
        _endTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startingDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date for the appointment.'),
          ),
        );
        return;
      }

      String userId = FirebaseAuth.instance.currentUser!.uid;

      Map<String, dynamic> appointmentData = {
        'AppointmentId':
            FirebaseFirestore.instance.collection('appointments').doc().id,
        'StartingDateTime': _startingDateTime,
        'EndingTime': _endTimeController.text,
        'PsychiatristId': widget.psychiatristId,
        'UserId': userId,
        'isApproved': _isApproved,
        'endingDateTime': _endingDateTime,
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
                    child: _psychiatristProfileUrl.isNotEmpty
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primegreen,
                        ),
                      ),
                      Text(
                        _psychiatristQualification,
                        textAlign:
                            TextAlign.center, // Center align text horizontally
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        _psychiatristEmail,
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
                              ? '${_startingDateTime!.day}/${_startingDateTime!.month}/${_startingDateTime!.year}'
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
                      controller: _startTimeController,
                      icon: Icons.timelapse,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                GestureDetector(
                    onTap: () => _selectEndingTime(context),
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
                        _submitForm();
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
