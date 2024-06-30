import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/service/FirestoreService.dart';
import 'package:newproject/pages/video_call/videocall.dart';

class UserAppointments extends StatefulWidget {
  const UserAppointments({super.key});

  @override
  State<UserAppointments> createState() => _UserAppointmentsState();
}

class _UserAppointmentsState extends State<UserAppointments> {
  late Stream<QuerySnapshot> _appointmentsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService =
      FirestoreService(); // Instantiate FirestoreService

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      _appointmentsStream = FirebaseFirestore.instance
          .collection('appointments')
          .where('UserId', isEqualTo: userId)
          .snapshots();
    } else {
      // Handle the case where the user is not logged in
      _appointmentsStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primegreen,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              // Fetch psychiatrist details using FirestoreService
              return FutureBuilder<Map<String, dynamic>?>(
                future: _firestoreService
                    .getPsychiatristData(data['PsychiatristId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const ListTile(
                      title: Text('Psychiatrist Not Found'),
                    );
                  }

                  final psychiatristData = snapshot.data!;
                  final psychiatristName = psychiatristData['name'];
                  final psychiatristPicture =
                      psychiatristData['profilePicture'];

                  Timestamp? startingTimestamp = data['StartingDateTime'];
                  Timestamp? endingTimestamp = data['endingDateTime'];

                  // Convert Timestamp to DateTime if available
                  DateTime? startingDateTime = startingTimestamp?.toDate();

                  DateTime? endingDateTime = endingTimestamp?.toDate();

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            psychiatristPicture ??
                                'https://via.placeholder.com/150',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text('Dr. $psychiatristName'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Date: ${startingDateTime != null ? DateFormat('MMMM d, y').format(startingDateTime) : 'N/A'}'),
                          Text(
                              'Starting Time: ${startingDateTime != null ? DateFormat(' h:mm a').format(startingDateTime) : 'N/A'}'),
                          Text('Ending Time: ${data['EndingTime'] ?? 'N/A'}'),
                          Text((data['isApproved'] ?? false)
                              ? 'Confirmed'
                              : 'Pending'),
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
