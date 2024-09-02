import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/pages/user/make_appointment.dart';
import 'package:mind_healer/pages/user/make_appointment_by_time.dart';
import 'package:mind_healer/service/FirestoreService.dart';

class PsychiatristProfile extends StatefulWidget {
  const PsychiatristProfile({super.key, required this.psychiatristId});
  final String psychiatristId;

  @override
  State<PsychiatristProfile> createState() => _PsychiatristProfileState();
}

class _PsychiatristProfileState extends State<PsychiatristProfile> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String _psychiatristName = '';
  String _psychiatristQualification = '';
  String _psychiatristProfileUrl = '';
  String _psychiatristEmail = '';
  String? _psychiatristSpeciality;
  List<String> _favoritePsychiatrists = [];
  Map<String, dynamic> _availabilityStartTimes = {};
  Map<String, dynamic> _availabilityEndTimes = {};

  @override
  void initState() {
    super.initState();
    _fetchPsychiatristDetails();
  }

  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user != null) {
      List<String> favorites =
          await _firestoreService.getFavoritePsychiatrists(user.uid);
      setState(() {
        _favoritePsychiatrists = favorites;
      });
    }
  }

  void _toggleFavorite(String psychiatristId) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (_favoritePsychiatrists.contains(psychiatristId)) {
        await _firestoreService.removeFavoritePsychiatrist(
            user.uid, psychiatristId);
      } else {
        await _firestoreService.addFavoritePsychiatrist(
            user.uid, psychiatristId);
      }
      await _loadFavorites();
    }
  }

  Future<void> _fetchPsychiatristDetails() async {
    try {
      DocumentSnapshot psychiatristSnapshot = await FirebaseFirestore.instance
          .collection('psychiatrists')
          .doc(widget.psychiatristId)
          .get();

      if (psychiatristSnapshot.exists) {
        Map<String, dynamic>? data =
            psychiatristSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          _psychiatristName = data?['name'] ?? '';
          _psychiatristQualification = data?['qualification'] ?? '';
          _psychiatristProfileUrl = data?['profilePicture'] ?? '';
          _psychiatristEmail = data?['email'] ?? '';
          _psychiatristSpeciality = data?.containsKey('speciality') == true
              ? data!['speciality']
              : null;

          var availability = data?['availability'] as Map<String, dynamic>?;
          if (availability != null) {
            _availabilityStartTimes =
                availability['startTimes'] as Map<String, dynamic>;
            _availabilityEndTimes =
                availability['endTimes'] as Map<String, dynamic>;
          }
        });
      }
    } catch (e) {
      print('Error fetching psychiatrist details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final user = _auth.currentUser;

    // Define the correct order of the days
    final List<String> orderedDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dr $_psychiatristName',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primegreen,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data != null) {
            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            _favoritePsychiatrists =
                List<String>.from(userData?['favoritePsychiatrists'] ?? []);

            return SingleChildScrollView(
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
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primegreen,
                              ),
                            ),
                            Text(
                              _psychiatristQualification,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            _psychiatristSpeciality != null
                                ? Text(
                                    _psychiatristSpeciality!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade900,
                                    ),
                                  )
                                : Container(),
                            Text(
                              _psychiatristEmail,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Display availability
                      const SizedBox(height: 16.0),
                      Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primegreen,
                        ),
                      ),

                      const SizedBox(height: 8.0),
                      Table(
                        border: TableBorder.all(color: Colors.grey),
                        children: [
                          TableRow(
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Day',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primegreen,
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'From',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primegreen,
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'To',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primegreen,
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primegreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Iterate through orderedDays to ensure correct order
                          ...orderedDays.map((day) {
                            String startTime =
                                _availabilityStartTimes[day] ?? 'Unavailable';
                            String endTime =
                                _availabilityEndTimes[day] ?? 'Unavailable';

                            return TableRow(
                              children: [
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(day),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(startTime),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(endTime),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MakeAppointmentByTime(
                                              psychiatristId:
                                                  widget.psychiatristId,
                                              startTime: startTime,
                                              endTime: endTime,
                                              day: day,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.arrow_circle_right_rounded,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                      SizedBox(
                        height: 100,
                      )
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleFavorite(widget.psychiatristId),
        backgroundColor: primegreen,
        child: Icon(
          _favoritePsychiatrists.contains(widget.psychiatristId)
              ? Icons.favorite
              : Icons.favorite_border,
          color: Colors.white,
        ),
      ),
    );
  }
}
