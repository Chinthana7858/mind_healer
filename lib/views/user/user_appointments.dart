import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/service/FirestoreService.dart';
import 'package:mind_healer/views/video_call/videocall.dart';

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
      backgroundColor: coolgray,
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
          final now = DateTime.now();
          final upcomingAppointments = appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final endingTimestamp = data['endingDateTime'] as Timestamp?;
            final endingDateTime = endingTimestamp?.toDate();
            return endingDateTime != null && endingDateTime.isAfter(now);
          }).toList();

          final expiredAppointments = appointments.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final endingTimestamp = data['endingDateTime'] as Timestamp?;
            final endingDateTime = endingTimestamp?.toDate();
            return endingDateTime != null && endingDateTime.isBefore(now);
          }).toList();

          return ListView(
            children: [
              if (upcomingAppointments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primegreen,
                    ),
                  ),
                ),
                ...upcomingAppointments
                    .map((doc) => _buildAppointmentCard(doc)),
              ],
              if (expiredAppointments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: Text(
                    'Expired Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primegreen,
                    ),
                  ),
                ),
                ...expiredAppointments.map((doc) => _buildAppointmentCard(doc)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(DocumentSnapshot appointment) {
    final data = appointment.data() as Map<String, dynamic>;
    final appointmentId = data['AppointmentId'];
    // Fetch psychiatrist details using FirestoreService
    return FutureBuilder<Map<String, dynamic>?>(
      future: _firestoreService.getPsychiatristData(data['PsychiatristId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const ListTile(
            title: Text('Psychiatrist Not Found'),
          );
        }

        final psychiatristData = snapshot.data!;
        final psychiatristName = psychiatristData['name'];
        final psychiatristPicture = psychiatristData['profilePicture'];

        Timestamp? startingTimestamp = data['StartingDateTime'];
        Timestamp? endingTimestamp = data['endingDateTime'];

        // Convert Timestamp to DateTime if available
        DateTime? startingDateTime = startingTimestamp?.toDate();
        DateTime? endingDateTime = endingTimestamp?.toDate();

        return Card(
          margin: const EdgeInsets.all(12.0),
          borderOnForeground: true,
          color: secondarygreen,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  psychiatristPicture ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              'Dr. $psychiatristName',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 65, 120, 118),
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${startingDateTime != null ? DateFormat('MMMM d, y').format(startingDateTime) : 'N/A'}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 65, 120, 118),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Starting Time: ${startingDateTime != null ? DateFormat(' h:mm a').format(startingDateTime) : 'N/A'}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 65, 120, 118),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Ending Time: ${data['EndingTime'] ?? 'N/A'}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 65, 120, 118),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  (data['isApproved'] ?? false) ? 'Confirmed' : 'Pending',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 65, 120, 118),
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showDeleteConfirmationDialog(appointment.id);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: Column(
              children: [
                if (data['isApproved'] ?? false)
                  if (startingDateTime != null &&
                      endingDateTime != null &&
                      startingDateTime.isBefore(DateTime.now()) &&
                      endingDateTime.isAfter(DateTime.now()))
                    IconButton(
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
                                    channelName: appointmentId,
                                  )),
                        );
                      },
                    )
                  else
                    Icon(
                      Icons.videocam_off,
                      color: Colors.teal,
                      size: 40,
                    )
                else
                  TextButton(
                    onPressed: null,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(color: primegreen),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String appointmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content:
              const Text('Are you sure you want to delete this appointment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAppointment(appointmentId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete appointment: $e')),
      );
    }
  }
}
