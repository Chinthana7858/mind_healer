// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/pages/user/make_appointment.dart';
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
  // Variables to hold psychiatrist details
  String _psychiatristName = '';
  String _psychiatristQualification = '';
  String _psychiatristProfileUrl = '';
  String _psychiatristEmail = '';
  String? _psychiatristSpeciality;
  List<String> _favoritePsychiatrists = [];
  @override
  void initState() {
    super.initState();
    // Fetch psychiatrist details when the widget initializes
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

          print(_psychiatristProfileUrl);
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
                              textAlign: TextAlign
                                  .center, // Center align text horizontally
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primegreen,
                              ),
                            ),
                            Text(
                              _psychiatristQualification,
                              textAlign: TextAlign
                                  .center, // Center align text horizontally
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            _psychiatristSpeciality != null
                                ? Text(
                                    _psychiatristSpeciality!,
                                    textAlign: TextAlign
                                        .center, // Center align text horizontally
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade900,
                                    ),
                                  )
                                : Container(),
                            Text(
                              _psychiatristEmail,
                              textAlign: TextAlign
                                  .center, // Center align text horizontally
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Center(
                        child: SizedBox(
                          width: screenWidth * 0.7,
                          child: IconButton(
                            icon: _favoritePsychiatrists
                                    .contains(widget.psychiatristId)
                                ? const Icon(
                                    Icons.favorite,
                                    color: primegreen,
                                  )
                                : const Icon(
                                    Icons.favorite_border,
                                    color: primegreen,
                                  ),
                            onPressed: () {
                              _toggleFavorite(widget.psychiatristId);
                            },
                          ),
                        ),
                      ),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MakeAppointment(
                                        psychiatristId:
                                            widget.psychiatristId.toString())),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Make an appointment',
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
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
