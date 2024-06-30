// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newproject/const/colors.dart';

class PsychiatristAppointments extends StatefulWidget {
  const PsychiatristAppointments({super.key});

  @override
  _PsychiatristAppointmentsState createState() =>
      _PsychiatristAppointmentsState();
}

class _PsychiatristAppointmentsState extends State<PsychiatristAppointments> {
  late Stream<QuerySnapshot> _appointmentsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointments',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: primegreen),
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

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Appointment ID: ${appointment.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${data['Date'] ?? 'N/A'}'),
                      Text('Starting Time: ${data['StartingTime'] ?? 'N/A'}'),
                      Text('Ending Time: ${data['EndingTime'] ?? 'N/A'}'),
                      Text('User ID: ${data['UserId'] ?? 'N/A'}'),
                      Text(
                          'Approved: ${(data['isApproved'] ?? false) ? 'Yes' : 'No'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateAppointmentStatus(appointment.id, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateAppointmentStatus(appointment.id, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
