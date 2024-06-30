// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/service/FirestoreService.dart';
import 'package:newproject/pages/video_call/videocall.dart';

class PsychiatristHomePage extends StatefulWidget {
  const PsychiatristHomePage({super.key});

  @override
  _PsychiatristHomePageState createState() => _PsychiatristHomePageState();
}

class _PsychiatristHomePageState extends State<PsychiatristHomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<QuerySnapshot> _appointmentsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      _appointmentsStream = FirebaseFirestore.instance
          .collection('appointments')
          .where('PsychiatristId', isEqualTo: userId)
          .snapshots();
    } else {
      // Handle the case where the user is not logged in
      _appointmentsStream = const Stream.empty();
    }
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, bool isApproved) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'isApproved': isApproved});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Appointment status updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update appointment status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: user != null
              ? FutureBuilder<Map<String, dynamic>?>(
                  future: _firestoreService.getUserData(user.uid),
                  builder:
                      (context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return const Text('Error fetching user data');
                    }

                    final userData = snapshot.data;

                    if (userData == null || !userData.containsKey('name')) {
                      return const Text(
                          'User data not found or name not available',
                          style: TextStyle(fontSize: 18));
                    }

                    final userName = userData['name'] as String;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hi, Dr. $userName',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: primegreen)),
                            const Text('Your appointments',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: primegreen)),
                          ],
                        ),
                      ],
                    );
                  },
                )
              : const Text('No user is currently signed in',
                  style: TextStyle(fontSize: 18)),
        ),
        actions: [
          IconButton(
            onPressed: () => _signout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No appointments found'));
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data() as Map<String, dynamic>;
              final appointmentId = data['AppointmentId'];

              Timestamp? startingTimestamp = data['StartingDateTime'];
              Timestamp? endingTimestamp = data['endingDateTime'];

              // Convert Timestamp to DateTime if available
              DateTime? startingDateTime =
                  startingTimestamp?.toDate();

              DateTime? endingDateTime =
                  endingTimestamp?.toDate();

              return FutureBuilder<Map<String, dynamic>?>(
                future: _firestoreService.getUserData(data['UserId']),
                builder:
                    (context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return ListTile(
                      title: const Text('Error fetching user data'),
                      subtitle: Text(
                        'Date: ${startingDateTime != null ? DateFormat('MMMM d, y').format(startingDateTime) : 'N/A'}\n'
                        'Starting Time: ${startingDateTime != null ? DateFormat('h:mm a').format(startingDateTime) : 'N/A'}\n'
                        'Ending Time: ${data['EndingTime'] ?? 'N/A'}\n'
                        'User ID: ${data['UserId'] ?? 'N/A'}\n'
                        'Approved: ${(data['isApproved'] ?? false) ? 'Yes' : 'No'}',
                      ),
                    );
                  }

                  final userData = snapshot.data;
                  final userName = userData!['name'] as String;
                  final userProfile = userData['profilePicture'];
                 // final userId = userData['userId'];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: userProfile != null
                            ? AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  userProfile,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  'assets/images/default_profile.png',
                                  width: screenWidth * 0.5,
                                  height: screenWidth * 0.5,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      title: Text(userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Date: ${startingDateTime != null ? DateFormat('MMMM d, y').format(startingDateTime) : 'N/A'}'),
                          Text(
                              'Starting Time: ${startingDateTime != null ? DateFormat('h:mm a').format(startingDateTime) : 'N/A'}'),
                          Text('Ending Time: ${data['EndingTime'] ?? 'N/A'}'),
                          Text(
                              (data['isApproved'] ?? false) ? 'Confirmed' : 'Not confirmed'),
                          !data['isApproved']
                              ? TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => _updateAppointmentStatus(
                                      appointment.id, true),
                                  child: const Text('Confirm'),
                                )
                              : TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => _updateAppointmentStatus(
                                      appointment.id, false),
                                  child: const Text('Cancel'),
                                ),
                        ],
                      ),
                      trailing: (data['isApproved'] ?? false)
                          ? (startingDateTime != null &&
                                  endingDateTime != null &&
                                  startingDateTime.isBefore(DateTime.now()) &&
                                  endingDateTime.isAfter(DateTime.now()))
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.videocam,
                                    color: Colors.teal,
                                    size: 40,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => VideoCall(
                                              channelName: appointmentId)),
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.videocam_off,
                                  color: Colors.teal.shade200,
                                  size: 40,
                                )
                          : TextButton(
                              onPressed: null,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.teal.shade100,
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
